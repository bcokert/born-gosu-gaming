defmodule DiscordQueryTest do
  use ExUnit.Case, async: true
  doctest Event

  alias Nostrum.Struct.User
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role

  import TestStructs, only: [member: 0, user: 0, role: 0]

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

  test "role_by_name", context do
    assert %Role{id: 11, name: "role1"} = DiscordQuery.role_by_name("role1", context[:guild])
  end

  test "users_with_role as id", context do
    users = DiscordQuery.users_with_role(11, context[:guild])

    assert [
      %User{username: "user1"},
      %User{username: "user3"},
      %User{username: "user4"}
    ] = users
  end

  test "users_with_role as name", context do
    users = DiscordQuery.users_with_role("role1", context[:guild])

    assert [
      %User{username: "user1"},
      %User{username: "user3"},
      %User{username: "user4"}
    ] = users
  end

  test "users_with_role as struct", context do
    users = DiscordQuery.users_with_role(%Role{id: 11}, context[:guild])

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

  test "admins", context do
    assert [
      %User{username: "user3"},
      %User{username: "user5"},
      %User{username: "user6"},
    ] = DiscordQuery.admins(context[:guild])
  end

  test "mentors", context do
    assert [
      %User{username: "user2"},
      %User{username: "user3"},
      %User{username: "user4"},
    ] = DiscordQuery.mentors(context[:guild])
  end

  test "members", context do
    assert [
      %User{username: "user4"},
      %User{username: "user5"},
    ] = DiscordQuery.members(context[:guild])
  end

  test "non_members", context do
    assert [
      %User{username: "user7"},
    ] = DiscordQuery.non_members(context[:guild])
  end

  test "tryouts", context do
    assert [
      %User{username: "user8"},
    ] = DiscordQuery.tryouts(context[:guild])
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
