defmodule EventTest do
  use ExUnit.Case, async: true
  doctest Event

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
end
