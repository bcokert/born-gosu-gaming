defmodule Command.DiscordConsumer do
  use Nostrum.Consumer
  require Logger

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def input_to_command("", discord_msg) do
    %Command{discord_msg: discord_msg, command: "soon"}
  end

  @spec input_to_command(String.t(), Nostrum.Struct.Message.t()) :: %Command{}
  def input_to_command(input, discord_msg) do
    input
      |> String.replace("\n", " ")
      |> String.replace("“", "\"")
      |> String.replace("”", "\"")
      |> String.replace("\"\"", "\"")
      |> OptionParser.split()
      |> Enum.filter(fn s -> String.length(s) > 0 end)
      |> list_to_command(discord_msg)
  end

  @spec list_to_command([String.t()], Nostrum.Struct.Message.t()) :: %Command{}
  def list_to_command([command | args], discord_msg) do
    %Command{discord_msg: discord_msg, command: command, args: args}
  end

  def handle_event({:READY, _, _}) do
    Logger.info("Confirmed a websocket connection")
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _}) do
    case msg.content do
      "!events" <> rest ->
        rest
          |> String.trim()
          |> input_to_command(msg)
          |> Command.run_command()
      "!tryout" <> rest ->
        "tryout" <> rest
          |> String.trim()
          |> input_to_command(msg)
          |> Command.run_command
      str ->
        with true <- Enum.any?(msg.mentions, fn u -> u.id == Nostrum.Cache.Me.get().id end),
             lower <- String.downcase(str),
             trimmed <- String.trim(lower),
             {:reply, {resp, img_bytes}} <- Command.Butler.talk(trimmed, msg) do
          if Enum.empty?(img_bytes) do
            Nostrum.Api.create_message(msg.channel_id, resp)
          else
            Nostrum.Api.create_message(msg.channel_id, [content: resp, file: %{name: "motivation.jpg", body: to_string(img_bytes)}])
          end
        end
    end
  end

  def handle_event(_) do
    :noop
  end
end
