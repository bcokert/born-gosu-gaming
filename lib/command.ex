defmodule Command do
  @enforce_keys [:discord_msg, :command]
  defstruct [:discord_msg, :command, args: []]

  def run_command(command) do
    Event.run(command)
  end
end
