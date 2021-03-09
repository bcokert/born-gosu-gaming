defmodule Mentor do
  require Logger
  @api Application.get_env(:born_gosu_gaming, :discord_api)

  @dayinseconds 24*60*60
  @hourinseconds 60*60

  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.User

  def run(%Command{discord_msg: m, command: "help"}), do: help(m.channel_id, m.author.id)
  def run(%Command{discord_msg: m, command: "users", args: args}), do: users(m.channel_id, m.guild_id, args)
  def run(%Command{discord_msg: m, command: command, args: args}), do: unknown(m.channel_id, command, args, m.author.username, m.author.discriminator)

  defp unknown(channel_id, command, args, username, discriminator) do
    cmd = "`!mentor #{command} #{Enum.join(args, ", ")}` from #{username}\##{discriminator}"
    @api.create_message(channel_id, "Apologies, but I'm not sure what to do with this mentor command: #{cmd}")
  end

  defp help(channel_id, author_id) do
    @api.create_message(channel_id, "I'll dm you")
    with {:ok, dm} <- @api.create_dm(author_id) do
      @api.create_message(dm.id, String.trim("""
      Available commands:
        - users <field=joindate> <order=asc|desc> <count=20> <roles=""> <allroles=no|yes>
            Displays users sorted by a specific property. Always excludes bots.
            Defaults:
              field=joindate order=asc count=16 roles="Born Gosu" allroles=no
            eg: show the 16 oldest members, oldest at the top
              '!mentor users' (same as !mentor users field=joindate order=asc count=16 roles="Born Gosu")
            eg: show the newest 32 tryouts and members, newest at the top
              '!mentor users field=joindate order=desc count=32 roles="Tryouts, Born Gosu"'
            eg: show 32 diamond OR master players, newest at the top
              '!mentor users order=desc count=32 roles="Diamond, Master"'
            eg: show 16 diamond AND Zerg AND BG Members, newest at the top
              '!mentor users order=desc roles="Diamond, Zerg, Born Gosu"' allroles=yes
      """))
    end
  end

  defp users(channel_id, guild_id, args) do
    opts = Command.parseeqopts(args)
    case opts do
      {:illegal, illegal} ->
        @api.create_message(channel_id, "Looks like there's a problem with #{Enum.count(illegal)} of your options.\nThey should look like:\n`option=banana` or `option=\"Born Gosu, Tryout\"` if they have spaces.\nBad options:\n#{Enum.map(illegal, fn o -> "`#{o}`\n" end)}")
      opts ->
        case validateusersopts(opts) do
          [] ->
            userswithopts(channel_id, guild_id, cleanopts(opts))
          optionerrors ->
            @api.create_message(channel_id, "Looks like there's a problem with #{Enum.count(optionerrors)} of your options:\n#{Enum.join(optionerrors, "\n")}")
        end
    end
  end

  defp userswithopts(channel_id, guild_id, opts = [{"field", field}, {"order", order}, {"count", count}, {"roles", roles}, {"allroles", allroles}]) do
    @api.create_message(channel_id, "Searching for #{explain("count", count)} members with #{explain("allroles", allroles)} of these roles: #{explain("roles", roles)}, in #{explain("order", order)} order based on #{explain("field", field)}...")
    users = @api.list_guild_members(guild_id, limit: 1000)
    case users do
      {:error, e} ->
        @api.create_message(channel_id, "Discord failed to fetch memebers. Try again?")
        Logger.error("Error when searching discord for members with !mentor users: #{e}")
      {:ok, members} ->
        with guild <- Nostrum.Cache.GuildCache.get!(guild_id) do
          Logger.info("Starting user search for !mentor users #{opts |> Enum.map(fn {l, r} -> "#{l}: #{r}" end) |> Enum.join(", ")}")
          members
            |> Enum.filter(fn m -> m.user.bot == nil and rolefilter?(allroles, m, roles, guild) end)
            |> Enum.sort(fn (%Member{joined_at: l}, %Member{joined_at: r}) -> datecompare(l, r, order) end)
            |> Enum.take(count)
            |> prettyprintusers(channel_id, guild)
        end
    end
  end

  defp rolefilter?("no", m, roles, guild), do: DiscordQuery.member_has_any_role?(m, roles, guild)
  defp rolefilter?("yes", m, roles, guild), do: DiscordQuery.member_has_all_roles?(m, roles, guild)

  defp prettyprintusers([], channel_id, _) do
    @api.create_message(channel_id, "Looks like there are no users matching that criteria. Try widening your search?")
  end
  defp prettyprintusers(users, channel_id, guild) do
    @api.create_message(channel_id, "Found #{Enum.count(users)} matching users. Showing 10 at a time...")
    users
      |> Enum.map(fn m = %Member{joined_at: d, nick: nick, user: %User{username: username}} -> "#{prettyroles(m, guild)} #{prettyname(username, nick)} joined #{prettydate(d)}" end)
      |> Enum.chunk_every(10)
      |> Enum.map(fn chunk -> Enum.join(chunk, "\n") end)
      |> Enum.map(fn block ->
        @api.create_message(channel_id, block)
        :timer.sleep(2000)
      end)
  end

  defp prettyroles(m, guild) do
    rank = ["Grandmaster", "Master", "Diamond", "Platinum", "Gold", "Silver", "Bronze"]
      |> Enum.find("", fn r -> DiscordQuery.member_has_role?(m, r, guild) end)
      |> getmatchingemoji(":question:", guild)
    races = ["Terran", "Zerg", "Protoss", "Random"]
      |> Enum.map(fn r -> if DiscordQuery.member_has_role?(m, r, guild) do r else ":black_medium_square:" end end)
      |> Enum.map(fn r -> getmatchingemoji(r, ":black_medium_square:", guild) end)
      |> Enum.join("")
    "#{races}#{rank}"
  end

  defp getmatchingemoji(emojiname, default, guild) do
    guild.emojis()
      |> Enum.find(default, fn e -> e.name == emojiname end)
  end

  defp prettydate(iso8601) do
    {:ok, d, _} = DateTime.from_iso8601(iso8601)
    case DateTime.diff(DateTime.utc_now(), d, :second) do
      d when d >= @dayinseconds -> "#{Integer.floor_div(d, @dayinseconds)} days ago"
      d -> "#{Integer.floor_div(d, @hourinseconds)} hours ago"
    end
  end

  defp prettyname(username, nil), do: String.pad_trailing("`#{username}`", 1)
  defp prettyname(username, nickname), do: String.pad_trailing("`#{username}` (aka #{nickname})", 1)

  defp datecompare(iso8601_l, iso8601_r, order) do
    {:ok, l, _} = DateTime.from_iso8601(iso8601_l)
    {:ok, r, _} = DateTime.from_iso8601(iso8601_r)
    if order == "asc" do DateTime.diff(r, l) > 0 else DateTime.diff(r, l) < 0 end
  end

  defp explain("order", "asc"), do: "ascending"
  defp explain("order", "desc"), do: "descending"

  defp explain("field", "joindate"), do: "how long they've been here"

  defp explain("count", n), do: "#{n}"

  defp explain("roles", roles), do: "#{roles |> Enum.map(fn r -> "`#{r}`" end) |> Enum.join(", ")}"

  defp explain("allroles", "yes"), do: "all"
  defp explain("allroles", "no"), do: "any"

  defp defaultopts() do
    [
      {"field", "joindate"},
      {"order", "asc"},
      {"count", "16"},
      {"roles", "Born Gosu"},
      {"allroles", "no"},
    ]
  end

  defp optssanitizers() do
    [
      {"count", fn s -> elem(Integer.parse(s), 0) end},
      {"roles", fn roles -> String.split(roles, ",") |> Enum.map(fn r -> String.trim(r) end) end}
    ]
  end
  
  defp cleanopts(opts) do
    defaultopts()
      |> Enum.map(fn {dl, dr} -> takeifpresent(getopt(opts, dl), {dl, dr}) end)
      |> Enum.map(fn {l, r} -> {l, sanitize(getsanitizer(l), r)} end)
  end

  defp getsanitizer(opt) do
    optssanitizers() |> Enum.find(:none, fn {l, _} -> l == opt end)
  end

  defp takeifpresent(:none, default), do: default
  defp takeifpresent(opt, _), do: opt

  defp sanitize(:none, r), do: r
  defp sanitize({_, sanitizer}, r), do: sanitizer.(r)

  defp getopt(opts, opt) do
    Enum.find(opts, :none, fn {l, _} -> l == opt end)
  end

  defp validateusersopts(opts) do
    opts
      |> Enum.map(fn {l, r} -> validateusersopt(l, r) end)
      |> Enum.filter(fn r -> r != :valid end)
  end

  defp validateusersopt("field", "joindate"), do: :valid
  defp validateusersopt("field", o), do: "`field` must be one of: `joindate`. Received `#{o}`"

  defp validateusersopt("order", "asc"), do: :valid
  defp validateusersopt("order", "desc"), do: :valid
  defp validateusersopt("order", o), do: "`order` must be one of: `asc` `desc`. Received `#{o}`"

  defp validateusersopt("count", n) do
    case Integer.parse(n) do
      :error -> 
        "`count` must be a positive integer. Received `#{n}`"
      {nn, _} ->
        case nn > 0 do
          true -> :valid
          false -> "`count` must be a positive integer. Received `#{n}`"
        end
    end
  end

  defp validateusersopt("roles", ""), do: "`roles` cannot be empty"
  defp validateusersopt("roles", _), do: :valid

  defp validateusersopt("allroles", "yes"), do: :valid
  defp validateusersopt("allroles", "no"), do: :valid
  defp validateusersopt("allroles", o), do: "`allroles` must be one of: `yes` `no`. Received `#{o}`"
end
