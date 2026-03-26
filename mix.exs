defmodule Algoliax.MixProject do
  use Mix.Project

  @source_url "https://github.com/WTTJ/algoliax"
  @version "0.10.0"

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
      {:hackney, "== 1.25.0"},
      {:ssl_verify_fun, "== 1.1.7"},
      {:jason, "== 1.4.4"},
      {:ex_doc, "== 0.40.1", only: :dev, runtime: false, override: true},
      {:ecto, "== 3.13.5", optional: true},
      {:ecto_sql, "== 3.13.5", only: [:dev, :test]},
      {:postgrex, "== 0.22.0", only: [:dev, :test]},
      {:inflex, "== 2.1.0"},
      {:credo, "== 1.7.17", only: [:dev, :test], runtime: false},
      {:faker, "== 0.18.0", only: :test},
      {:plug_cowboy, "== 2.8.0", only: :test},
      {:mix_test_watch, "== 1.4.0", only: :dev, runtime: false},
      {:sobelow, "== 0.14.1", only: [:dev, :test]},
      {:mix_audit, "== 2.1.5", only: [:dev, :test], runtime: false}
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
