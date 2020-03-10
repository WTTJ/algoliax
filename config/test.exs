import Config

config :algoliax,
  application_id: "APPLICATION_ID",
  api_key: "api_key",
  ecto_repos: [Algoliax.Repo]

config :algoliax, Algoliax.Repo,
  database: "algoliax_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
