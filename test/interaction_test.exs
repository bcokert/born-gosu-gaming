defmodule InteractionTest do
  use ExUnit.Case, async: false
  doctest Interaction

  test "adds new interactions" do
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test1",
      mid: 1,
      mstate: {},
      reducer: fn (x, _) -> x end,
      on_remove: nil,
    })

    assert :ok == Interaction.create(%Interaction{
      name: "test2",
      mid: 2,
      mstate: {},
      reducer: fn (x, _) -> x end,
      on_remove: nil,
    })
  end

  test "fails to remove interactions that don't exist" do
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test1",
      mid: 1,
      mstate: {},
      reducer: fn (x, _) -> x end,
      on_remove: nil,
    })

    assert {:error, "That interaction doesn't exist"} == Interaction.remove(2)
  end

  test "succeeds to remove interaction that was added" do
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test2",
      mid: 2,
      mstate: {},
      reducer: fn (x, _) -> x end,
      on_remove: nil,
    })

    assert :ok == Interaction.remove(2)
  end

  test "after removing an interaction, it can't be removed again" do
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test2",
      mid: 2,
      mstate: {},
      reducer: fn (x, _) -> x end,
      on_remove: nil,
    })

    assert :ok == Interaction.remove(2)
    assert {:error, "That interaction doesn't exist"} == Interaction.remove(2)
  end

  test "when an interaction is removed, the on_remove callback is called with the state" do
    me = self()
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test2",
      mid: 2,
      mstate: {1, 3, "banana"},
      reducer: fn (x, _) -> x end,
      on_remove: fn (state) -> send me, state end,
    })

    assert :ok == Interaction.remove(2)
    assert_receive {1, 3, "banana"}
  end

  test "interacting with a non-existent interaction returns an error" do
    Interaction.start_link()

    assert {:error, "No such interaction exists"} == Interaction.interact(2, %{emoji: ":yes:", sender: 89324978462, is_add: false})
  end

  test "interacting with an existing interaction calls the reducer with the state and the context" do
    me = self()
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test2",
      mid: 2,
      mstate: {1, 3, "banana"},
      reducer: fn (s, c) -> send me, {s, c} end,
      on_remove: nil,
    })

    assert :ok == Interaction.interact(2, %{emoji: ":yes:", sender: 89324978462, is_add: true})
    assert_receive {{1, 3, "banana"}, %{emoji: ":yes:", sender: 89324978462, is_add: true}}
  end

  test "interacting with an existing interaction saves the new state from the reducer" do
    me = self()
    Interaction.start_link()

    assert :ok == Interaction.create(%Interaction{
      name: "test2",
      mid: 2,
      mstate: {1},
      reducer: fn ({i}, _) -> {i+1} end,
      on_remove: fn (s) -> send me, s end,
    })

    assert :ok == Interaction.interact(2, %{emoji: ":yes:", sender: 89324978462, is_add: false})
    assert :ok == Interaction.interact(2, %{emoji: ":yes:", sender: 89324978462, is_add: false})
    assert :ok == Interaction.interact(2, %{emoji: ":yes:", sender: 89324978462, is_add: false})

    assert :ok == Interaction.remove(2)
    assert_receive {4}
  end
end
