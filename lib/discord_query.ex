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

  def users_with_role(%Role{id: role_id}, guild), do: users_with_role(role_id, guild)
  def users_with_role(role_id, %Guild{members: members}) do
    members
      |> Enum.filter(fn {_, m} -> role_id in m.roles end)
      |> Enum.map(fn {_, m} -> m.user end)
  end

  @spec matching_users([%User{}], String.t()) :: [%User{}]
  def matching_users(users, str) do
    users
      |> Enum.filter(fn u -> String.downcase(u.username) =~ str end)
  end
end
