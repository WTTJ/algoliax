defmodule Algoliax.SettingsStore.Agent do
  @moduledoc false

  use Agent

  @behaviour Algoliax.SettingsStore

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def reset do
    Agent.update(__MODULE__, fn _state ->
      %{}
    end)
  end

  @impl Algoliax.SettingsStore
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

  @impl Algoliax.SettingsStore
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

  @impl Algoliax.SettingsStore
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

  @impl Algoliax.SettingsStore
  def set_settings(index_name, settings) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Map.put(index_name, settings)
    end)
  end

  @impl Algoliax.SettingsStore
  def get_settings(index_name) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, index_name)
    end)
  end

  @impl Algoliax.SettingsStore
  def delete_settings(index_name) do
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, index_name)
    end)
  end
end
