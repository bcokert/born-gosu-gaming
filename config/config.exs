use Mix.Config

config :logger,
    backends: [{LoggerFileBackend, :debug_log}, {LoggerFileBackend, :info_log}, :console]

config :logger, :console,
    level: :debug

config :logger, :debug_log,
    path: "log/info.log",
    level: :debug,
    rotate: %{max_bytes: 1024*1024*1024*20, keep: 5 }

config :nostrum,
  token: "secret",
  num_shards: :auto

config :born_gosu_gaming,
  discord_api: Nostrum.Api,
  event_db: :"db/event",
  participant_db: :"db/participant",
  test_mode_role: "bg-events-tester",
  creator_role: "Born Gosu"

if Mix.env == :prod do
  config :born_gosu_gaming,
    event_db: :"/var/born-gosu-gaming/db/event",
    participant_db: :"/var/born-gosu-gaming/db/participant",
    is_test_mode: false
  
  import_config("./secret/prod/nostrum.exs")
else
  import_config("./secret/test/nostrum.exs")
end

if Mix.env == :test do
  import_config("#{Mix.env}.exs")
end
