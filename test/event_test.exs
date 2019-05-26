defmodule EventTest do
  use ExUnit.Case, async: true
  doctest Event

  import TestStructs, only: [message: 0]

  test "%Event has the correct defaults" do
    {:ok, date, _} = DateTime.from_iso8601("2013-01-22 08:39:06+00")
    event = %Event{name: "nom", date: date, creator: "16231"}
    
    assert %Event{
      name: "nom",
      date: date,
      creator: "16231",
      participants: [],
      description: nil,
      link: nil,
    } = event
  end

  test "help" do
    dmsg = %{message() | content: "!events help"}
    Command.DiscordConsumer.handle_event({:MESSAGE_CREATE, {dmsg}, nil})

    receive do
      {123, msg} ->
        assert msg == "I'll dm you"
    after
      50 ->
        assert false
    end

    receive do
      {456, msg} ->
        assert msg =~ "Available commands:"
        assert msg =~ "- help"
        assert msg =~ "- soon"
        assert msg =~ "- me"
        assert msg =~ "- add"
        assert msg =~ "- remove"
        assert msg =~ "- register"
        assert msg =~ "- unregister"
    after
      50 ->
        assert false
    end
  end
end
