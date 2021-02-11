defmodule Authz do

  @moduledoc """
  Provides a declarative api for authorizing calls based on user or channel.
  """

  def is_admin?(member, guild), do: DiscordQuery.member_has_role?(member, "Admins", guild)
  def is_member?(member, guild), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)

  def authorized_for_command?(_, _, _, "help"), do: true

  def authorized_for_command?(member, guild, "help", "admin"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "setdaylightsavings", "admin"), do: is_admin?(member, guild)
  def authorized_for_command?(member, guild, "daylightsavings", "admin"), do: is_admin?(member, guild)

  def authorized_for_command?(member, guild, "dates", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "soon", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "mine", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "add", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "remove", "event"), do: is_admin?(member, guild) or  is_member?(member, guild)
  def authorized_for_command?(member, guild, "tryout", "event"), do: is_admin?(member, guild)

  def authorized_for_command?(member, guild, _, _), do: is_admin?(member, guild)
end
