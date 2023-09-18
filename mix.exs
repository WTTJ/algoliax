defmodule Algoliax.MixProject do
  use Mix.Project

  @source_url "https://github.com/WTTJ/algoliax"
  @version "0.8.0"

  def project do
    [
      app: :algoliax,
      name: "Algoliax",
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
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
      {:hackney, "~> 1.18"},
      {:ssl_verify_fun, "~> 1.1.7"},
      {:jason, "~> 1.3"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, override: true},
      {:ecto, "~> 3.9", optional: true},
      {:ecto_sql, "~> 3.9", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:inflex, "~> 2.0.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.12", only: :test},
      {:plug_cowboy, "~> 2.6", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test]},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false}
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
      description: "AlgoliaSearch integration for Elixir app",
      maintainers: ["Stéphane Robino"],
      licenses: ["BSD-2-Clause"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      links: %{
        "Changelog" => "https://hexdocs.pm/algoliax/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  def docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"],
        "guides/examples/global.md": [],
        "guides/examples/secured_api_key.md": []
      ],
      main: "readme",
      source_url: @source_url,
      homepage_url: @source_url,
      formatters: ["html"],
      groups_for_extras: [
        Examples: Path.wildcard("guides/examples/*.md")
      ]
    ]
  end
end
