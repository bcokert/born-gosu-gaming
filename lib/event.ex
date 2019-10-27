defmodule Event do
  @enforce_keys [:name, :date, :creator]
  defstruct [:name, :date, :creator, :description, :link, participants: []]

  @type t :: %Event{
    name: String.t(),
    date: DateTime.t(),
    creator: Nostrum.Snowflake.t(),
    participants: [Nostrum.Snowflake.t()],
    link: String.t() | nil,
    description: String.t() | nil
  }

  require Logger
  alias Nostrum.Struct.User

  @api Application.get_env(:born_gosu_gaming, :discord_api)

  @reminder_add_emoji "⏰"

  def default_reminders() do
    [
      {7*24*60*60*1000, fn e -> remind_participants(e, "in 7 days") end},
      {3*24*60*60*1000, fn e -> remind_participants(e, "in 3 days") end},
      {1*24*60*60*1000, fn e -> remind_participants(e, "tomorrow") end},
      {3*60*60*1000, fn e -> remind_participants(e, "in 3 hours") end},
      {30*60*1000, fn e -> remind_participants(e, "30 minutes from now") end},
      {60*1000, fn e -> remind_participants(e, "in 1 minute!") end},
    ]
  end

  def run(command) do
    with {:ok, channel} <- Nostrum.Cache.ChannelCache.get(command.discord_msg.channel_id),
         guild <- Nostrum.Cache.GuildCache.get!(command.discord_msg.guild_id) do
      Logger.info "Attempting #{command.command}(#{Enum.join(command.args, ", ")}) from #{command.discord_msg.author.username}\##{command.discord_msg.author.discriminator} in #{channel.name}"
      if is_authorized(command.discord_msg.author.id, guild) do
        do_command(command.command, command.args, command.discord_msg)
      else
        @api.create_message(channel.id, "I'm sorry, but only members can use this.")
        Logger.info "#{command.command}(#{Enum.join(command.args, ", ")}) from #{command.discord_msg.author.username}\##{command.discord_msg.author.discriminator} in #{channel.name} was unauthorized"
      end
    end
  end

  defp remind_participants(event, date_str) do
    Enum.each(event.participants, fn participant -> 
      with {:ok, channel} <- @api.create_dm(participant) do
        @api.create_message(channel.id, "This is a reminder that you are registered for an upcoming event that starts #{date_str}\n#{Event.Formatter.full_summary(event)}")
      end
    end)
  end

  defp do_command("help", _, m), do: help(m.channel_id, m.author.id)
  defp do_command("adminhelp", _, m), do: adminhelp(m.channel_id, m.author.id)
  defp do_command("eventchannels", _, m), do: eventchannels(m.channel_id, m.guild_id)
  defp do_command("dates", _, m), do: dates(m.channel_id)
  defp do_command("soon", _, m), do: soon(m.channel_id, m.guild_id)
  defp do_command("mine", _, m), do: mine(m.channel_id, m.author.id, m.guild_id)
  defp do_command("add", [name | _], m), do: add(m.channel_id, m.author.id, m.guild_id, name, m.content)
  defp do_command("remove", [name | _], m), do: remove(m.channel_id, m.author.id, m.guild_id, name)
  defp do_command("tryout", [user1, user2 | _], m), do: tryout(m.channel_id, m.guild_id, user1, user2)
  defp do_command(name, args, m), do: unknown(m.channel_id, name, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, name, args, username, discriminator) do
    cmd = "#{name}(#{Enum.join(args, ", ")}) from #{username}\##{discriminator}"
    @api.create_message(channel_id, "Apologies, but I'm not sure what to do with this: #{cmd}")
  end

  defp help(channel_id, author_id) do
    @api.create_message(channel_id, "I'll dm you")
    with {:ok, channel} <- @api.create_dm(author_id) do
      @api.create_message(channel.id, String.trim("""
      Available commands:
      - help
          Shows this help text.
          eg: '!events help'

      - dates
          Shows some help specific to dates and date formats

      - soon
          Shows events coming in the next 7 days.
          This is the default when just using '!events' without a command.
          eg: '!events soon'
          eg: '!events'

      - mine
          Shows all events that you are managing
          eg: '!events mine'

      - add <name> <date>
          Creates an event with the given name and date. The name must have quotes around it.
          Each creator can only have 1 event with the same name
          eg: '!events add "BG Super Tourney" Aug 22 at 4:30 pm'
          eg: '!events add VTL3 2019-06-01 at 18:00'

      - remove <name>
          Deletes an event with the given name.
          Only the creator or admin can delete an event.
          eg: '!events remove "BG Super Tourney"'
      """))
    end
  end

  defp adminhelp(channel_id, author_id) do
    @api.create_message(channel_id, "I'll dm you")
    with {:ok, channel} <- @api.create_dm(author_id) do
      @api.create_message(channel.id, String.trim("""
      Available commands:
      - adminhelp
          Shows this help text.
          eg: '!events adminhelp'

      - eventchannels
          Shows the list of channels considered safe for teamleague information.
          This determines several permissions, such as hiding rosters
          in public channels.
      """))
    end
  end

  defp eventchannels(channel_id, guild_id) do
    with guild <- Nostrum.Cache.GuildCache.get!(guild_id),
         channels <- Authz.teamleague_channels(guild) do
      @api.create_message(channel_id, "These are the channels considered safe for sensitive teamleague information: #{Enum.join(channels, ", ")}")
    end
  end

  defp dates(channel_id) do
    @api.create_message(channel_id, """
    Consider these dates:
      `2019-07-01T16:30:00-07`
      `2019-07-01T16:30:00+03`

    The `-07` is the date offset from UTC. `-07` Might be PDT, `+03` might be EEST.

    Here's some common offsets
    ```
      Normal:                  Daylight Savings:
                    -NA-
      PDT:   -07               PST:  -08
      CDT:   -05               CST:  -06
      EDT:   -04               EST:  -05
                    -EU-
      UTC:   +00               BST:  +01
      WET:   +00               WEST: +01
      CET:   +01               CEST: +02
      EET:   +02               EEST: +03
                    -AS-
      China: +08
      Korea: +09
    ```

    Here's a list of all the possible offsets and their names, including daylight savings: https://www.timeanddate.com/time/zones/
    """)
  end

  defp soon(channel_id, _guild_id) do
    with events when events != [] <- Event.Persister.get_all(nil, nil, 60*60*24*7) do
      @api.create_message(channel_id, "There are #{length(events)} events in the next 7 days (click #{@reminder_add_emoji} for reminders):")
      events
        |> Enum.map(fn e -> {e, Event.Formatter.full_summary(e, length(events) > 3)} end)
        |> Enum.map(fn {e, msg} -> {e, @api.create_message(channel_id, msg)} end)
        |> Enum.filter(fn {_, resp} -> elem(resp, 0) == :ok end)
        |> Enum.map(fn {e, {:ok, %{id: mid}}} -> {e, mid, @api.create_reaction(channel_id, mid, @reminder_add_emoji)} end)
        |> Enum.map(fn {e, mid, _} -> add_reminder_interaction(channel_id, e, mid) end)
    else
      [] ->
        @api.create_message(channel_id, "Looks like there aren't any events in the next 7 days")
    end
  end

  defp add_reminder_interaction(channel_id, event, message_id) do
    reducer = fn (state, %{emoji: emoji, sender: sender_id, is_add: is_add}) ->
      {:ok, event = %Event{}} = Event.Persister.get(event.name)
      if emoji == @reminder_add_emoji do
        user = Nostrum.Cache.UserCache.get!(sender_id)
        if is_add do
          register(channel_id, event, user)
        else
          unregister(channel_id, event, user)
        end
      end
      state
    end

    Interaction.create(%Interaction{
      name: event.name,
      mid: message_id,
      mstate: {},
      reducer: reducer,
      on_remove: nil,
    })
  end

  defp mine(channel_id, author_id, _guild_id) do
    with events when events != [] <- Event.Persister.get_all(author_id, nil, nil) do
      events
        |> Enum.map(fn e -> Event.Formatter.full_summary(e, length(events) > 3) end)
        |> (&(["All the events you're managing:"] ++ &1)).()
        |> Enum.join("\n\n")
        |> (fn msg -> @api.create_message(channel_id, msg) end).()
    else
      [] ->
        @api.create_message(channel_id, "Looks like you haven't created any events")
    end
  end

  defp add(channel_id, author_id, _guild_id, name, raw_msg) do
    times_found = DTParser.parse_time(raw_msg)
    dates_found = DTParser.parse_date(raw_msg)
    timezones_found = DTParser.parse_timezone(raw_msg)

    possibles = permute_possible_dates(times_found, dates_found, timezones_found)

    case length(possibles) do
      0 ->
        @api.create_message(channel_id, Enum.join([
          missing_permutation_msg(times_found, dates_found, timezones_found),
          "Here's some options that match what you gave me, but add what was missing:",
          permute_with_missing(times_found, dates_found, timezones_found)
            |> Enum.map(fn m -> "!events add \"#{name}\" " <> m end)
            |> Enum.join("\n")
        ], "\n"))
      1 ->
        with events <- Event.Persister.get_all(author_id, nil, nil),
          false <- has_duplicate_event?(events, name),
          {[date | _], [time | _], [tz | _]} <- {dates_found, times_found, timezones_found},
          _ <- IO.inspect("#{date[:year]}-#{pad_2digit(date[:month])}-#{pad_2digit(date[:day])}T#{pad_2digit(time[:hour])}:#{pad_2digit(time[:min])}:00#{pad_2digit(tz[:offset])}"),
          {:ok, date, _} <- DateTime.from_iso8601("#{date[:year]}-#{pad_2digit(date[:month])}-#{pad_2digit(date[:day])}T#{pad_2digit(time[:hour])}:#{pad_2digit(time[:min])}:00#{pad_2digit(tz[:offset])}"),
          {:ok, now} <- DateTime.now("Etc/UTC") do
          if DateTime.diff(date, now) > 0 do
            event = Event.Persister.create(%Event{name: name, date: date, creator: author_id, link: nil})
            msg = Enum.join([
              "Excellent! I've created that event for you.",
              Event.Formatter.full_summary(event),
              "If you made a mistake, type `!events remove #{name}` and try again"
            ], "\n")
            @api.create_message(channel_id, msg)
          else
            pretty = Event.Formatter.time_ago!(date)
            @api.create_message(channel_id, "New events must be in the future. Yours was #{pretty} in the past")
          end
        else
          true ->
            @api.create_message(channel_id, "Looks like you already have an event called '#{name}'")
          e ->
            IO.inspect(e, label: "Error when creating event")
            @api.create_message(channel_id, "Something went very, very wrong. Please tell PhysicsNoob")
        end
      _ ->
        @api.create_message(channel_id, Enum.join([
          "It looks like you could have meant multiple dates. Here's the ones I understood, try one of them?",
          possibles
            |> Enum.map(fn m -> "!events add \"#{name}\" " <> m end)
            |> Enum.join("\n")
        ], "\n"))
    end
  end

  defp permute_possible_dates(times, dates, zones) do
    for tz <- zones,
        date <- dates,
        time <- times do
      {:ok, datetime, _} = DateTime.from_iso8601("#{date[:year]}-#{pad_2digit(date[:month])}-#{pad_2digit(date[:day])}T#{pad_2digit(time[:hour])}:#{pad_2digit(time[:min])}:00-00")
      Event.Formatter.day_and_time_utc(datetime, tz)
    end
  end

  defp pad_2digit(amnt) when amnt < 0 and amnt > -9, do: "-0#{amnt*-1}"
  defp pad_2digit(amnt) when amnt < 10, do: "0#{amnt}"
  defp pad_2digit(amnt), do: "#{amnt}"

  defp missing_permutation_msg([], [], []), do: "I couldn't find a time, date, or timezone in that."
  defp missing_permutation_msg([], [], [_ | _]), do: "I couldn't find a time or date in that, but I found a timezone."
  defp missing_permutation_msg([], [_ | _], []), do: "I couldn't find a time or timezone in that, but I found a date."
  defp missing_permutation_msg([_ | _], [], []), do: "I couldn't find a date or timezone in that, but I found a time."
  defp missing_permutation_msg([_ | _], [_ | _], []), do: "I couldn't find a timezone in that, but I found a time and date."
  defp missing_permutation_msg([], [_ | _], [_ | _]), do: "I couldn't find a time in that, but I found a date and timezone."
  defp missing_permutation_msg([_ | _], [], [_ | _]), do: "I couldn't find a date in that, but I found a time and timezone."

  defp permute_with_missing(times, dates, zones) do
    permute_possible_dates(times_or_default(times), dates_or_default(dates), zones_or_default(zones))
  end

  defp times_or_default([]), do: [[hour: 4, min: 30]]
  defp times_or_default(time), do: time

  defp dates_or_default([]), do: [[year: 2019, month: 7, day: 21]]
  defp dates_or_default(date), do: date

  defp zones_or_default([]), do: [[name: "EDT", offset: -4]]
  defp zones_or_default(zone), do: zone

  defp has_duplicate_event?(events, name) do
    length(Enum.filter(events, fn e -> e.name == name end)) > 0
  end

  defp remove(channel_id, author_id, guild_id, name) do
    with {:ok, event = %Event{name: name, creator: creator_id, date: date, link: link}} <- Event.Persister.get(name),
         guild <- Nostrum.Cache.GuildCache.get!(guild_id),
         true <- permission_remove(author_id, creator_id, guild),
         :ok <- Event.Persister.remove(event)
    do
      msg = "Ok, I'll remove \"#{name}\" that was scheduled for #{date}."
        |> add_line_if(link != nil, "You might have to cleanup <#{link}> as well.")
      @api.create_message(channel_id, msg)
    else
      {:ok, :none} ->
        @api.create_message(channel_id, "It doesn't look like that event exists. Are you sure you spelled it right?")
      {false, reason} ->
        @api.create_message(channel_id, reason)
    end
  end

  defp add_line_if(lines, _, ""), do: lines
  defp add_line_if(lines, true, str), do: lines <> "\n" <> str
  defp add_line_if(lines, false, _), do: lines

  defp permission_remove(author_id, creator_id, guild) do
    %User{username: creator_name} = Nostrum.Cache.UserCache.get!(creator_id)
    if creator_id == author_id or Authz.is_admin?(author_id, guild) do
      true
    else
      {false, "Only the creator (#{creator_name}) or an admin can remove events"}
    end
  end

  defp is_authorized(author_id, guild) do
    is_test_mode = Application.get_env(:born_gosu_gaming, :is_test_mode)
    test_mode_role = Application.get_env(:born_gosu_gaming, :test_mode_role)
    creator_role = Application.get_env(:born_gosu_gaming, :creator_role)

    is_creator = DiscordQuery.user_has_role?(author_id, creator_role, guild)
    is_tester = DiscordQuery.user_has_role?(author_id, test_mode_role, guild)
    is_admin = DiscordQuery.user_has_role?(author_id, "Admins", guild)
    if is_test_mode do
      is_tester or is_admin
    else
      is_creator or is_admin
    end
  end

  defp register(channel_id, event, user) do
    if !(user.id in event.participants) do
      with :ok <- Event.Persister.register(event, [user.id] ++ event.participants) do
        @api.create_message(channel_id, "#{user} alright I'll remind you about #{event.name}")
      end
    else
      @api.create_message(channel_id, "#{user} you're already getting reminders for this. Click again to remove them.")
    end
  end

  defp unregister(channel_id, event, user) do
    if user.id in event.participants do
      with :ok <- Event.Persister.register(event, Enum.filter(event.participants, fn p -> p != user.id end)) do
        @api.create_message(channel_id, "#{user} alright I'll no longer remind you about #{event.name}")
      end
    else
      @api.create_message(channel_id, "#{user} you weren't getting reminders for this. Click again to add them.")
    end
  end

  def tryout(channel_id, guild_id, raw_mentor, raw_mentee) when is_binary(raw_mentor) and is_binary(raw_mentee) do
    guild = Nostrum.Cache.GuildCache.get!(guild_id)
    mentors = guild
      |> DiscordQuery.mentors()
      |> DiscordQuery.matching_users(raw_mentor)
    non_members = guild
      |> DiscordQuery.non_members()
      |> DiscordQuery.matching_users(raw_mentee)
    output = (for m <- mentors, n <- non_members, do: {m, n})
      |> options_for_pairings()
      |> Enum.join("\n")

    @api.create_message(channel_id, output)
  end

  defp options_for_pairings([]), do: []
  defp options_for_pairings([{%User{username: n1, discriminator: d1}, %User{username: n2, discriminator: d2}} | rest]) do
    ["Enter `+#{length(rest)+1}` to run '+tryout @#{n1}##{d1} @#{n2}##{d2}'" | options_for_pairings(rest)]
  end
end
