defmodule Command do
  @enforce_keys [:discord_msg, :command]
  defstruct [:discord_msg, :command, args: []]

  defimpl String.Chars do
    def to_string(command) do
      "#{command.command}(#{Enum.join(command.args, ", ")}) from #{command.discord_msg.author.username}\##{command.discord_msg.author.discriminator}"
    end
  end

  def run_command(command) do
    Event.run_command(command)
  end
end
  