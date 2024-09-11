defmodule Algoliax.Repo do
  use Ecto.Repo,
    otp_app: :algoliax,
    adapter: Ecto.Adapters.Postgres
end
