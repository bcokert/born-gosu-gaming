use Mix.Config

config :born_gosu_gaming,
  discord_api: FakeDiscordApi,
  event_db: :"test_db/event",
  participant_db: :"test_db/participant"
