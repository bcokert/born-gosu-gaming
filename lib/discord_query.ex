defmodule DiscordQuery do
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.User

  # All nostrum structs in here should come from the cache when possible
  # eg: Nostrum.Cache.GuildCache.get!(guild_id)
  # rather than: Nostrum.Api.get_guild!(guild_id)
  
  def role_by_name(role_name, %Guild{roles: roles}) do
    roles
      |> Enum.find(fn {_id, r} -> r.name == role_name end)
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
  def mentors(guild), do: users_with_role("Mentor", guild)
  def members(guild), do: users_with_role("Born Gosu", guild)
  def tryouts(guild), do: users_with_role("Tryout Member", guild)
  def non_members(guild), do: users_with_role("Non-Born Gosu", guild)

  def user_has_role?(%User{id: user_id}, role, guild), do: user_has_role?(user_id, role, guild)
  def user_has_role?(user_id, role, guild) when is_binary(role) do
    role
      |> users_with_role(guild)
      |> Enum.filter(fn %User{id: id} -> id == user_id end)
      |> (fn u -> length(u) > 0 end).()
  end

  @spec matching_users([%User{}], String.t()) :: [%User{}]
  def matching_users(users, str) when is_binary(str) do
    users
      |> Enum.filter(fn u -> String.downcase(u.username) =~ str end)
  end
end
