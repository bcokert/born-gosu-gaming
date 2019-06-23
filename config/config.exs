use Mix.Config

config :nostrum,
  token: "secret",
  num_shards: :auto

config :born_gosu_gaming,
  discord_api: Nostrum.Api,
  event_db: :"db/event",
  participant_db: :"db/participant"

if Mix.env == :prod do
  config :born_gosu_gaming,
  event_db: :"/var/born-gosu-gaming/db/event",
  participant_db: :"/var/born-gosu-gaming/db/participant"
end

import_config("./secret/nostrum.exs")

if Mix.env == :test do
  import_config("#{Mix.env}.exs")
end
