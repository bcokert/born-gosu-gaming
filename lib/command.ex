defmodule Command do
  require Logger
  @enforce_keys [:discord_msg, :command]
  defstruct [:discord_msg, :command, args: []]

  @api Application.get_env(:born_gosu_gaming, :discord_api)

  def run(cmd = %Command{discord_msg: discord_msg, command: command, args: args}, namespace) do
    with {:ok, channel} <- Nostrum.Cache.ChannelCache.get(discord_msg.channel_id),
         guild <- Nostrum.Cache.GuildCache.get!(discord_msg.guild_id) do

      Logger.info "Attempting '!#{namespace} #{command} #{Enum.join(args, ", ")}' from #{discord_msg.author.username}\##{discord_msg.author.discriminator} in #{channel.name}"
      author = @api.get_guild_member!(guild.id, discord_msg.author.id)
      case Authz.authorized_for_command?(author, guild, command, namespace) do
        true -> run_command(cmd, namespace)
        false ->
          @api.create_message(channel.id, "I'm sorry, but you're not authorized to do this.")
          Logger.info "#{command}(#{Enum.join(args, ", ")}) from #{discord_msg.author.username}\##{discord_msg.author.discriminator} in #{channel.name} was unauthorized"
      end
    end
  end

  defp run_command(command, "event"), do: Event.run(command)
  defp run_command(command, "mentor"), do: Mentor.run(command)
  defp run_command(command, "admin"), do: Admin.run(command)
  defp run_command(command, "help"), do: Help.run(command)
end
