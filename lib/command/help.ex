defmodule Help do
  require Logger
  @api Application.get_env(:born_gosu_gaming, :discord_api)

  def run(%Command{discord_msg: m}), do: help(m.channel_id)

  defp help(channel_id) do
    @api.create_message(channel_id, String.trim("""
    Try one of these to get help specific to that area:

    `!help` - Shows this help text.
    `!events` - List the commands related to events.
    `!admin` - List the commands related to admins.
    `!mentor` - List the commands related to mentors.

    You can also talk directly to Alfred! Try one of these:
    `@Alfred send huskies`
    `@Alfred I need some inspiration`
    `@Alfred Tell me a joke`
    ... and many more to discover
    """))
  end
end
