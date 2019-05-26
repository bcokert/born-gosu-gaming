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
        111 => %{member() | roles: [11], user: %{user() | id: 111, username: "user1"}},
        222 => %{member() | roles: [22], user: %{user() | id: 222, username: "user2"}},
        333 => %{member() | roles: [11, 22, 66], user: %{user() | id: 333, username: "user3"}},
        444 => %{member() | roles: [11, 22, 33], user: %{user() | id: 444, username: "user4"}},
        555 => %{member() | roles: [33, 44, 55, 66], user: %{user() | id: 555, username: "user5"}},
        666 => %{member() | roles: [66], user: %{user() | id: 666, username: "user6"}},
        777 => %{member() | roles: [77], user: %{user() | id: 777, username: "user7"}},
        888 => %{member() | roles: [88], user: %{user() | id: 888, username: "user8"}},
      },
      roles: %{
        11 => %{role() | id: 11, name: "role1"},
        22 => %{role() | id: 22, name: "Mentor"},
        33 => %{role() | id: 33, name: "Born Gosu"},
        44 => %{role() | id: 44, name: "role4"},
        55 => %{role() | id: 55, name: "role5"},
        66 => %{role() | id: 66, name: "Admins"},
        77 => %{role() | id: 77, name: "Non-Born Gosu"},
        88 => %{role() | id: 88, name: "Tryout Member"},
      }
    }
  end

  setup_all do
    [guild: basic_guild()]
  end

  test "role_by_name" do
    assert %Role{id: 11, name: "role1"} = DiscordQuery.role_by_name("role1", basic_guild())
  end

  test "users_with_role as id" do
    users = DiscordQuery.users_with_role(11, basic_guild())

    assert [
      %User{username: "user1"},
      %User{username: "user3"},
      %User{username: "user4"}
    ] = users
  end

  test "users_with_role as name" do
    users = DiscordQuery.users_with_role("role1", basic_guild())

    assert [
      %User{username: "user1"},
      %User{username: "user3"},
      %User{username: "user4"}
    ] = users
  end

  test "users_with_role as struct" do
    users = DiscordQuery.users_with_role(%Role{id: 11}, basic_guild())

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

  test "admins" do
    assert [
      %User{username: "user3"},
      %User{username: "user5"},
      %User{username: "user6"},
    ] = DiscordQuery.admins(basic_guild())
  end

  test "mentors" do
    assert [
      %User{username: "user2"},
      %User{username: "user3"},
      %User{username: "user4"},
    ] = DiscordQuery.mentors(basic_guild())
  end

  test "members" do
    assert [
      %User{username: "user4"},
      %User{username: "user5"},
    ] = DiscordQuery.members(basic_guild())
  end

  test "non_members" do
    assert [
      %User{username: "user7"},
    ] = DiscordQuery.non_members(basic_guild())
  end

  test "tryouts" do
    assert [
      %User{username: "user8"},
    ] = DiscordQuery.tryouts(basic_guild())
  end

  test "user_has_role? with user_id", context do
    assert DiscordQuery.user_has_role?(333, "role1", context[:guild])
    assert DiscordQuery.user_has_role?(333, "Mentor", context[:guild])
    assert DiscordQuery.user_has_role?(333, "Admins", context[:guild])

    assert DiscordQuery.user_has_role?(333, "Admins", context[:guild])
    assert DiscordQuery.user_has_role?(555, "Admins", context[:guild])
    assert DiscordQuery.user_has_role?(666, "Admins", context[:guild])
  end

  test "user_has_role? with user struct", context do
    assert DiscordQuery.user_has_role?(%User{id: 333}, "role1", context[:guild])
    assert DiscordQuery.user_has_role?(%User{id: 333}, "Mentor", context[:guild])
    assert DiscordQuery.user_has_role?(%User{id: 333}, "Admins", context[:guild])

    assert DiscordQuery.user_has_role?(%User{id: 333}, "Admins", context[:guild])
    assert DiscordQuery.user_has_role?(%User{id: 555}, "Admins", context[:guild])
    assert DiscordQuery.user_has_role?(%User{id: 666}, "Admins", context[:guild])
  end
end
