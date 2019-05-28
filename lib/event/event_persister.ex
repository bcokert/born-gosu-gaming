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

  @spec get_all() :: [%Event{}]
  def get_all do
    GenServer.call(Event.Persister, {:get_all})
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

  def handle_call({:get, name}, _from, {event_table, participant_table}) do
    with results when is_list(results) <- :dets.lookup(event_table, name) do
      {:reply, {:ok, first_or_none(results)}, {event_table, participant_table}}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, {event_table, participant_table}}
    end
  end

  def handle_call({:get_all}, _from, {event_table, participant_table}) do
    results = :dets.traverse(event_table, fn obj -> {:continue, elem(obj, 1)} end)
    {:reply, results, {event_table, participant_table}}
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
