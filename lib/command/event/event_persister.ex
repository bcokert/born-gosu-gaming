defmodule Event.Persister do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec get(String.t()) :: {:ok, %Event{} | :none} | {:error, any()}
  def get(name) do
    GenServer.call(Event.Persister, {:get, name})
  end

  @spec get_all(integer | nil, integer | nil, integer | nil) :: [%Event{}]
  def get_all(author_id \\ nil, participant_id \\ nil, within_seconds \\ nil) do
    filters = [
      date_filter(within_seconds),
      author_filter(author_id),
      participant_filter(participant_id),
      future_filter(0),
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

  @spec set_reminders(String.t(), [Nostrum.Snowflake.t()]) :: :ok | {:error, any}
  def set_reminders(name, participant_ids) do
    GenServer.call(Event.Persister, {:set_reminders, name, participant_ids})
  end

  def init(:ok) do
    {:ok, event_table} = :dets.open_file(Application.get_env(:born_gosu_gaming, :event_db), [type: :set, auto_save: 5000])
    {:ok, {event_table}}
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

  defp future_filter(nil), do: fn _ -> true end
  defp future_filter(seconds_from_now) when seconds_from_now >= 0 do
    {:ok, now} = DateTime.now("Etc/UTC")
    fn event -> DateTime.diff(event.date, now) > seconds_from_now end
  end

  defp author_filter(nil), do: fn _ -> true end
  defp author_filter(author_id) when is_integer(author_id) do
    fn event -> event.creator == author_id end
  end

  defp participant_filter(nil), do: fn _ -> true end
  defp participant_filter(participant_id) when is_integer(participant_id) do
    fn event -> participant_id in event.participants end
  end

  def handle_call({:get, name}, _from, {event_table}) do
    with results when is_list(results) <- :dets.lookup(event_table, name) do
      {:reply, {:ok, first_or_none(results)}, {event_table}}
    end
  end

  def handle_call({:get_all, filters}, _from, {event_table}) do
    with results when is_list(results) <- :dets.traverse(event_table, filter_by(filters)) do
      sorted = Enum.sort(results, fn (%Event{date: d1}, %Event{date: d2}) -> DateTime.compare(d1, d2) != :gt end)
      {:reply, sorted, {event_table}}
    end
  end

  def handle_call({:create, event}, _from, {event_table}) do
    :ok = :dets.insert(event_table, {event.name, event})
    :ok = Event.Reminder.schedule_reminders(event)
    Logger.info("Created event '#{event.name}'")
    {:reply, event, {event_table}}
  end

  def handle_call({:remove, event}, _from, {event_table}) do
    result = :dets.delete(event_table, event.name)
    :ok = Event.Reminder.unschedule_reminders(event)
    Logger.info("Removed event '#{event.name}'")
    {:reply, result, {event_table}}
  end

  def handle_call({:set_reminders, event, participant_ids}, _from, {event_table}) do
    updated_event = %{event | participants: participant_ids}
    :ok = :dets.insert(event_table, {event.name, updated_event})
    :ok = Event.Reminder.schedule_reminders(updated_event)
    Logger.info("Set reminders to #{length(participant_ids)} peeps for '#{event.name}'")
    {:reply, :ok, {event_table}}
  end
end
