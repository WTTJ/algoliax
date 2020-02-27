defmodule Algoliax.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Algoliax.Agent,
      {Task.Supervisor, name: Algoliax.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Algoliax.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
