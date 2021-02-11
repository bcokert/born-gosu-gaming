defmodule Mentor do
  require Logger
  @api Application.get_env(:born_gosu_gaming, :discord_api)

  def run(%Command{discord_msg: m, command: "help"}), do: help(m.channel_id, m.author.id)
  def run(%Command{discord_msg: m, command: command, args: args}), do: unknown(m.channel_id, command, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, command, args, username, discriminator) do
    cmd = "`!mentor #{command} #{Enum.join(args, ", ")}` from #{username}\##{discriminator}"
    @api.create_message(channel_id, "Apologies, but I'm not sure what to do with this mentor command: #{cmd}")
  end

  defp help(channel_id, author_id) do
    @api.create_message(channel_id, "I'll dm you")
    with {:ok, dm} <- @api.create_dm(author_id) do
      @api.create_message(dm.id, String.trim("""
      Available commands:
        Coming Soon!
      """))
    end
  end

end
