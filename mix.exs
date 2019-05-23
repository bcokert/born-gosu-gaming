defmodule ExampleConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :born_gosu_gaming,
      version: "1.0.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Main, []}
    ]
  end

  defp deps do
    [
      {:nostrum, "~> 0.3"},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
