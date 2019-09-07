defmodule Algoliax.MixProject do
  use Mix.Project

  def project do
    [
      app: :algoliax,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # docs
      name: "Algoliax",
      source_url: "https://github.com/StephaneRob/algoliax",
      homepage_url: "https://github.com/StephaneRob/algoliax",
      docs: [
        # The main page in the docs
        main: "Algoliax",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Algoliax.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:hackney, "~> 1.15.1"},
      {:jason, "~> 1.1"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false, override: true},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:inflex, "~> 2.0.0"},
      {:mox, "~> 0.5", only: :test},
      {:credo, "~> 1.1.2", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.12", only: :test}
    ]
  end

  defp aliases do
    [
      # Ensures database is reset before tests are run
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
