defmodule Authz do

  @moduledoc """
  Provides a declarative api for authorizing calls based on user or channel.
  """

  @api Application.get_env(:born_gosu_gaming, :discord_api)

  @type uid :: Nostrum.Snowflake.t()

  @spec has_roles?(uid, [String.t()], Nostrum.Struct.Guild.t()) :: boolean
  def has_roles?(user_id, [role_name | rest], guild) do
    member = @api.get_guild_member!(guild.id, user_id)
    DiscordQuery.member_has_role?(member, role_name, guild) and has_roles?(user_id, rest, guild)
  end
  def has_roles?(_, [], _), do: true
  def has_roles?(user_id, role_name, guild), do: has_roles?(user_id, [role_name], guild)

  @spec is_tryout?(uid, Nostrum.Struct.Guild.t()) :: boolean
  def is_tryout?(user_id, guild) do
    has_roles?(user_id, ["Tryout Member"], guild)
  end

  @spec is_member?(uid, Nostrum.Struct.Guild.t()) :: boolean
  def is_member?(user_id, guild) do
    has_roles?(user_id, ["Born Gosu"], guild)
  end

  @spec is_admin?(uid, Nostrum.Struct.Guild.t()) :: boolean
  def is_admin?(user_id, guild) do
    has_roles?(user_id, ["Admins"], guild)
  end

  def authorized_for_command?(_, _, "help"), do: true
  def authorized_for_command?(member, guild, "adminhelp"), do: DiscordQuery.member_has_role?(member, "Admins", guild)
  def authorized_for_command?(member, guild, "setdaylightsavings"), do: DiscordQuery.member_has_role?(member, "Admins", guild)
  def authorized_for_command?(member, guild, "daylightsavings"), do: DiscordQuery.member_has_role?(member, "Admins", guild)
  def authorized_for_command?(member, guild, "dates"), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)
  def authorized_for_command?(member, guild, "soon"), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)
  def authorized_for_command?(member, guild, "mine"), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)
  def authorized_for_command?(member, guild, "add"), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)
  def authorized_for_command?(member, guild, "remove"), do: DiscordQuery.member_has_role?(member, "Born Gosu", guild)
  def authorized_for_command?(member, guild, "tryout"), do: DiscordQuery.member_has_role?(member, "Admins", guild)
end
