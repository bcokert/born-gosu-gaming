defmodule DiscordQueryTest do
  use ExUnit.Case, async: true
  doctest Event

  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Guild.Role

  def user do
    %User{
      avatar: "XXXXXXXXXXXXXX",
      bot: false,
      discriminator: "XXXX",
      email: nil,
      id: 1234567736329846798,
      mfa_enabled: nil,
      username: "XXXXX",
      verified: nil
    }
  end

  def member do
    %Member{
      deaf: false,
      joined_at: "2019-05-20T16:16:12.363574+00:00",
      mute: false,
      nick: nil,
      roles: [],
      user: user()
    }
  end

  def role do
    %Role{
      color: 0,
      hoist: true,
      id: 234264626636234,
      managed: false,
      mentionable: true,
      name: "XXXXXXXXXX",
      permissions: 6432632,
      position: 232642364
    }
  end

  def basic_guild do
    %Guild{
      members: %{
        111 => %{member() | roles: [11], user: %{user() | username: "user1"}},
        222 => %{member() | roles: [22], user: %{user() | username: "user2"}},
        333 => %{member() | roles: [11, 22], user: %{user() | username: "user3"}},
        444 => %{member() | roles: [11, 22], user: %{user() | username: "user4"}},
        555 => %{member() | roles: [33, 44, 55], user: %{user() | username: "user5"}},
      },
      roles: %{
        11 => %{role() | id: 11, name: "role1"},
        22 => %{role() | id: 22, name: "role2"},
        33 => %{role() | id: 33, name: "role3"},
        44 => %{role() | id: 44, name: "role4"},
        55 => %{role() | id: 55, name: "role5"},
      }
    }
  end

  test "role_by_name" do
    assert %Role{id: 11, name: "role1"} = DiscordQuery.role_by_name("role1", basic_guild())
  end

  test "users_with_role" do
    users = DiscordQuery.users_with_role(11, basic_guild())

    assert [
      %User{username: "user1"},
      %User{username: "user3"},
      %User{username: "user4"}
    ] = users
  end

  test "matching_users" do
    users = [
      %User{user() | username: "bob"},
      %User{user() | username: "bab"},
      %User{user() | username: "baby"},
      %User{user() | username: "bobby"},
      %User{user() | username: "jim"},
    ]

    assert [
      %User{username: "bob"},
      %User{username: "bobby"},
    ] = DiscordQuery.matching_users(users, "bob")

    assert [
      %User{username: "bob"},
      %User{username: "bab"},
      %User{username: "baby"},
      %User{username: "bobby"},
    ] = DiscordQuery.matching_users(users, "b")

    assert [] = DiscordQuery.matching_users(users, "q")
  end
end
