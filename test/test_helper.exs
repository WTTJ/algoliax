Algoliax.RequestsStore.start_link()
Algoliax.TaskStore.start_link()

Bandit.start_link(
  plug: Algoliax.ApiMockServer,
  port: System.get_env("API_MOCK_SERVER_PORT", "8002") |> String.to_integer()
)

ExUnit.start()
Algoliax.Repo.start_link([])
Ecto.Adapters.SQL.Sandbox.mode(Algoliax.Repo, :manual)
