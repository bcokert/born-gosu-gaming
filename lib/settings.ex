defmodule Settings do
  @server Settings.Server

  def start_link() do
    GenServer.start_link(Settings.Server, :ok, name: @server)
  end

  @spec get_output_timezones :: %{required(binary) => integer}
  def get_output_timezones do
    GenServer.call(@server, :get_output_timezones)
  end

  @spec remove_output_timezones([binary]) :: %{required(binary) => integer}
  def remove_output_timezones(timezones) do
    GenServer.call(@server, {:remove_output_timezones, timezones})
  end

  @spec set_daylight_savings(boolean, :na | :eu) :: :ok
  def set_daylight_savings(true, :na) do
    GenServer.call(@server, {:remove_output_timezones, [:EST]})
    GenServer.call(@server, {:merge_output_timezones, %{EDT: -4}})
  end
  def set_daylight_savings(false, :na) do
    GenServer.call(@server, {:remove_output_timezones, [:EDT]})
    GenServer.call(@server, {:merge_output_timezones, %{EST: -5}})
  end
  def set_daylight_savings(true, :eu) do
    GenServer.call(@server, {:remove_output_timezones, [:CET]})
    GenServer.call(@server, {:merge_output_timezones, %{CEST: 2}})
  end
  def set_daylight_savings(false, :eu) do
    GenServer.call(@server, {:remove_output_timezones, [:CEST]})
    GenServer.call(@server, {:merge_output_timezones, %{CET: 1}})
  end
end
