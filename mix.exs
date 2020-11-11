defmodule ExampleConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :born_gosu_gaming,
      version: "2.0.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env)
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
      {:nostrum, "== 0.3.2", runtime: Mix.env != :test},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0", runtime: false},
      {:logger_file_backend, "~> 0.0.10"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

end
