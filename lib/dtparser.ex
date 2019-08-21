defmodule DTParser do

  @timezones_to_offset %{
    pdt: -7,
    cdt: -5,
    edt: -4,
    utc: 0,
    wet: 1,
    eet: 2,
    cet: 2,
    kst: 9
  }

  @months "jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec|january|february|march|april|june|july|august|september|october|november|december"
  @month_to_int %{
    jan: 1,
    feb: 2,
    mar: 3,
    apr: 4,
    may: 5,
    jun: 6,
    jul: 7,
    aug: 8,
    sep: 9,
    sept: 9,
    oct: 10,
    nov: 11,
    dec: 12,
    january: 1,
    february: 2,
    march: 3,
    april: 4,
    june: 6,
    july: 7,
    august: 8,
    september: 9,
    october: 10,
    november: 11,
    december: 12
  }
  @time_regex ~r/((\d{1,2})\s*(am|pm))|(\d{1,2})(:(\d\d))\s*(am|pm)?/
  @date_regex ~r/(((\d{4})[-\/])?(\d{1,2})[-\/](\d{1,2}))|(#{@months})\s*(\d{1,2})([^\d]+(\d{4}))?/
  @timezone_regex ~r/\b(pdt|cdt|edt|kst|wet|eet|cet|utc)\b/
  
  @type time_result :: [hour: integer, min: integer]
  @type time_results :: [time_result]

  @type date_result :: [year: integer, month: integer, day: integer]
  @type date_results :: [date_result]

  @type timezone_result :: [name: String.t(), offset: integer]
  @type timezone_results :: [timezone_result]

  @doc"""
  Parses an arbitrary string to find all potential valid times.
  Is only interested in hours and minutes.
  Output is always in 24 hour format, in a list of keyword lists sorted by earliest first:
  [
    [hour: 6, min: 20],
    [hour: 16, min: 30]
  ]

  Examples
    iex> DTParser.parse_time(nil)
    []

    iex> DTParser.parse_time("")
    []

    iex> DTParser.parse_time("at 1 pm")
    [[hour: 13, min: 0]]

    iex> DTParser.parse_time("1:30")
    [[hour: 1, min: 30]]

    iex> DTParser.parse_time("11:30")
    [[hour: 11, min: 30]]

    iex> DTParser.parse_time("16:30")
    [[hour: 16, min: 30]]

    iex> DTParser.parse_time("1:00")
    [[hour: 1, min: 0]]

    iex> DTParser.parse_time("11:00")
    [[hour: 11, min: 0]]

    iex> DTParser.parse_time("16:00")
    [[hour: 16, min: 0]]

    iex> DTParser.parse_time("4:30pm")
    [[hour: 16, min: 30]]

    iex> DTParser.parse_time("4:30 pm")
    [[hour: 16, min: 30]]

    iex> DTParser.parse_time("4:30          pm")
    [[hour: 16, min: 30]]

    iex> DTParser.parse_time("4:30 am")
    [[hour: 4, min: 30]]

    iex> DTParser.parse_time("4 am")
    [[hour: 4, min: 0]]

    iex> DTParser.parse_time("16 am")
    []

    iex> DTParser.parse_time("16 pm")
    []

    iex> DTParser.parse_time("12:21 am")
    [[hour: 0, min: 21]]

    iex> DTParser.parse_time("12:21 pm")
    [[hour: 12, min: 21]]

    iex> DTParser.parse_time("11:59 am")
    [[hour: 11, min: 59]]

    iex> DTParser.parse_time("12:00 am")
    [[hour: 0, min: 0]]

    iex> DTParser.parse_time("12:01 am")
    [[hour: 0, min: 1]]

    iex> DTParser.parse_time("11:59 pm")
    [[hour: 23, min: 59]]

    iex> DTParser.parse_time("12:00 pm")
    [[hour: 12, min: 0]]

    iex> DTParser.parse_time("12:01 pm")
    [[hour: 12, min: 1]]

    iex> DTParser.parse_time("0 pm")
    []

    iex> DTParser.parse_time("0 am")
    [[hour: 0, min: 0]]

    iex> DTParser.parse_time("12 am")
    [[hour: 0, min: 0]]

    iex> DTParser.parse_time("12 pm")
    [[hour: 12, min: 0]]

    iex> DTParser.parse_time(" 9873512 1928512 981523  13:12 98ashsg a3293 25372 5273")
    [[hour: 13, min: 12]]

    iex> DTParser.parse_time("The event 'pizza' is on July 28, 2021 at 4:30 pm")
    [[hour: 16, min: 30]]

    iex> DTParser.parse_time("Be there by 5")
    []

    iex> DTParser.parse_time("Be there by 5 pm")
    [[hour: 17, min: 0]]

    iex> DTParser.parse_time("Be there by 5:20 am")
    [[hour: 5, min: 20]]

    iex> DTParser.parse_time("Be there by 5:20 pm or 7:30 am")
    [[hour: 7, min: 30], [hour: 17, min: 20]]

    iex> DTParser.parse_time("Be there by 5:20 or 7:30 ")
    [[hour: 5, min: 20], [hour: 7, min: 30]]

    iex> DTParser.parse_time("3 or 1")
    []

    iex> DTParser.parse_time("3 pm or 1am")
    [[hour: 1, min: 0], [hour: 15, min: 0]]

    iex> DTParser.parse_time("3 pm or at 4 or 1am or at 1")
    [[hour: 1, min: 0], [hour: 15, min: 0]]

    iex> DTParser.parse_time("3 pm or at 4 or 1am or at 1 or at 1am or at 1am")
    [[hour: 1, min: 0], [hour: 15, min: 0]]

    iex> DTParser.parse_time("at 3 or at 1")
    []
  """
  @spec parse_time(String.t()) :: time_results
  def parse_time(nil), do: []
  def parse_time(""), do: []
  def parse_time(str) do
    Regex.scan(@time_regex, String.downcase(str))
      |> Enum.map(&(process_possible_time(&1)))
      |> Enum.filter(fn r -> r != :no_match end)
      |> Enum.uniq()
      |> Enum.sort(fn ([hour: h1, min: m1], [hour: h2, min: m2]) -> h1*60 + m1 < h2*60 + m2 end)
  end

  defp process_possible_time([]), do: :no_match
  defp process_possible_time([_]), do: :no_match
  defp process_possible_time([_, _, "0", "pm"]), do: :no_match
  defp process_possible_time([_, _, hourstr, "am"]) do
    hour = toint(hourstr)
    if hour <= 12, do: process_legal_time(rem(hour, 12)), else: :no_match
  end
  defp process_possible_time([_, _, hourstr, "pm"]) do
    hour = toint(hourstr)
    if hour <= 12, do: process_legal_time(hour + add12_unless12(hour)), else: :no_match
  end
  defp process_possible_time([_, _, _, _, hour, _, min]), do: process_legal_time(hour, min)
  defp process_possible_time([_, _, _, _, hourstr, _, min, "am"]) do
    hour = toint(hourstr)
    if hour <= 12, do: process_legal_time(rem(hour, 12), min), else: :no_match
  end
  defp process_possible_time([_, _, _, _, "0", _, _, "pm"]), do: :no_match
  defp process_possible_time([_, _, _, _, hourstr, _, min, "pm"]) do
    hour = toint(hourstr)
    if hour <= 12, do: process_legal_time(hour + add12_unless12(hour), min), else: :no_match
  end

  defp process_legal_time(hourstr, minstr \\ 0) do
    {hour, min} = {toint(hourstr), toint(minstr)}
    if hour >= 0 and hour <= 23 and min >= 0 and min <= 59 do
      [hour: hour, min: min]
    else
      :no_match
    end
  end

  defp toint(i) when is_integer(i), do: i
  defp toint(i) when is_binary(i), do: String.to_integer(i)

  defp add12_unless12(12), do: 0
  defp add12_unless12(_), do: 12

  @doc"""
  Parses an arbitrary string to find all potential valid dates.
  Is only interested in month and day.
  Output is always in a list of keyword lists sorted by earliest first:
  [
    [year: 2019, month: 6, day: 11],
    [year: 2019, month: 6, day: 19]
  ]

  Examples
    iex> DTParser.parse_date(nil)
    []

    iex> DTParser.parse_date("")
    []

    iex> DTParser.parse_date("2019-07-21")
    [[year: 2019, month: 7, day: 21]]

    iex> DTParser.parse_date("2019-7-21")
    [[year: 2019, month: 7, day: 21]]

    iex> DTParser.parse_date("2019-7-03")
    [[year: 2019, month: 7, day: 3]]

    iex> DTParser.parse_date("2019-7-3")
    [[year: 2019, month: 7, day: 3]]

    iex> DTParser.parse_date("07-21")
    [[year: Date.utc_today().year, month: 7, day: 21]]

    iex> DTParser.parse_date("7-21")
    [[year: Date.utc_today().year, month: 7, day: 21]]

    iex> DTParser.parse_date("7-03")
    [[year: Date.utc_today().year, month: 7, day: 3]]

    iex> DTParser.parse_date("7-3")
    [[year: Date.utc_today().year, month: 7, day: 3]]

    iex> DTParser.parse_date("07-3")
    [[year: Date.utc_today().year, month: 7, day: 3]]

    iex> DTParser.parse_date("2019/07/21")
    [[year: 2019, month: 7, day: 21]]

    iex> DTParser.parse_date("07/3")
    [[year: Date.utc_today().year, month: 7, day: 3]]

    iex> DTParser.parse_date("2022 07/3 125821")
    [[year: Date.utc_today().year, month: 7, day: 3]]

    iex> DTParser.parse_date("8347523 07/3 2022")
    [[year: Date.utc_today().year, month: 7, day: 3]]

    iex> DTParser.parse_date("8347523 2026-01-1 2022")
    [[year: 2026, month: 1, day: 1]]

    iex> DTParser.parse_date("2021 1997-1-1 2022")
    [[year: 1997, month: 1, day: 1]]

    iex> DTParser.parse_date("January 29")
    [[year: Date.utc_today().year, month: 1, day: 29]]

    iex> DTParser.parse_date("Jan 1")
    [[year: Date.utc_today().year, month: 1, day: 1]]

    iex> DTParser.parse_date("February 01")
    [[year: Date.utc_today().year, month: 2, day: 1]]

    iex> DTParser.parse_date("feb 13")
    [[year: Date.utc_today().year, month: 2, day: 13]]

    iex> DTParser.parse_date("March 03 2016")
    [[year: 2016, month: 3, day: 3]]

    iex> DTParser.parse_date("mar 13 2023")
    [[year: 2023, month: 3, day: 13]]

    iex> DTParser.parse_date("Apr 30")
    [[year: Date.utc_today().year, month: 4, day: 30]]

    iex> DTParser.parse_date("april     06 2023")
    [[year: 2023, month: 4, day: 6]]

    iex> DTParser.parse_date("may30")
    [[year: Date.utc_today().year, month: 5, day: 30]]

    iex> DTParser.parse_date("may 30")
    [[year: Date.utc_today().year, month: 5, day: 30]]

    iex> DTParser.parse_date("ma 30")
    []

    iex> DTParser.parse_date("ma y 30")
    []

    iex> DTParser.parse_date("may")
    []

    iex> DTParser.parse_date("may 30 april")
    [[year: Date.utc_today().year, month: 5, day: 30]]

    iex> DTParser.parse_date("may 30 april 2016")
    [[year: 2016, month: 5, day: 30]]

    iex> DTParser.parse_date("jun 3 april 2016")
    [[year: 2016, month: 6, day: 3]]

    iex> DTParser.parse_date("2015 june 3 june 4 june 4 jun 15")
    [[year: Date.utc_today().year, month: 6, day: 3], [year: Date.utc_today().year, month: 6, day: 4], [year: Date.utc_today().year, month: 6, day: 15]]

    iex> DTParser.parse_date("jul 3 2016")
    [[year: 2016, month: 7, day: 3]]

    iex> DTParser.parse_date("JULY 20")
    [[year: Date.utc_today().year, month: 7, day: 20]]

    iex> DTParser.parse_date("aug 3 2016512")
    [[year: 2016, month: 8, day: 3]]

    iex> DTParser.parse_date("august 2021 20")
    [[year: Date.utc_today().year, month: 8, day: 20]]

    iex> DTParser.parse_date("august 20 20")
    [[year: Date.utc_today().year, month: 8, day: 20]]

    iex> DTParser.parse_date("20 20")
    []

    iex> DTParser.parse_date("sept sept 1")
    [[year: Date.utc_today().year, month: 9, day: 1]]

    iex> DTParser.parse_date("sep 1st")
    [[year: Date.utc_today().year, month: 9, day: 1]]

    iex> DTParser.parse_date("sep 2nd")
    [[year: Date.utc_today().year, month: 9, day: 2]]

    iex> DTParser.parse_date("sePtember 3rd")
    [[year: Date.utc_today().year, month: 9, day: 3]]

    iex> DTParser.parse_date("sept 4th")
    [[year: Date.utc_today().year, month: 9, day: 4]]

    iex> DTParser.parse_date("sept          24th")
    [[year: Date.utc_today().year, month: 9, day: 24]]

    iex> DTParser.parse_date("september          24 th")
    [[year: Date.utc_today().year, month: 9, day: 24]]

    iex> DTParser.parse_date("2011 september          24 th")
    [[year: Date.utc_today().year, month: 9, day: 24]]

    iex> DTParser.parse_date(" oct          01 th 2011")
    [[year: 2011, month: 10, day: 1]]

    iex> DTParser.parse_date(" oct3 th")
    [[year: Date.utc_today().year, month: 10, day: 3]]

    iex> DTParser.parse_date(" oct3st2014")
    [[year: 2014, month: 10, day: 3]]

    iex> DTParser.parse_date(" october09rd2014")
    [[year: 2014, month: 10, day: 9]]

    iex> DTParser.parse_date(" nov 3")
    [[year: Date.utc_today().year, month: 11, day: 3]]

    iex> DTParser.parse_date(" nov 33")
    []

    iex> DTParser.parse_date(" nov 3 november 9 jan 3rd 2018")
    [[year: 2018, month: 1, day: 3], [year: Date.utc_today().year, month: 11, day: 3], [year: Date.utc_today().year, month: 11, day: 9]]

    iex> DTParser.parse_date(" DEC 01")
    [[year: Date.utc_today().year, month: 12, day: 1]]

    iex> DTParser.parse_date(" DEC 0")
    []

    iex> DTParser.parse_date(" DECemBer -3")
    []

    iex> DTParser.parse_date(" AAASEFASDjhidecemberiodshf 3")
    []

    iex> DTParser.parse_date(" janfeb 3")
    [[year: Date.utc_today().year, month: 2, day: 3]]

    iex> DTParser.parse_date(" juliet 3")
    []

    iex> DTParser.parse_date(" december 1 1111")
    [[year: 1111, month: 12, day: 1]]

    iex> DTParser.parse_date(" december 1-1111")
    [[year: 1111, month: 12, day: 1]]
  """
  @spec parse_date(String.t()) :: date_results
  def parse_date(nil), do: []
  def parse_date(""), do: []
  def parse_date(str) do
    Regex.scan(@date_regex, String.downcase(str))
      |> Enum.map(&(process_possible_date(&1)))
      |> Enum.filter(fn r -> r != :no_match end)
      |> Enum.uniq()
      |> Enum.sort(fn ([year: y1, month: m1, day: d1], [year: y2, month: m2, day: d2]) -> y1*365 + m1*(365/12) + d1 < y2*365 + m2*(365/12) + d2 end)
  end

  defp process_possible_date([]), do: :no_match
  defp process_possible_date([_]), do: :no_match
  defp process_possible_date([_, _, _, "", month, day]), do: process_legal_date(Date.utc_today().year, month, day)
  defp process_possible_date([_, _, _, year, month, day]), do: process_legal_date(year, month, day)
  defp process_possible_date([_, "", "", "", "", "", monthstr, day]), do: process_legal_date(Date.utc_today().year, Map.fetch!(@month_to_int, String.to_atom(monthstr)), day)
  defp process_possible_date([_, "", "", "", "", "", monthstr, day, _]), do: process_legal_date(Date.utc_today().year, Map.fetch!(@month_to_int, String.to_atom(monthstr)), day)
  defp process_possible_date([_, "", "", "", "", "", monthstr, day, _, year]), do: process_legal_date(year, Map.fetch!(@month_to_int, String.to_atom(monthstr)), day)

  defp process_legal_date(yearstr, monthstr, daystr) do
    {y, m, d} = {toint(yearstr), toint(monthstr), toint(daystr)}
    case Date.new(y, m, d) do
      {:ok, _} -> [year: y, month: m, day: d]
      _ -> :no_match
    end
  end

  @doc"""
  Parses an arbitrary string to find all potential valid timezones.
  Output is always in a list of keyword lists sorted by offset:
  [
    [name: "EDT", offset: -4],
    [name: "PDT", offset: -7],
    [name: "KST", offset: 9]
  ]

  Examples
    iex> DTParser.parse_timezone(nil)
    []

    iex> DTParser.parse_timezone("")
    []

    iex> DTParser.parse_timezone("PDT")
    [[name: "PDT", offset: -7]]

    iex> DTParser.parse_timezone("PDT.")
    [[name: "PDT", offset: -7]]

    iex> DTParser.parse_timezone("PDT  .")
    [[name: "PDT", offset: -7]]

    iex> DTParser.parse_timezone("PDT PDT")
    [[name: "PDT", offset: -7]]

    iex> DTParser.parse_timezone(".!.PDT >>!!PDT:")
    [[name: "PDT", offset: -7]]

    iex> DTParser.parse_timezone("     KST    ")
    [[name: "KST", offset: 9]]

    iex> DTParser.parse_timezone("     K ST    ")
    []

    iex> DTParser.parse_timezone("     K STPD T    ")
    []

    iex> DTParser.parse_timezone("     KSTPDT    ")
    []

    iex> DTParser.parse_timezone("PDT CDT EDT KST WET EET CET UTC")
    [[name: "PDT", offset: -7], [name: "CDT", offset: -5], [name: "EDT", offset: -4], [name: "UTC", offset: 0], [name: "WET", offset: 1], [name: "CET", offset: 2], [name: "EET", offset: 2], [name: "KST", offset: 9]]
  """
  @spec parse_timezone(String.t()) :: timezone_results
  def parse_timezone(nil), do: []
  def parse_timezone(""), do: []
  def parse_timezone(str) do
    Regex.scan(@timezone_regex, String.downcase(str))
      |> Enum.map(&(process_possible_timezone(&1)))
      |> Enum.filter(fn r -> r != :no_match end)
      |> Enum.uniq()
      |> Enum.sort(fn ([name: n1, offset: o1], [name: n2, offset: o2]) -> o1*10000000 + tz_to_compare(n1) < o2*10000000 + tz_to_compare(n2) end)
  end

  defp tz_to_compare(tz) when byte_size(tz) == 3, do: :binary.decode_unsigned(tz) - :binary.decode_unsigned("aaa") + 1
  defp tz_to_compare(tz) when byte_size(tz) == 4, do: :binary.decode_unsigned(tz) - :binary.decode_unsigned("aaaa") + 1

  defp process_possible_timezone([]), do: :no_match
  defp process_possible_timezone([_]), do: :no_match
  defp process_possible_timezone([_, tz]), do: process_legal_timezone(tz)

  defp process_legal_timezone(timezone) do
    with {:ok, offset} <- Map.fetch(@timezones_to_offset, String.to_atom(timezone)) do
      [name: String.upcase(timezone), offset: offset]
    else
      _ -> :no_match
    end
  end
end
