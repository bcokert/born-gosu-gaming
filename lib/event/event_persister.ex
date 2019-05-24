defmodule Event.Persister do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec get(String.t()) :: %Event{} | :none
  def get(name) do
    GenServer.call(Event.Persister, {:get, name})
  end

  @spec get_all() :: [%Event{}]
  def get_all() do
    GenServer.call(Event.Persister, {:get_all})
  end

  @spec create(%Event{}) :: %Event{}
  def create(event) do
    GenServer.call(Event.Persister, {:create, event})
    event
  end

  def init(:ok) do
    case :dets.open_file(:"db/eventPeristence", [type: :set]) do
      {:ok, table} ->
        {:ok, table}
      {:error, reason} ->
        Logger.error "Failed to open event file: #{reason}"
        {:stop, "Couldn't open event file", :error, nil}
    end
  end

  def handle_call({:get, name}, _from, table) do
    case :dets.lookup(table, name) do
      {:error, reason} ->
        Logger.warn "Failed to retrieve event '#{name}': #{reason}"
        {:stop, "Failed to retrieve event", :error, table}
      [result] ->
        {:reply, elem(result, 1), table}
      [] ->
        {:reply, :none, table}
    end
  end

  def handle_call({:get_all}, _from, table) do
    case :dets.traverse(table, fn obj -> {:continue, elem(obj, 1)} end) do
      {:error, reason} ->
        Logger.warn "Failed to retrieve all events: #{reason}"
        {:stop, "Failed to retrieve events", :error, table}
      results ->
        {:reply, results, table}
    end
  end

  def handle_call({:create, event}, _from, table) do
    case :dets.insert(table, {event.name, event}) do
      {:error, reason} ->
        Logger.warn "Failed to create event '#{event.name}': #{reason}"
        {:stop, "Failed to create event", :error, table}
      :ok ->
        {:reply, event, table}
    end
  end
end
