defmodule Admin do
  require Logger
  @api Application.get_env(:born_gosu_gaming, :discord_api)

  def run(%Command{discord_msg: m, command: "help"}), do: help(m.channel_id, m.author.id)
  def run(%Command{discord_msg: m, command: "setdaylightsavings", args: [region, enabled? | _]}), do: setdaylightsavings(m.channel_id, region, enabled?)
  def run(%Command{discord_msg: m, command: "daylightsavings"}), do: daylightsavings(m.channel_id)
  def run(%Command{discord_msg: m, command: "tryout", args: [user1, user2 | _]}), do: tryout(m.channel_id, m.guild_id, m.author.id, user1, user2)
  def run(%Command{discord_msg: m, command: command, args: args}), do: unknown(m.channel_id, command, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, command, args, username, discriminator) do
    cmd = "`!admin #{command} #{Enum.join(args, ", ")}` from #{username}\##{discriminator}"
    @api.create_message(channel_id, "Apologies, but I'm not sure what to do with this admin command: #{cmd}")
  end

  defp help(channel_id, author_id) do
    @api.create_message(channel_id, "I'll dm you")
    with {:ok, dm} <- @api.create_dm(author_id) do
      @api.create_message(dm.id, String.trim("""
      Available commands:
        - daylightsavings
            Displays what the settings for daylight savings are
            eg: '!admin daylightsavings'
        
        - setdaylightsavings <eu|na> <yes|no>
            Toggles the default output formats between Daylight Savings and Summer
            times.
            eg: '!admin setdaylightsavings na yes'
            eg: '!admin setdaylightsavings eu no'
      """))
    end
  end

  defp daylightsavings(channel_id) do
    settings = Settings.get_output_timezones()
    if Map.has_key?(settings, :EDT), do: @api.create_message(channel_id, "For NA, daylight savings is active")
    if Map.has_key?(settings, :EST), do: @api.create_message(channel_id, "For NA, daylight savings is not active")
    if Map.has_key?(settings, :CEST), do: @api.create_message(channel_id, "For EU, daylight savings is active")
    if Map.has_key?(settings, :CET), do: @api.create_message(channel_id, "For EU, daylight savings is not active")
  end

  defp setdaylightsavings(channel_id, region, enabled?) do
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
  end

  defp tryout(channel_id, guild_id, author_id, raw_mentee, raw_mentor) when is_binary(raw_mentor) and is_binary(raw_mentee) do
    guild = Nostrum.Cache.GuildCache.get!(guild_id)
    mentors = guild
      |> DiscordQuery.mentors()
      |> DiscordQuery.matching_users(raw_mentor)
    non_members = guild
      |> DiscordQuery.non_members()
      |> DiscordQuery.matching_users(raw_mentee)
    author = @api.get_guild_member!(guild.id, author_id)

    tryout_response(guild_id, channel_id, author, mentors, non_members, raw_mentor, raw_mentee)
  end

  defp tryout_response(_, channel_id, _, [], [], raw_mentor, raw_mentee) do
    @api.create_message(channel_id, "No mentors matching '#{raw_mentor}' found, and no non-members matching '#{raw_mentee}' found")
  end
  defp tryout_response(_, channel_id, _, [], mentees, raw_mentor, _) do
    @api.create_message(channel_id, "No mentors matching '#{raw_mentor}' found, but found matching mentees: #{users_to_csv(mentees)}")
  end
  defp tryout_response(_, channel_id, _, mentors, [], _, raw_mentee) do
    @api.create_message(channel_id, "No non members matching '#{raw_mentee}' found, but found matching mentors: #{users_to_csv(mentors)}")
  end
  defp tryout_response(guild_id, channel_id, author, mentors, mentees, raw_mentor, raw_mentee) do
    matches = (for m <- mentors, n <- mentees, do: {m, n})
      |> Enum.with_index()
      |> Enum.map(fn {{m, n}, i} -> {m, n, i, num_emojis()["#{i}"], "+tryout #{n} #{m}"} end)

    message = matches
      |> Enum.map(fn {m, n, _, emoji, _} -> "React with #{emoji} to run `#{"+tryout #{n.username} #{m.username}"}`" end)
      |> Enum.join("\n")

    with {:ok, %{id: mid}} <- @api.create_message(channel_id, message) do
      reducer = fn (state, %{emoji: emoji, sender: sender_id, is_add: is_add}) ->
        user = @api.get_guild_member!(guild_id, sender_id)
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
end
