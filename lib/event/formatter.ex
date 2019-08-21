defmodule Event.Formatter do

  @minute 1000*60
  @hour @minute*60
  @day @hour*24
  @edt_offset_seconds -4*60*60

  @months {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  }

  def full_summary(%Event{name: name, date: date, link: link}) do
    link_raw = nil_to_string(link)
    link_text = if String.length(link_raw) > 0, do: "<#{link_raw}>", else: link_raw

    date_edt = DateTime.add(date, @edt_offset_seconds, :second)

    [
      "__**#{name}**__",
      "#{elem(@months, date_edt.month-1)} #{date_edt.day}, #{date_edt.year} at #{date_edt.hour}:#{date_edt.minute} EDT _(#{time_until!(date)} from now)_",
      "#{link_text}",
    ]
      |> Enum.filter(fn s -> String.length(s) > 0 end)
      |> Enum.join("\n")
  end

  @doc """
  Prints the time until the event or given date, in human format.
  Assumes the date is in the future. If it isn't, you'll get negative amounts.
  """
  def time_until!({days, hours, minutes}) do
    [{days > 0, "#{days} days"}, {hours > 0, "#{hours} hours"}, {minutes > 0, "#{minutes} minutes"}]
      |> Enum.filter(fn {keep, _} -> keep end)
      |> Enum.map(fn {_, val} -> val end)
      |> Enum.join(", ")
  end
  def time_until!(%Event{date: date}), do: time_until!(time_blocks_until!(date))
  def time_until!(date), do: time_until!(time_blocks_until!(date))

  @doc """
  Prints the time past since the event or given date, in human format.
  Assumes the date is in the past. If it isn't, you'll get negative amounts.
  """
  def time_ago!(date) do
    {neg_days, neg_hours, neg_minutes} = time_blocks_until!(date)
    time_until!({neg_days*-1, neg_hours*-1, neg_minutes*-1})
  end


  defp nil_to_string(nil), do: ""
  defp nil_to_string(str), do: str

  def ms_until!(%Event{date: date}), do: ms_until!(date)
  def ms_until!(date) do
    {:ok, now} = DateTime.now("Etc/UTC")
    DateTime.diff(date, now, :millisecond)
  end

  defp time_blocks_until!(date) do
    ms_total = ms_until!(date)
    days = div(ms_total, @day)
    hours = div(rem(ms_total, @day), @hour)
    mins = div(rem(ms_total, @hour), @minute)
    {days, hours, mins}
  end
end
