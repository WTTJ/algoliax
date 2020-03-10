defmodule Algoliax.RequestsStore do
  use Agent

  def start_link(state \\ []) do
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  def clean do
    Agent.update(__MODULE__, fn _state ->
      []
    end)
  end

  def save(request) do
    Agent.update(__MODULE__, fn state ->
      [request | state]
    end)
  end

  def get do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def remove(request) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Enum.reject(fn r -> r.id == request.id end)
    end)
  end
end
