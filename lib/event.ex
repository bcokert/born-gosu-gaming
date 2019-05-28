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
  alias Nostrum.Struct.Message

  @api Application.get_env(:born_gosu_gaming, :discord_api)

  def run(command) do
    with {:ok, channel} <- Nostrum.Cache.ChannelCache.get(command.discord_msg.channel_id) do
      Logger.info "Running #{command.command}(#{Enum.join(command.args, ", ")}) from #{command.discord_msg.author.username}\##{command.discord_msg.author.discriminator} in #{channel.name}"
    end
    do_command(command.command, command.args, command.discord_msg)
  end

  defp do_command("help", _, m), do: help(m)
  defp do_command("soon", _, m), do: soon(m)
  defp do_command("me", _, m), do: me(m)
  defp do_command("add", [name, date | _], m), do: add(m, name, date)
  defp do_command("remove", [name | _], m), do: remove(m, name)
  defp do_command("register", [name | _], m), do: register(m.channel_id, m.author.id, name, m.mentions)
  defp do_command("unregister", [name | users], m), do: unregister(m, name, users)
  defp do_command("tryout", [user1, user2 | _], m), do: tryout(m, user1, user2)
  defp do_command(name, args, m), do: unknown(m.channel_id, name, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, name, args, username, discriminator) do
    cmd = "#{name}(#{Enum.join(args, ", ")}) from #{username}\##{discriminator}"
    @api.create_message(channel_id, "Unknown command or args: #{cmd}")
  end

  defp help(discord_msg) do
    @api.create_message(discord_msg.channel_id, "I'll dm you")

    case @api.create_dm(discord_msg.author.id) do
      {:ok, channel} ->
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

        - add <name> <date>
            Creates an event with the given name and date.
            Will ask for more information.
            Events will be automatically added to the calendar.
            Only users with the ''Event Creator' role can create events.
            eg: '!events "BG Super Tourney" "2019-08-22 17:00:00 PDT"'

        - remove <name>
            Deletes an event with the given name.
            Only the creator or admin can delete an event.
            eg: '!events delete "BG Super Tourney"'

        - register <name> <@discordUser1> <@discordUser2> <...>
            Registers the given discord users to the given event.
            Only creators and admins can do this.
            Registering a user will make them receive event reminders.
            Use discords autocomplete/user selector to ensure the name is right.
            eg: '!events register "BG Super Tourney" @PhysicsNoob#2664 @AsheN🌯#0002'

        - unregister <name> <@discordUser1> <@discordUser2> <...>
            Unregisters the given discord users to the given event.
            Creators and admins, can do this, and users can also unregister themselves.
            Registering a user will make them receive event reminders.
            Use discords autocomplete/user selector to ensure the name is right.
            eg: '!events register "BG Super Tourney" @PhysicsNoob#2664 @AsheN🌯#0002'
        """))
      {:error, reason} ->
        Logger.warn "Failed to create dm in help command: #{reason}"
    end
  end

  defp soon(discord_msg) do
    case Event.Persister.get_all() do
      :error ->
        @api.create_message(discord_msg.channel_id, "Oops! Something went wrong fetching upcoming events. Please tell PhysicsNoob")
      [] ->
        @api.create_message(discord_msg.channel_id, "No Events are Upcoming")
      events ->
        event_lines = Enum.map(events, fn e -> soon_format_event(e) end)
        @api.create_message(discord_msg.channel_id, """
        Upcoming Events:
          #{Enum.join(event_lines, "\n  ")}
        """)
    end
  end

  defp soon_format_event(event) do
    creator = case Nostrum.Cache.UserCache.get(event.creator) do
      {:ok, %Nostrum.Struct.User{username: name, discriminator: disc}} ->
        name <> "#" <> disc
      {:error, reason} ->
        Logger.warn("Failed to get creator from cache in 'soon': #{reason}")
        "@#{event.creator}"
    end

    participants = Enum.map(event.participants, fn p ->
      case Nostrum.Cache.UserCache.get(p) do
        {:ok, %Nostrum.Struct.User{username: name}} ->
          name
        {:error, reason} ->
          Logger.warn("Failed to get participant from cache in 'soon': #{reason}")
          "@#{p}"
      end
    end)

    description = case event.description do
      nil ->
        ""
      _ ->
        "\n`#{event.description}`"
    end

    link = case event.link do
      nil ->
        ""
      _ ->
        "\n#{event.link}"
    end

    """
    #{event.name}
        By #{creator}
        #{DateTime.to_date(event.date)} at #{event.date.hour}:#{event.date.minute} (#{event.date.time_zone})#{link}#{description}
        Participants (#{length(participants)}): #{Enum.join(participants, ", ")}
    """
  end

  defp me(discord_msg) do
    Logger.info "Running unimplemented me command"
    @api.create_message(discord_msg.channel_id, "WIP")
  end

  defp add(discord_msg, name, date_str) do
    creator = Nostrum.Cache.UserCache.get!(discord_msg.author.id)
    with {:ok, date, _} <- DateTime.from_iso8601(date_str) do
      event = Event.Persister.create(%Event{name: name, date: date, creator: discord_msg.author.id})
      @api.create_message(discord_msg.channel_id, """
        Event Created!
          "#{event.name}" by #{creator} on #{DateTime.to_date(event.date)} at #{event.date.hour}:#{event.date.minute} (#{event.date.time_zone})
        """)
    else
      _ ->
        @api.create_message(discord_msg.channel_id, "Illegal input date: #{date_str}. Compare it to '2021-01-19T16:30:00-08'")
    end
  end

  defp remove(%Message{author: %User{id: author_id}, channel_id: channel_id, guild_id: guild_id}, name) do
    with {:ok, %Event{name: name, creator: creator_id, date: date, participants: participants, link: link}} <- Event.Persister.get(name),
         guild <- Nostrum.Cache.GuildCache.get!(guild_id),
         true <- permission_remove(author_id, creator_id, guild),
         :ok <- Event.Persister.remove(name)
    do
      @api.create_message(channel_id, "Ok, I'll remove \"#{name}\" that was scheduled for #{date}.")
      if length(participants) > 0 do
        @api.create_message(channel_id, "Make sure to let the #{length(participants)} know!")
      end
      if link != nil do
        @api.create_message(channel_id, "You might have to cleanup #{link} as well.")
      end
    else
      {:ok, :none} ->
        @api.create_message(channel_id, "It doesn't look like that event exists. Are you sure you spelled it right?")
      {false, reason} ->
        @api.create_message(channel_id, reason)
    end
  end

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
         :ok <- Event.Persister.register(name, user_ids),
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

  defp unregister(discord_msg, name, users) do
    Logger.info "Running unimplemented unregister(#{name}, [#{Enum.join(users, ", ")}]) command"
    @api.create_message(discord_msg.channel_id, "WIP")
  end

  def tryout(discord_msg, raw_mentor, raw_mentee) when is_binary(raw_mentor) and is_binary(raw_mentee) do
    guild = Nostrum.Cache.GuildCache.get!(discord_msg.guild_id)
    mentors = guild
      |> DiscordQuery.mentors()
      |> DiscordQuery.matching_users(raw_mentor)
    non_members = guild
      |> DiscordQuery.non_members()
      |> DiscordQuery.matching_users(raw_mentee)
    output = (for m <- mentors, n <- non_members, do: {m, n})
      |> options_for_pairings()
      |> Enum.join("\n")

    @api.create_message(discord_msg.channel_id, output)
  end

  defp options_for_pairings([]), do: []
  defp options_for_pairings([{%User{username: n1, discriminator: d1}, %User{username: n2, discriminator: d2}} | rest]) do
    ["Enter `+#{length(rest)+1}` to run '+tryout @#{n1}##{d1} @#{n2}##{d2}'" | options_for_pairings(rest)]
  end
end
