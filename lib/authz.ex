defmodule Authz do

  @moduledoc """
  Provides a declarative api for authorizing calls based on user or channel.
  """

  def is_admin?(member, guild), do: DiscordQuery.member_has_role?(member, "Admins", guild)
  def is_member?(member, guild), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)

  def authorized_for_command?(_, _, "help"), do: true
  def authorized_for_command?(member, guild, "adminhelp"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "setdaylightsavings"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "daylightsavings"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "dates"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "soon"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "mine"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "add"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "remove"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "tryout"), do: is_admin?(member, guild)

  def authorized_for_command?(member, guild, _), do: is_admin?(member, guild)
end
