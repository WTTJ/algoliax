defmodule Algoliax.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Algoliax.Worker.start_link(arg)
      # {Algoliax.Worker, arg}
      Algoliax.SettingsStore
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Algoliax.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
