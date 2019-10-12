import Config

config :algoliax,
  ecto_repos: [Algoliax.Repo]

config :algoliax, Algoliax.Repo,
  database: "algoliax_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
