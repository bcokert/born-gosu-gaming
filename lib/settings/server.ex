defmodule Settings.Server do
  use GenServer

  def init(_) do
    {:ok, %{
      output_timezones: %{
        EDT: -4,
        CEST: 2,
        KST: 9,
      }
    }}
  end

  def handle_call(:get_output_timezones, _from, state = %{output_timezones: output}) do
    {:reply, output, state}
  end

  def handle_call({:remove_output_timezones, tzs}, _from, state = %{output_timezones: existing}) do
    {:reply, :ok, %{state | output_timezones: Map.drop(existing, tzs)}}
  end

  def handle_call({:merge_output_timezones, new}, _from, state = %{output_timezones: existing}) do
    {:reply, :ok, %{state | output_timezones: Map.merge(existing, new)}}
  end
end
