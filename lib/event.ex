defmodule Event do
  @enforce_keys [:name, :date, :creator]
  defstruct [:name, :date, :creator, :description, :link, participants: []]

  @type t :: %Event{
    name: String.t(),
    date: DateTime.t(),
    creator: Nostrum.Snowflake.t(),
    participants: [Nostrum.Snowflake.t()],
    link: String.t(),
    description: String.t()
  }

  require Logger
  alias Nostrum.Api
  alias Nostrum.Struct.User

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
  defp do_command("register", [name | users], m), do: register(m, name, users)
  defp do_command("unregister", [name | users], m), do: unregister(m, name, users)
  defp do_command("tryout", [user1, user2 | _], m), do: tryout(m, user1, user2)
  defp do_command(name, args, m), do: unknown(m.channel_id, name, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, name, args, username, discriminator) do
    cmd = "#{name}(#{Enum.join(args, ", ")}) from #{username}\##{discriminator}"
    Api.create_message(channel_id, "Unknown command or args: #{cmd}")
  end

  defp help(discord_msg) do
    Api.create_message(discord_msg.channel_id, "I'll dm you")

    case Api.create_dm(discord_msg.author.id) do
      {:ok, channel} ->
        Api.create_message(channel.id, String.trim("""
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
        Api.create_message(discord_msg.channel_id, "Oops! Something went wrong fetching upcoming events. Please tell PhysicsNoob")
      [] ->
        Api.create_message(discord_msg.channel_id, "No Events are Upcoming")
      events ->
        event_lines = Enum.map(events, fn e -> soon_format_event(e) end)
        Api.create_message(discord_msg.channel_id, """
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
        {:ok, %Nostrum.Struct.User{username: name, discriminator: disc}} ->
          name <> "#" <> disc
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
        Participants (#{length(participants)}):
          #{Enum.join(participants, "\n  ")}
    """
  end

  defp me(discord_msg) do
    Logger.info "Running unimplemented me command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  defp add(discord_msg, name, date_str) do
    case DateTime.from_iso8601(date_str) do
      {:ok, date, _} ->
        case Event.Persister.create(%Event{name: name, date: date, creator: discord_msg.author.id}) do
          :error ->
            Api.create_message(discord_msg.channel_id, "Oops! Something went wrong creating that event. Please tell PhysicsNoob")
          event ->
            creator = case Nostrum.Cache.UserCache.get(discord_msg.author.id) do
              {:ok, %Nostrum.Struct.User{username: name, discriminator: disc}} ->
                name <> "#" <> disc
              {:error, reason} ->
                Logger.warn("Failed to get creator from cache in 'add': #{reason}")
                "@#{event.creator}"
            end
            Api.create_message(discord_msg.channel_id, """
            Event Created!
              #{event.name} by #{creator} on #{DateTime.to_date(event.date)} at #{event.date.hour}:#{event.date.minute} (#{event.date.time_zone})
            """)
        end
      {:error, _} ->
        Api.create_message(discord_msg.channel_id, "Illegal input date: #{date_str}. Compare it to '2021-01-19T16:30:00-08'")
    end
  end

  defp remove(discord_msg, name) do
    Logger.info "Running unimplemented remove(#{name}) command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  defp register(discord_msg, name, users) do
    Logger.info "Running unimplemented register(#{name}, [#{Enum.join(users, ", ")}]) command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  defp unregister(discord_msg, name, users) do
    Logger.info "Running unimplemented unregister(#{name}, [#{Enum.join(users, ", ")}]) command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  def tryout(discord_msg, raw_mentor, raw_mentee) do
    guild = Nostrum.Cache.GuildCache.get!(discord_msg.guild_id)
    mentors = "Mentor"
      |> DiscordQuery.role_by_name(guild)
      |> DiscordQuery.users_with_role(guild)
      |> DiscordQuery.matching_users(raw_mentor)
    non_members = "Non-Born Gosu"
      |> DiscordQuery.role_by_name(guild)
      |> DiscordQuery.users_with_role(guild)
      |> DiscordQuery.matching_users(raw_mentee)
    output = (for m <- mentors, n <- non_members, do: {m, n})
      |> options_for_pairings()
      |> Enum.join("\n")

    Api.create_message(discord_msg.channel_id, output)
  end

  defp options_for_pairings([]), do: []
  defp options_for_pairings([{%User{username: n1, discriminator: d1}, %User{username: n2, discriminator: d2}} | rest]) do
    ["Enter `+#{length(rest)+1}` to run '+tryout @#{n1}##{d1} @#{n2}##{d2}'" | options_for_pairings(rest)]
  end
end
