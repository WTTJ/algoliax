import Config

config :algoliax,
  application_id: "APPLICATION_ID",
  api_key: "api_key",
  batch_size: 1,
  ecto_repos: [Algoliax.Repo],
  env: "test"

config :algoliax, Algoliax.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: System.get_env("POSTGRES_PORT", "5432"),
  database: System.get_env("DB_NAME", "algoliax_test"),
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres")

config :algoliax,
  mock_api_port: System.get_env("ALGOLIA_MOCK_API_PORT", "8002")

config :logger, level: :warning
