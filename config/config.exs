use Mix.Config

config :nostrum,
  token: "secret",
  num_shards: :auto

config :born_gosu_gaming,
  discord_api: Nostrum.Api,
  db_file: :"db/eventPeristence"

import_config("./secret/nostrum.exs")

if Mix.env == :test do
  import_config("#{Mix.env}.exs")
end
