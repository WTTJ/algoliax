defmodule Algoliax.MixProject do
  use Mix.Project

  def project do
    [
      app: :algoliax,
      version: "0.3.0-alpha",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # docs
      name: "Algoliax",
      source_url: "https://github.com/StephaneRob/algoliax",
      homepage_url: "https://github.com/StephaneRob/algoliax",
      docs: [
        # The main page in the docs
        main: "Algoliax",
        extras: ["README.md"]
      ],

      # Hex
      description: "AlgoliaSearch integration for Elixir app",
      package: package()
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
      {:hackney, "~> 1.15.2"},
      {:jason, "~> 1.1"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false, override: true},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:inflex, "~> 2.0.0"},
      {:mox, "~> 0.5", only: :test},
      {:mock, "~> 0.3.0", only: :test},
      {:credo, "~> 1.3.0", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.12", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test}
    ]
  end

  defp aliases do
    [
      # Ensures database is reset before tests are run
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp package do
    [
      maintainers: ["Stéphane Robino"],
      licenses: ["BSD-2-Clause"],
      links: %{"GitHub" => "https://github.com/StephaneRob/algoliax"}
    ]
  end
end
