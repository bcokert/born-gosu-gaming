defmodule Event.Formatter do

  @minute 1000*60
  @hour @minute*60
  @day @hour*24
  @sec_per_hour 60*60

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

  @days {
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  }

  def full_summary(%Event{name: name, date: date, link: link}) do
    link_raw = nil_to_string(link)
    link_text = if String.length(link_raw) > 0, do: "<#{link_raw}>", else: link_raw

    day_of_week_int = date
      |> DateTime.to_date()
      |> Date.day_of_week()
    
    day_of_week = elem(@days, day_of_week_int-1)

    # day_of_week = elem(@days, Date.day_of_week(DateTime.to_date(date))-1)

    date_edt = DateTime.add(date, -4 * @sec_per_hour, :second)
    date_cest = DateTime.add(date, 2 * @sec_per_hour, :second)
    date_kst = DateTime.add(date, 9 * @sec_per_hour, :second)

    time_str = [
      "#{date_edt.hour}:#{pad_2digit(date_edt.minute)} EDT",
      "#{date_cest.hour}:#{pad_2digit(date_cest.minute)} CEST",
      "#{date_kst.hour}:#{pad_2digit(date_kst.minute)} KST",
    ]
      |> Enum.map(fn t -> "__#{t}__" end)
      |> Enum.join("  /  ")

    [
      "__***#{name}***__",
      "**Date:** #{elem(@months, date_edt.month-1)} #{date_edt.day}, #{date_edt.year} (#{day_of_week})",
      "**Time:** #{time_str}",
      "(#{time_until!(date)} from now)",
      "#{link_text}",
    ]
      |> Enum.filter(fn s -> String.length(s) > 0 end)
      |> Enum.join("\n")
  end

  defp pad_2digit(amnt) when amnt < 10, do: "0#{amnt}"
  defp pad_2digit(amnt), do: "#{amnt}"

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
