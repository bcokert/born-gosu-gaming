defmodule Interaction.Server do
  use GenServer

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:create, interaction}, _from, interactions) do
    {:reply, :ok, Map.put(interactions, interaction.mid, interaction)}
  end

  def handle_call({:interact, mid, context}, _from, interactions) do
    case interactions do
      %{^mid => interaction = %Interaction{mstate: mstate, reducer: reducer}} ->
        {:reply, :ok, %{interactions | mid => %{interaction | mstate: reducer.(mstate, context)}}}
      _ ->
        {:reply, {:error, "No such interaction exists"}, interactions}
    end
  end

  def handle_call({:remove, mid}, _from, interactions) do
    case interactions do
      %{^mid => %Interaction{on_remove: nil}} ->
        {:reply, :ok, Map.delete(interactions, mid)}
      %{^mid => %Interaction{mstate: mstate, on_remove: on_remove}} ->
        on_remove.(mstate)
        {:reply, :ok, Map.delete(interactions, mid)}
      _ ->
        {:reply, {:error, "That interaction doesn't exist"}, interactions}
    end
  end
end
