import Config

config :algoliax,
  application_id: "APPLICATION_ID",
  api_key: "api_key",
  batch_size: 1,
  ecto_repos: [Algoliax.Repo]

config :algoliax, Algoliax.Repo,
  database: "algoliax_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
