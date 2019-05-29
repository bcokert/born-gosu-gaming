defmodule Event.Persister do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec get(String.t()) :: {:ok, %Event{} | :none} | {:error, :event_not_found}
  def get(name) do
    GenServer.call(Event.Persister, {:get, name})
  end

  @spec get_all(integer | nil, integer | nil, integer | nil) :: [%Event{}]
  def get_all(author_id \\ nil, participant_id \\ nil, within_seconds \\ nil) do
    filters = [
      date_filter(within_seconds),
      author_filter(author_id),
      participant_filter(participant_id)
    ]
    GenServer.call(Event.Persister, {:get_all, filters})
  end

  @spec create(%Event{}) :: %Event{}
  def create(event) do
    GenServer.call(Event.Persister, {:create, event})
    event
  end

  @spec remove(String.t()) :: :ok | {:error, any}
  def remove(name) do
    GenServer.call(Event.Persister, {:remove, name})
  end

  @spec register(String.t(), [Nostrum.Snowflake.t()]) :: :ok | {:error, any}
  def register(name, participant_ids) do
    GenServer.call(Event.Persister, {:register, name, participant_ids})
  end

  def init(:ok) do
    {:ok, event_table} = :dets.open_file(Application.get_env(:born_gosu_gaming, :event_db), [type: :set])
    {:ok, participant_table} = :dets.open_file(Application.get_env(:born_gosu_gaming, :participant_db), [type: :bag])
    {:ok, {event_table, participant_table}}
  end

  defp first_or_none([first | _]), do: elem(first, 1)
  defp first_or_none([]), do: :none

  defp filter_by(filters) do
    fn {_, event} ->
      Enum.all?(filters, fn f -> f.(event) end)
        |> filter_result_to_response(event)
    end
  end

  defp filter_result_to_response(true, event), do: {:continue, event}
  defp filter_result_to_response(false, _), do: :continue

  defp date_filter(nil), do: fn _ -> true end
  defp date_filter(within_seconds) when within_seconds > 0 do
    {:ok, now} = DateTime.now("Etc/UTC")
    fn event -> DateTime.diff(event.date, now) <= within_seconds end
  end

  defp author_filter(nil), do: fn _ -> true end
  defp author_filter(author_id) when is_integer(author_id) do
    fn event -> event.creator == author_id end
  end

  defp participant_filter(nil), do: fn _ -> true end
  defp participant_filter(participant_id) when is_integer(participant_id) do
    fn event -> participant_id in event.participants end
  end

  def handle_call({:get, name}, _from, {event_table, participant_table}) do
    with results when is_list(results) <- :dets.lookup(event_table, name) do
      {:reply, {:ok, first_or_none(results)}, {event_table, participant_table}}
    end
  end

  def handle_call({:get_all, filters}, _from, {event_table, participant_table}) do
    with results when is_list(results) <- :dets.traverse(event_table, filter_by(filters)) do
      {:reply, results, {event_table, participant_table}}
    end
  end

  def handle_call({:create, event}, _from, {event_table, participant_table}) do
    :ok = :dets.insert(event_table, {event.name, event})
    {:reply, event, {event_table, participant_table}}
  end

  def handle_call({:remove, name}, _from, {event_table, participant_table}) do
    result = :dets.delete(event_table, name)
    {:reply, result, {event_table, participant_table}}
  end

  def handle_call({:register, name, participant_ids}, _from, {event_table, participant_table}) do
    with results when is_list(results) <- :dets.lookup(event_table, name),
         event <- first_or_none(results) do
      :ok = :dets.insert(event_table, {name, %{event | participants: participant_ids}})
      {:reply, :ok, {event_table, participant_table}}
    else
      :none ->
        {:reply, {:error, :event_not_exists}, {event_table, participant_table}}
    end
  end
end
