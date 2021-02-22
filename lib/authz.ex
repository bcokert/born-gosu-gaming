defmodule Authz do
  require Logger

  @moduledoc """
  Provides a declarative api for authorizing calls based on user or channel.
  """

  def is_admin?(member, guild), do: DiscordQuery.member_has_role?(member, "Admins", guild)
  def is_mentor?(member, guild), do: DiscordQuery.member_has_role?(member, "Mentors", guild)
  def is_member?(member, guild), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)

  def authorized_for_command?(_, _, _, "help"), do: true

  def authorized_for_command?(member, guild, "help", "mentor"), do: is_admin?(member, guild) or is_mentor?(member, guild)
  def authorized_for_command?(member, guild, "users", "mentor"), do: is_admin?(member, guild) or is_mentor?(member, guild)

  def authorized_for_command?(member, guild, "help", "admin"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "setdaylightsavings", "admin"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "daylightsavings", "admin"), do: is_admin?(member, guild)

  def authorized_for_command?(_, _, "help", "event"), do: true
  def authorized_for_command?(_, _, "dates", "event"), do: true
  def authorized_for_command?(_, _, "soon", "event"), do: true
  def authorized_for_command?(member, guild, "mine", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "add", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "remove", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "tryout", "event"), do: is_admin?(member, guild)

  def authorized_for_command?(member, guild, cmd, namespace) do
    Logger.info("Detected an unhandled authorization check: #{cmd} in #{namespace} by #{member.user.username}")
    is_admin?(member, guild)
  end
end
