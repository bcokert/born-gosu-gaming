defmodule Main do
  use Application

  def start_link() do
    children = [
      Command.DiscordConsumer,
      {Event.Persister, name: Event.Persister}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start(_type, _args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    Main.start_link()
  end
end
