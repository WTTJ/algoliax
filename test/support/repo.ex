defmodule Algoliax.Repo do
  use Ecto.Repo,
    otp_app: :algoliax,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    config =
      config
      |> put_env(:hostname)
      |> put_env(:port)
      |> put_env(:username)
      |> put_env(:password)

    {:ok, config}
  end

  defp put_env(config, key) do
    case load_env(key) do
      nil -> config
      val -> Keyword.put(config, key, val)
    end
  end

  defp load_env(:username), do: System.get_env("DB_USERNAME")
  defp load_env(:password), do: System.get_env("DB_PASSWORD")
  defp load_env(:hostname), do: System.get_env("POSTGRES_HOST")
  defp load_env(:port), do: System.get_env("POSTGRES_PORT")
end
