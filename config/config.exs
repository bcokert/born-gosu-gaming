use Mix.Config

config :nostrum,
  token: "secret",
  num_shards: :auto

config :born_gosu_gaming,
  discord_api: Nostrum.Api,
  event_db: :"db/event",
  participant_db: :"db/participant"

import_config("./secret/nostrum.exs")

if Mix.env == :test do
  import_config("#{Mix.env}.exs")
end
