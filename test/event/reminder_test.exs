defmodule Event.ReminderTest do
  use ExUnit.Case, async: true
  doctest Event.Reminder
  doctest Event.Reminder.Server

  defp ms_from_now(ms) do
    {:ok, d} = DateTime.now("Etc/UTC")
    DateTime.add(d, ms, :millisecond)
  end

  defp fake_get_all(n, from_now) do
    Enum.map(1..n, fn i -> %Event{name: "event#{i}", date: ms_from_now(from_now), creator: 123} end)
  end

  defp now() do
    :os.system_time(:milli_seconds)
  end

  test "server asks for events upon startup" do
    me = self()
    get_all = fn () ->
      send me, :passed
      []  
    end
    {:ok, _} = Event.Reminder.Server.start_link([], get_all)  
    assert_receive :passed
  end

  test "doesn't schedule reminders if there are no events" do
    me = self()
    intervals = [
      {1, fn _ -> send me, :reminder1 end},
      {1, fn _ -> send me, :reminder2 end},
    ]
    get_all = fn () -> [] end
    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)

    refute_receive :reminder1
    refute_receive :reminder2
  end

  test "schedules reminders for each event, which execute" do
    me = self()
    intervals = [
      {1, fn _ -> send me, :reminder1 end},
      {1, fn _ -> send me, :reminder2 end},
    ]
    get_all = fn () -> fake_get_all(3, 5) end
    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)

    assert %{
      "event1::123" => 2,
      "event2::123" => 2,
      "event3::123" => 2,
    } = Event.Reminder.reminders_per_event()
    
    assert_receive :reminder1
    assert_receive :reminder2
    assert_receive :reminder1
    assert_receive :reminder2
    assert_receive :reminder1
    assert_receive :reminder2
  end

  test "executes reminders at correct intervals" do
    me = self()
    intervals = [
      {1, fn _ -> send me, {:reminder1, now()} end},
      {200, fn _ -> send me, {:reminder2, now()} end},
      {1000, fn _ -> send me, {:reminder3, now()} end},
    ]
    get_all = fn () -> fake_get_all(1, 1300) end

    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)
    start = now()

    assert %{
      "event1::123" => 3,
    } = Event.Reminder.reminders_per_event()

    max_error = 20

    receive do
      {:reminder3, t3} -> assert_in_delta 300, t3 - start, max_error
    after
      2000 -> assert false
    end
    receive do
      {:reminder2, t2} -> assert_in_delta 1100, t2 - start, max_error
    after
      2000 -> assert false
    end
    receive do
      {:reminder1, t3} -> assert_in_delta 1299, t3 - start, max_error
    after
      2000 -> assert false
    end
  end

  test "schedule new events added after startup" do
    me = self()
    intervals = [
      {1, fn _ -> send me, :reminder1 end},
      {1, fn _ -> send me, :reminder2 end},
    ]
    get_all = fn () -> fake_get_all(0, 5) end
    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)

    assert %{} = Event.Reminder.reminders_per_event()

    :ok = Event.Reminder.schedule_reminders(%Event{name: "abacab", creator: 91246712, date: ms_from_now(1000)})

    assert %{
      "abacab::91246712" => 2,
    } = Event.Reminder.reminders_per_event()
    
    assert_receive :reminder1
    assert_receive :reminder2
  end

  test "scheduling should unschedule existing reminders for an event before scheduling that same event" do
    me = self()
    intervals = [
      {1, fn e -> send me, "#{e.name}-1" end},
      {15, fn e -> send me, "#{e.name}-15" end},
    ]
    get_all = fn () -> fake_get_all(1, 200) end
    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)

    assert %{
      "event1::123" => 2,
    } = Event.Reminder.reminders_per_event()

    :ok = Event.Reminder.schedule_reminders(%Event{name: "event1", creator: 123, date: ms_from_now(200)})
    assert %{
      "event1::123" => 2,
    } = Event.Reminder.reminders_per_event()

    :ok = Event.Reminder.schedule_reminders(%Event{name: "event2", creator: 123, date: ms_from_now(200)})
    assert %{
      "event1::123" => 2,
      "event2::123" => 2,
    } = Event.Reminder.reminders_per_event()

    :ok = Event.Reminder.schedule_reminders(%Event{name: "event1", creator: 123, date: ms_from_now(200)})
    assert %{
      "event1::123" => 2,
      "event2::123" => 2,
    } = Event.Reminder.reminders_per_event()
    
    Process.sleep(180)
    assert_receive "event1-15"
    assert_receive "event2-15"
    assert_receive "event1-1"
    assert_receive "event2-1"
    refute_receive "event1-15"
    refute_receive "event2-15"
    refute_receive "event1-1"
    refute_receive "event2-1"
  end

  test "unscheduling should unschedule existing reminders for an event" do
    me = self()
    intervals = [
      {1, fn e -> send me, "#{e.name}-1" end},
      {2, fn e -> send me, "#{e.name}-2" end},
    ]
    get_all = fn () -> fake_get_all(3, 100) end
    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)

    assert %{
      "event1::123" => 2,
      "event2::123" => 2,
      "event3::123" => 2,
    } = Event.Reminder.reminders_per_event()

    :ok = Event.Reminder.unschedule_reminders(%Event{name: "event1", creator: 123, date: ms_from_now(200)})
    assert %{
      "event2::123" => 2,
      "event3::123" => 2,
    } = Event.Reminder.reminders_per_event()

    :ok = Event.Reminder.unschedule_reminders(%Event{name: "event3", creator: 123, date: ms_from_now(200)})
    :ok = Event.Reminder.unschedule_reminders(%Event{name: "event3", creator: 123, date: ms_from_now(200)})
    :ok = Event.Reminder.unschedule_reminders(%Event{name: "event3", creator: 123, date: ms_from_now(200)})
    assert %{
      "event2::123" => 2,
    } = Event.Reminder.reminders_per_event()

    Process.sleep(80)
    assert_receive "event2-2"
    assert_receive "event2-1"
    refute_receive "event1-1"
    refute_receive "event1-2"
    refute_receive "event3-1"
    refute_receive "event3-2"
  end

  test "only schedules reminders in the future" do
    me = self()
    intervals = [
      {1, fn _ -> send me, :reminder1 end},
      {5, fn _ -> send me, :reminder5 end},
      {10, fn _ -> send me, :reminder10 end},
      {20, fn _ -> send me, :reminder20 end},
      {30, fn _ -> send me, :reminder30 end},
    ]
    get_all = fn () -> fake_get_all(1, 18) end
    {:ok, _} = Event.Reminder.Server.start_link(intervals, get_all)

    assert %{
      "event1::123" => 3,
    } = Event.Reminder.reminders_per_event()
    
    assert_receive :reminder1
    assert_receive :reminder5
    assert_receive :reminder10
  end
end
