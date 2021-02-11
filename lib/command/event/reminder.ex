defmodule Event.Reminder do

  def start_link(intervals, get_all \\ &Event.Persister.get_all/0, alert_delta \\ 50) do
    GenServer.start_link(Event.Reminder.Server, {intervals, get_all, alert_delta}, [name: Reminder.Server])
  end

  def schedule_all_reminders(events) when is_list(events) do
    Enum.map(events, fn e -> GenServer.call(Reminder.Server, {:schedule_event, e}) end)
  end

  def schedule_reminders(event = %Event{}) do
    GenServer.call(Reminder.Server, {:schedule_event, event})
  end

  def unschedule_reminders(event = %Event{}) do
    GenServer.call(Reminder.Server, {:unschedule_event, event})
  end

  def reminders_per_event() do
    GenServer.call(Reminder.Server, {:reminders_per_event})
  end
end
