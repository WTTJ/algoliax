defmodule Algoliax.Agent do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def reset do
    Agent.update(__MODULE__, fn _state ->
      %{}
    end)
  end

  def start_reindexing(index_name) do
    Agent.update(__MODULE__, fn state ->
      reindexings =
        state
        |> Map.get(:reindexing, %{})
        |> Map.put(index_name, "working")

      state
      |> Map.put(:reindexing, reindexings)
    end)
  end

  def stop_reindexing(index_name) do
    Agent.update(__MODULE__, fn state ->
      reindexings =
        state
        |> Map.get(:reindexing, %{})
        |> Map.delete(index_name)

      state
      |> Map.put(:reindexing, reindexings)
    end)
  end

  def reindexing?(index_name) do
    Agent.get(__MODULE__, fn state ->
      state
      |> Map.get(:reindexing, %{})
      |> Map.get(index_name)
    end)
    |> case do
      nil ->
        false

      _ ->
        true
    end
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

  def delete_settings(index_name) do
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, index_name)
    end)
  end
end
