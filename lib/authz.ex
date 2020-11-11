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

  @doc """
  Checks if the channel provided is a teamleague-only channel.
  This is useful for hiding information from non-members.
  A set of custom channels is added to this for dynamic settings/special cases.
  """
  @spec is_teamleague_channel?(uid, Nostrum.Struct.Guild.t()) :: boolean
  def is_teamleague_channel?(channel_id, guild) do
    teamleague_channels(guild)
      |> Enum.map(fn c -> c.id end)
      |> Enum.member?(channel_id)
  end

  def teamleague_channels(guild) do
    guild.channels
      |> Enum.filter(fn {_, c} -> channel_is_teamleague?(c, guild) end)
      |> Enum.map(fn {_, c} -> c end)
  end

  defp channel_is_teamleague?(%Nostrum.Struct.Channel{parent_id: parent, name: name}, guild) do
    %Nostrum.Struct.Channel{id: teamleague_parent_id} = DiscordQuery.channel_by_name("Teamleague channels", guild)
    parent == teamleague_parent_id or Enum.member?(custom_teamleague_channels(), name)
  end

  defp custom_teamleague_channels() do
    ["ashenchat", "bg-events"]
  end
end
