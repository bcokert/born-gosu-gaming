defmodule Mentor do
  require Logger
  @api Application.get_env(:born_gosu_gaming, :discord_api)

  def run(%Command{discord_msg: m, command: "help"}), do: help(m.channel_id, m.author.id)
  def run(%Command{discord_msg: m, command: "users", args: args}), do: users(m.channel_id, args)
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
        - users <field=joindate> <order=asc|desc> <count=20> <roles="">
            Displays users sorted by a specific property
            Defaults:
              field=joindate, order=asc, count=16 roles="Born Gosu"
            eg: show the 16 oldest members, oldest at the top
              '!mentor users' (same as !mentor users field=joindate order=asc count=16 roles="Born Gosu")
            eg: show the newest 32 tryouts and members, newest at the top
              '!mentor users field=joindate order=desc count=32 roles="Tryouts, Born Gosu"'
      """))
    end
  end

  defp users(channel_id, args) do
    opts = Command.parseeqopts(args)
    case opts do
      {:illegal, illegal} ->
        @api.create_message(channel_id, "Looks like there's a problem with #{Enum.count(illegal)} of your options.\nThey should look like:\n`option=banana` or `option=\"Born Gosu, Tryout\"` if they have spaces.\nBad options:\n#{Enum.map(illegal, fn o -> "`#{o}`\n" end)}")
      opts ->
        case validateusersopts(opts) do
          [] ->
            userswithopts(channel_id, cleanopts(opts))
          optionerrors ->
            @api.create_message(channel_id, "Looks like there's a problem with #{Enum.count(optionerrors)} of your options:\n#{Enum.join(optionerrors, "\n")}")
        end
    end
  end

  defp userswithopts(channel_id, opts) do
    # @api.list_guild_members()
    @api.create_message(channel_id, "Got\n#{opts |> Enum.map(fn {l, r} -> "#{l} = #{r}" end) |> Enum.join("\n")}")
  end

  defp defaultopts() do
    [
      {"field", "joindate"},
      {"order", "asc"},
      {"count", "16"},
      {"roles", "Born Gosu"},
    ]
  end

  defp optssanitizers() do
    [
      {"count", fn s -> elem(Integer.parse(s), 0) end}
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
end
