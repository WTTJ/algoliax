defmodule Algoliax.Agent do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def set_settings(index_name, settings) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Map.put(index_name, settings)
    end)
  end

  def get_settings(index_name) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, index_name)
    end)
  end

  def get_object_id_attribute(index_name) do
    index_name
    |> get_settings()
    |> Keyword.get(:object_id)
  end
end
