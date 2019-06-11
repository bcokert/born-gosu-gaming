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

  def ms_until!(%Event{date: date}) do
    {:ok, now} = DateTime.now("Etc/UTC")
    DateTime.diff(date, now, :millisecond)
  end

  def default_reminders() do
    [
      {7*24*60*60*1000, fn e -> remind_participants(e, "in 7 days") end},
      {3*24*60*60*1000, fn e -> remind_participants(e, "in 3 days") end},
      {1*24*60*60*1000, fn e -> remind_participants(e, "tomorrow") end},
      {3*60*60*1000, fn e -> remind_participants(e, "in 3 hours") end},
      {20*60*1000, fn e -> remind_participants(e, "20 minutes from now") end},
    ]
  end

  def run(command) do
    with {:ok, channel} <- Nostrum.Cache.ChannelCache.get(command.discord_msg.channel_id) do
      Logger.info "Running #{command.command}(#{Enum.join(command.args, ", ")}) from #{command.discord_msg.author.username}\##{command.discord_msg.author.discriminator} in #{channel.name}"
    end
    do_command(command.command, command.args, command.discord_msg)
  end

  defp remind_participants(event, date_str) do
    Enum.each(event.participants, fn participant -> 
      with {:ok, channel} <- @api.create_dm(participant) do
        @api.create_message(channel.id, "This is a reminder that you are registered for an upcoming event that starts #{date_str}\n#{summarize_event(event)}")
      end
    end)
  end

  defp do_command("help", _, m), do: help(m.channel_id, m.author.id)
  defp do_command("soon", _, m), do: soon(m.channel_id)
  defp do_command("me", _, m), do: me(m.channel_id, m.author.id)
  defp do_command("mine", _, m), do: mine(m.channel_id, m.author.id)
  defp do_command("add", [name, date, link | _], m), do: add(m.channel_id, m.author.id, name, date, link)
  defp do_command("add", [name, date | _], m), do: add(m.channel_id, m.author.id, name, date, nil)
  defp do_command("remove", [name | _], m), do: remove(m.channel_id, m.author.id, m.guild_id, name)
  defp do_command("register", [name | _], m), do: register(m.channel_id, m.author.id, name, m.mentions)
  defp do_command("unregister", [name | _], m), do: unregister(m.channel_id, name, m.mentions)
  defp do_command("tryout", [user1, user2 | _], m), do: tryout(m.channel_id, m.guild_id, user1, user2)
  defp do_command(name, args, m), do: unknown(m.channel_id, name, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, name, args, username, discriminator) do
    cmd = "#{name}(#{Enum.join(args, ", ")}) from #{username}\##{discriminator}"
    @api.create_message(channel_id, "Unknown command or args: #{cmd}")
  end

  defp help(channel_id, author_id) do
    @api.create_message(channel_id, "I'll dm you")
    with {:ok, channel} <- @api.create_dm(author_id) do
      @api.create_message(channel.id, String.trim("""
      Available commands:
      - help
          Shows this help text.
          eg: '!events help'

      - soon
          Shows events coming in the next 7 days.
          This is the default when just using '!events' without a command.
          eg: '!events soon'
          eg: '!events'

      - me
          Shows all events that you are registered for
          eg: '!events me'
      
      - mine
          Shows all events that you are managing
          eg: '!events mine'

      - add <name> <date> <optional_link>
          Creates an event with the given name and date and link.
          Each creator can only have 1 event with the same name
          eg: '!events add "BG Super Tourney" 2019-08-22T17:00:00+00' http://challonge.com/test
          eg: '!events add VTL3 2021-08-22T17:00:00-07'

      - remove <name>
          Deletes an event with the given name.
          Only the creator or admin can delete an event.
          eg: '!events remove "BG Super Tourney"'

      - register <name> <@discordUser1> <@discordUser2> <...>
          Registers the given discord users to the given event.
          Registering a user will make them receive event reminders.
          Use discords autocomplete/user selector to ensure the name is right.
          eg: '!events register "BG Super Tourney" @PhysicsNoob#2664 @AsheN🌯#0002'

      - unregister <name> <@discordUser1> <@discordUser2> <...>
          Unregisters the given discord users from the given event.
          Use discords autocomplete/user selector to ensure the name is right.
          eg: '!events unregister "BG Super Tourney" @PhysicsNoob#2664 @AsheN🌯#0002'
      """))
    end
  end

  defp soon(channel_id) do
    with events when events != [] <- Event.Persister.get_all(nil, nil, 60*60*24*7) do
      events
        |> Enum.map(fn e -> summarize_event(e) end)
        |> (&(["Here's what's coming in the next 7 days:"] ++ &1)).()
        |> Enum.join("\n")
        |> (fn msg -> @api.create_message(channel_id, msg) end).()
    else
      [] ->
        @api.create_message(channel_id, "Looks like there aren't any events in the next 7 days")
    end
  end

  defp summarize_event(%Event{name: name, date: date, creator: creator, participants: participant_ids, link: link}) do
    %User{username: creator_name} = Nostrum.Cache.UserCache.get!(creator)
    participant_names = participant_ids
      |> Enum.map(fn p -> Nostrum.Cache.UserCache.get!(p) end)
      |> Enum.map(fn u -> u.username end)

    [
      "__**#{name}**__ by **#{creator_name}** _on #{DateTime.to_date(date)} at #{date.hour}:#{date.minute} (#{date.time_zone})_",
      "#{nil_to_string(link)}",
      "Players (#{length(participant_names)}): #{Enum.join(participant_names, ", ")}\n"
    ]
      |> Enum.filter(fn s -> String.length(s) > 0 end)
      |> Enum.join("\n")
  end

  defp nil_to_string(nil), do: ""
  defp nil_to_string(str), do: str

  defp me(channel_id, author_id) do
    with events when events != [] <- Event.Persister.get_all(nil, author_id, nil) do
      events
        |> Enum.map(fn e -> summarize_event(e) end)
        |> (&(["All the events you've registered for:"] ++ &1)).()
        |> Enum.join("\n")
        |> (fn msg -> @api.create_message(channel_id, msg) end).()
    else
      [] ->
        @api.create_message(channel_id, "Looks like you're not registered for any events")
    end
  end

  defp mine(channel_id, author_id) do
    with events when events != [] <- Event.Persister.get_all(author_id, nil, nil) do
      events
        |> Enum.map(fn e -> summarize_event(e) end)
        |> (&(["All the events you're managing:"] ++ &1)).()
        |> Enum.join("\n")
        |> (fn msg -> @api.create_message(channel_id, msg) end).()
    else
      [] ->
        @api.create_message(channel_id, "Looks like you haven't created any events")
    end
  end

  defp add(channel_id, author_id, name, date_str, link) do
    with events <- Event.Persister.get_all(author_id, nil, nil),
         false <- has_duplicate_event?(events, name),
         {:ok, date, _} <- DateTime.from_iso8601(date_str),
         {:ok, now} <- DateTime.now("Etc/UTC") do
      if DateTime.diff(date, now) > 0 do
        event = Event.Persister.create(%Event{name: name, date: date, creator: author_id, link: link})
        @api.create_message(channel_id, "Excellent! I've created that event for you.\n" <> summarize_event(event))
      else
        @api.create_message(channel_id, "New events must be in the future")
      end
    else
      true ->
        @api.create_message(channel_id, "Looks like you already have an event called '#{name}'")
      _ ->
        @api.create_message(channel_id, "Looks like that date is incorrect: '#{date_str}'. Compare it to '2021-01-19T16:30:00-08'")
    end
  end

  defp has_duplicate_event?(events, name) do
    length(Enum.filter(events, fn e -> e.name == name end)) > 0
  end

  defp remove(channel_id, author_id, guild_id, name) do
    with {:ok, event = %Event{name: name, creator: creator_id, date: date, participants: participant_ids, link: link}} <- Event.Persister.get(name),
         guild <- Nostrum.Cache.GuildCache.get!(guild_id),
         true <- permission_remove(author_id, creator_id, guild),
         participants <- Enum.map(participant_ids, fn p -> Nostrum.Cache.UserCache.get!(p) end),
         :ok <- Event.Persister.remove(event)
    do
      msg = "Ok, I'll remove \"#{name}\" that was scheduled for #{date}."
        |> add_line_if(length(participants) > 0, "FYI #{Enum.join(participants, ", ")}")
        |> add_line_if(link != nil, "You might have to cleanup #{link} as well.")
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
    if creator_id == author_id or DiscordQuery.user_has_role?(author_id, "Admins", guild) do
      true
    else
      {false, "Only the creator (#{creator_name}) or an admin can remove events"}
    end
  end

  defp register(channel_id, author_id, name, users) do
    with {:ok, event} <- Event.Persister.get(name),
         {unregistered, registered} <- find_already_registered(users, event),
         user_ids <- Enum.uniq(Enum.map(unregistered, fn u -> u.id end) ++ event.participants),
         :ok <- Event.Persister.register(event, user_ids),
         creator <- Nostrum.Cache.UserCache.get!(event.creator),
         %User{id: creator_id} = creator do
      if length(registered) > 0 do
        @api.create_message(channel_id, "#{Enum.join(Enum.map(registered, fn u -> u.username end), ", ")} already registered")
      end
      if length(unregistered) > 0 do
        @api.create_message(channel_id, "Alright I've registered #{Enum.join(Enum.map(unregistered, fn u -> u.username end), ", ")} for \"#{name}\"")
        if author_id == creator_id do
          @api.create_message(channel_id, "You take care of telling them about the event and keeping up with them.")
          @api.create_message(channel_id, "I'll make sure they get reminders about when the event is happening.")
        else
          @api.create_message(channel_id, "Pinging #{creator} so they can follow up.")
          @api.create_message(channel_id, "I'll make sure the participants get reminders about when the event is happening.")
        end
      end
    else
      {:error, :event_not_exists} ->
        @api.create_message(channel_id, "It doesn't look like that event exists. Are you sure you spelled it right?")
    end
  end

  defp find_already_registered(users, event) do
    registered = users
      |> Enum.filter(fn u -> u.id in event.participants end)
    unregistered = users
      |> Enum.filter(fn u -> u.id not in event.participants end)
    {unregistered, registered}
  end

  defp unregister(channel_id, name, users) do
    with {:ok, event} <- Event.Persister.get(name),
         {unregistered, registered} <- find_already_registered(users, event),
         registered_ids <- Enum.map(registered, fn u -> u.id end),
         user_ids <- Enum.filter(event.participants, fn p -> p not in registered_ids end),
         :ok <- Event.Persister.register(event, user_ids) do
      if length(unregistered) > 0 do
        @api.create_message(channel_id, "#{Enum.join(Enum.map(unregistered, fn u -> u.username end), ", ")} not registered for this event.")
      end
      if length(registered) > 0 do
        @api.create_message(channel_id, "Alright I've unregistered #{Enum.join(Enum.map(registered, fn u -> u.username end), ", ")} from \"#{name}\"")
      else
        @api.create_message(channel_id, "Looks like there was noone registered that I needed to unregister.")
      end
    else
      {:error, :event_not_exists} ->
        @api.create_message(channel_id, "It doesn't look like that event exists. Are you sure you spelled it right?")
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
