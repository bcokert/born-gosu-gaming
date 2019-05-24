defmodule EventTest do
  use ExUnit.Case, async: true
  doctest Event

  test "has the correct defaults" do
    {:ok, date, _} = DateTime.from_iso8601("2013-01-22 08:39:06+00")
    a = %Event{name: "nom", date: date, creator: "16231"}
    assert a.name == "nom"
    assert a.date == date
    assert a.creator == "16231"
    assert a.participants == []
    assert a.description == nil
    assert a.link == nil
  end
end
