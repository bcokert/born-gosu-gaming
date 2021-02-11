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

  defp num_emojis() do
    %{
      "0" => "0️⃣",
      "1" => "1️⃣",
      "2" => "2️⃣",
      "3" => "3️⃣",
      "4" => "4️⃣",
      "5" => "5️⃣",
      "6" => "6️⃣",
      "7" => "7️⃣",
      "8" => "8️⃣",
      "9" => "9️⃣",
      "10" => "🔟",
      "11" => "↖️",
      "12" => "⬅️",
      "13" => "↙️",
      "14" => "⬇️",
      "15" => "↘️",
      "16" => "➡️",
      "17" => "↗️",
      "18" => "⬆️",
      "19" => "🅿️",
      "20" => "🅾️",
      "21" => "ℹ️",
      "22" => "🅱️",
      "23" => "🅰️",
      "24" => "#️⃣",
    }
  end

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
      if is_authorized?(command.discord_msg.author.id, guild, command.command) do
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
        @api.create_message(channel.id, "This is a reminder for an upcoming event that starts #{date_str}\n#{Event.Formatter.full_summary(event)}")
      end
    end)
  end

  defp do_command("help", _, m), do: help(m.channel_id, m.author.id)
  defp do_command("adminhelp", _, m), do: adminhelp(m.channel_id, m.author.id)
  defp do_command("setdaylightsavings", [region, enabled? | _], m), do: setdaylightsavings(m.channel_id, m.guild_id, m.author.id, region, enabled?)
  defp do_command("daylightsavings", _, m), do: daylightsavings(m.channel_id, m.guild_id, m.author.id)
  defp do_command("dates", _, m), do: dates(m.channel_id)
  defp do_command("soon", _, m), do: soon(m.channel_id, m.guild_id)
  defp do_command("mine", _, m), do: mine(m.channel_id, m.author.id, m.guild_id)
  defp do_command("add", [name | _], m), do: add(m.channel_id, m.author.id, m.guild_id, name, m.content)
  defp do_command("remove", [name | _], m), do: remove(m.channel_id, m.author.id, m.guild_id, name)
  defp do_command("tryout", [user1, user2 | _], m), do: tryout(m.channel_id, m.guild_id, m.author.id, user1, user2)
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

      - daylightsavings
          Displays what the settings for daylight savings are
          eg: '!events daylightsavings'
      
      - setdaylightsavings <eu|na> <yes|no>
          Toggles the default output formats between Daylight Savings and Summer
          times.
          eg: '!events setdaylightsavings na yes'
          eg: '!events setdaylightsavings eu no'
      """))
    end
  end

  defp daylightsavings(channel_id, guild_id, author_id) do
    with guild <- Nostrum.Cache.GuildCache.get!(guild_id) do
      if Authz.is_admin?(author_id, guild) do
        settings = Settings.get_output_timezones()
        if Map.has_key?(settings, :EDT), do: @api.create_message(channel_id, "For NA, daylight savings is active")
        if Map.has_key?(settings, :EST), do: @api.create_message(channel_id, "For NA, daylight savings is not active")
        if Map.has_key?(settings, :CEST), do: @api.create_message(channel_id, "For EU, daylight savings is active")
        if Map.has_key?(settings, :CET), do: @api.create_message(channel_id, "For EU, daylight savings is not active")
      else
        @api.create_message(channel_id, "Only admins can use this")
      end
    end
  end

  defp setdaylightsavings(channel_id, guild_id, author_id, region, enabled?) do
    with guild <- Nostrum.Cache.GuildCache.get!(guild_id) do
      if Authz.is_admin?(author_id, guild) do
        case {region, enabled?} do
          {"eu", "yes"} ->
            Settings.set_daylight_savings(true, :eu)
            @api.create_message(channel_id, "Alright I've set output to use daylight savings for europe")
          {"eu", "no"} ->
            Settings.set_daylight_savings(false, :eu)
            @api.create_message(channel_id, "Alright I've set output to not use daylight savings for europe")
          {"na", "yes"} ->
            Settings.set_daylight_savings(true, :na)
            @api.create_message(channel_id, "Alright I've set output to use daylight savings for north america")
          {"na", "no"} ->
            Settings.set_daylight_savings(false, :na)
            @api.create_message(channel_id, "Alright I've set output to not use daylight savings for north america")
          _ ->
            @api.create_message(channel_id, "Invalid region or state. Try `!events setdaylightsavings eu yes` or `!events setdaylightsavings na no`")
        end
      else
        @api.create_message(channel_id, "Only admins can change the output timezones")
      end
    end 
  end

  defp dates(channel_id) do
    @api.create_message(channel_id, """
    These are the timezones (and their offsets) you can use:
    ```
      pdt: -7,  # pacific daylight
      pst: -8,  # pacific standard
      mdt: -6,  # mountain daylight
      mst: -7,  # mountain standard
      cdt: -5,  # central america daylight
      cst: -6,  # central standard
      edt: -4,  # eastern america daylight
      est: -5,  # eastern standard
      utc: 0,   # standard
      gmt: 0,   # greenwich
      wet: 0,   # western european
      west: 1,  # western european summer
      eet: 2,   # eastern europe
      eest: 3,  # eastern europe summer
      cet: 1,   # central europe
      cest: 2,  # central europse summer
      bst: 1,   # british summer
      china: 8, # china, aka CST
      kst: 9    # korea
    ```
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
          remind(channel_id, event, user)
        else
          unremind(channel_id, event, user)
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
          date_str = "#{date[:year]}-#{pad_2digit(date[:month])}-#{pad_2digit(date[:day])}T#{pad_2digit(time[:hour])}:#{pad_2digit(time[:min])}:00#{pad_2digit_tz(tz[:offset])}",
          _ <- Logger.info("Creating event from date string: #{date_str}"),
          {:ok, date, _} <- DateTime.from_iso8601(date_str),
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
          {:error, :invalid_format} ->
            @api.create_message(channel_id, "It looks like there's something wrong with the date format")
          e ->
            Logger.error("Error when creating event: #{inspect(e)}")
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

  defp pad_2digit(amnt) when amnt < 10, do: "0#{amnt}"
  defp pad_2digit(amnt), do: "#{amnt}"

  defp pad_2digit_tz(amnt) when amnt <= -10, do: "#{amnt}"
  defp pad_2digit_tz(amnt) when amnt < 0, do: "-0#{amnt*-1}"
  defp pad_2digit_tz(amnt) when amnt < 10, do: "+0#{amnt}"
  defp pad_2digit_tz(amnt) when amnt >= 10, do: "+#{amnt}"

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

  defp is_authorized?(author_id, guild, command) do
    member = @api.get_guild_member!(guild.id, author_id)
    is_admin = DiscordQuery.member_has_role?(member, "Admins", guild)
    is_admin or Authz.authorized_for_command?(member, guild, command)
  end

  defp remind(channel_id, event, user) do
    if !(user.id in event.participants) do
      with :ok <- Event.Persister.set_reminders(event, [user.id] ++ event.participants) do
        @api.create_message(channel_id, "#{user} alright I'll remind you about #{event.name}")
      end
    else
      @api.create_message(channel_id, "#{user} you're already getting reminders for this. Click again to remove them.")
    end
  end

  defp unremind(channel_id, event, user) do
    if user.id in event.participants do
      with :ok <- Event.Persister.set_reminders(event, Enum.filter(event.participants, fn p -> p != user.id end)) do
        @api.create_message(channel_id, "#{user} alright I'll no longer remind you about #{event.name}")
      end
    else
      @api.create_message(channel_id, "#{user} you weren't getting reminders for this. Click again to add them.")
    end
  end

  def tryout(channel_id, guild_id, author_id, raw_mentee, raw_mentor) when is_binary(raw_mentor) and is_binary(raw_mentee) do
    guild = Nostrum.Cache.GuildCache.get!(guild_id)
    mentors = guild
      |> DiscordQuery.mentors()
      |> DiscordQuery.matching_users(raw_mentor)
    non_members = guild
      |> DiscordQuery.non_members()
      |> DiscordQuery.matching_users(raw_mentee)
    author = Nostrum.Cache.UserCache.get!(author_id)

    tryout_response(channel_id, author, mentors, non_members, raw_mentor, raw_mentee)
  end

  defp tryout_response(channel_id, _, [], [], raw_mentor, raw_mentee) do
    @api.create_message(channel_id, "No mentors matching '#{raw_mentor}' found, and no non-members matching '#{raw_mentee}' found")
  end
  defp tryout_response(channel_id, _, [], mentees, raw_mentor, _) do
    @api.create_message(channel_id, "No mentors matching '#{raw_mentor}' found, but found matching mentees: #{users_to_csv(mentees)}")
  end
  defp tryout_response(channel_id, _, mentors, [], _, raw_mentee) do
    @api.create_message(channel_id, "No non members matching '#{raw_mentee}' found, but found matching mentors: #{users_to_csv(mentors)}")
  end
  defp tryout_response(channel_id, author, mentors, mentees, raw_mentor, raw_mentee) do
    matches = (for m <- mentors, n <- mentees, do: {m, n})
      |> Enum.with_index()
      |> Enum.map(fn {{m, n}, i} -> {m, n, i, num_emojis()["#{i}"], "+tryout #{n} #{m}"} end)

    message = matches
      |> Enum.map(fn {m, n, _, emoji, _} -> "React with #{emoji} to run `#{"+tryout #{n.username} #{m.username}"}`" end)
      |> Enum.join("\n")

    with {:ok, %{id: mid}} <- @api.create_message(channel_id, message) do
      reducer = fn (state, %{emoji: emoji, sender: sender_id, is_add: is_add}) ->
        user = Nostrum.Cache.UserCache.get!(sender_id)
        if (user.id != author.id) do
          @api.create_message(channel_id, "Sorry #{user}, only #{author} can do that for this tryout search")
        else
          if is_add do
            case Enum.find(matches, fn {_, _, _, e, _} -> emoji == e end) do
              {_, _, _, _, cmd} ->
                @api.create_message(channel_id, "#{cmd}")
              _ ->
                @api.create_message(channel_id, "Sorry #{user}, but #{emoji} is not a valid choice")
            end
          end
        end
        state
      end

      Interaction.create(%Interaction{
        name: "!tryout #{raw_mentee} #{raw_mentor}",
        mid: mid,
        mstate: {},
        reducer: reducer,
        on_remove: nil,
      })
    else
      error ->
        logid = DateTime.to_unix(DateTime.utc_now())
        Logger.info "[#{logid}] Error while running tryouts: #{error}"
        @api.create_message(channel_id, "Something went wrong. Please tell Physics and give him this: #{logid}")
    end
  end

  defp users_to_csv(users) do
    users
      |> Enum.map(fn m -> m.username end)
      |> Enum.join(", ")
  end
end
