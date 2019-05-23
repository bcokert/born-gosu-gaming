use Mix.Config

config :nostrum,
  token: "secret",
  num_shards: :auto

import_config("./secret/nostrum.exs")
