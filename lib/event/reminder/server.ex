defmodule Event.Reminder.Server do
  use GenServer
  require Logger

  def init({intervals, get_all_events, alert_delta}) do
    Logger.info("Starting reminder process")
    events = get_all_events.()

    scheduled = Enum.reduce(events, %{}, fn (e, sched) ->
      schedule_intervals(e, intervals, alert_delta, sched)
    end)

    Logger.debug("Started reminder process and loaded in #{length(events)} events: #{Enum.join(Enum.map(events, fn e -> "\"#{event_key(e)}\"" end), ", ")}")
    {:ok, {scheduled, intervals, alert_delta}}
  end

  def handle_info({:remind, event, func}, state) do
    func.(event)
    {:noreply, state}
  end

  def handle_call({:schedule_event, event}, _from, {scheduled, intervals, alert_delta}) do
    {:reply, :ok, {schedule_intervals(event, intervals, alert_delta, scheduled), intervals, alert_delta}}
  end

  def handle_call({:unschedule_event, event}, _from, {scheduled, intervals, alert_delta}) do
    {:reply, :ok, {unschedule_intervals(event, scheduled), intervals, alert_delta}}
  end

  def handle_call({:reminders_per_event}, _from, state = {scheduled, _, _}) do
    {:reply, Enum.map(scheduled, fn {key, reminders} -> {key, length(reminders)} end) |> Map.new, state}
  end

  defp unschedule_intervals(event, scheduled) do
    if is_scheduled?(event, scheduled) do
      Logger.debug("Unscheduling #{event_key(event)} and removing #{length(scheduled[event_key(event)])} reminders")
      Enum.each(scheduled[event_key(event)], fn p -> Process.cancel_timer(p) end)
    end
    Map.drop(scheduled, [event_key(event)])
  end

  defp schedule_intervals(event, intervals, alert_delta, scheduled) do
    unscheduled = unschedule_intervals(event, scheduled)
    new_reminders = intervals
      |> Enum.filter(fn {i, _} -> i < Event.ms_until!(event) end)
      |> Enum.map(fn {i, f} -> schedule(event, f, Event.ms_until!(event) - i, alert_delta) end)
    
    Logger.info("Scheduled #{length(new_reminders)} reminders for #{event_key(event)} after unscheduling any existing reminders")
    Map.put(unscheduled, event_key(event), new_reminders)
  end

  defp schedule(event, func, ms_from_now, alert_delta) do
    Logger.debug("Scheduling '#{event_key(event)}' reminder for #{ms_from_now} ms from now with #{length(event.participants)} participants")
    start = now()
    f = fn e ->
      delta = (now() - start) - ms_from_now
      alert_slow(delta, alert_delta)
      Logger.debug("Executing reminder #{event_key(event)} from #{ms_from_now} ms ago after #{now() - start} ms")
      func.(e)
    end
    Process.send_after(Reminder.Server, {:remind, event, f}, ms_from_now)
  end

  defp is_scheduled?(event, scheduled) do
    scheduled[event_key(event)] != nil
  end

  defp event_key(event) do
    "#{event.name}::#{event.creator}"
  end

  defp now() do
    :os.system_time(:milli_seconds)
  end

  defp alert_slow(delta, alert_delta) do
    if delta > alert_delta do
      Logger.warn("Event Server was behind #{delta} ms. It may be having trouble keeping up.")
    end
  end
end
