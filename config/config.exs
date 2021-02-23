use Mix.Config

config :logger,
    backends: [{LoggerFileBackend, :info_log}, {LoggerFileBackend, :sasl_log}, :console]

config :logger, :console,
    level: :debug

config :logger, :info_log,
    path: "log/info.log",
    handle_sasl_reports: false,
    level: :info,
    rotate: %{max_bytes: 1024*1024*1024*20, keep: 5 }

config :logger, :sasl_log,
    path: "log/sasl.log",
    handle_sasl_reports: true,
    level: :error,
    rotate: %{max_bytes: 1024*1024*1024*20, keep: 5 }

config :nostrum,
  token: "secret",
  num_shards: :auto

config :born_gosu_gaming,
  discord_api: Nostrum.Api,
  event_db: :"db/event",
  test_mode_role: "bg-events-tester"

if Mix.env == :prod do
  config :born_gosu_gaming,
    event_db: :"/var/born-gosu-gaming/db/event"
  
  import_config("./secret/prod/nostrum.exs")
else
  import_config("./secret/test/nostrum.exs")
end

if Mix.env == :test do
  import_config("#{Mix.env}.exs")
end
