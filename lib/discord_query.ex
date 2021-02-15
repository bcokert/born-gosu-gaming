defmodule DiscordQuery do
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild.Member

  # All nostrum structs in here should come from the cache when possible
  # eg: Nostrum.Cache.GuildCache.get!(guild_id)
  # rather than: Nostrum.Api.get_guild!(guild_id)
  
  def role_by_name(role_name, %Guild{roles: roles}) do
    roles
      |> Enum.find({:none, :none}, fn {_id, r} -> r.name == role_name end)
      |> elem(1)
  end

  def channel_by_name(channel_name, %Guild{channels: channels}) do
    channels
      |> Enum.find(fn {_id, c} -> c.name == channel_name end)
      |> elem(1)
  end

  def users_with_role(role, guild) when is_binary(role) do
    role
      |> role_by_name(guild)
      |> users_with_role(guild)
  end
  def users_with_role(%Role{id: role_id}, guild), do: users_with_role(role_id, guild)
  def users_with_role(role_id, %Guild{members: members}) do
    members
      |> Enum.filter(fn {_, m} -> role_id in m.roles end)
      |> Enum.map(fn {_, m} -> m.user end)
  end

  def admins(guild), do: users_with_role("Admins", guild)
  def mentors(guild), do: users_with_role("Mentors", guild)
  def members(guild), do: users_with_role("Born Gosu", guild)
  def tryouts(guild), do: users_with_role("Tryout Member", guild)
  def non_members(guild), do: users_with_role("Non-Born Gosu", guild)

  def member_has_role?(%Member{roles: roles}, role, guild) when is_binary(role) do
    roleobj = role_by_name(role, guild)
    roleobj != :none and Enum.any?(roles, fn r -> r == roleobj.id end)
  end

  def member_has_any_role?(_, [], _), do: false
  def member_has_any_role?(m, [next | roles], guild) do
    member_has_role?(m, next, guild) or member_has_any_role?(m, roles, guild)
  end

  def member_has_all_roles?(_, [], _), do: true
  def member_has_all_roles?(m, [next | roles], guild) do
    member_has_role?(m, next, guild) and member_has_all_roles?(m, roles, guild)
  end

  @spec matching_users([%User{}], String.t()) :: [%User{}]
  def matching_users(users, str) when is_binary(str) do
    users
      |> Enum.filter(fn u -> String.downcase(u.username) =~ str end)
  end
end
