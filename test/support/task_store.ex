defmodule Algoliax.TaskStore do
  @moduledoc false

  use Agent

  def start_link(state \\ %{}) do
    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  def increment(task_id) do
    Agent.update(__MODULE__, fn state ->
      current_count = Map.get(state, task_id, 0)
      Map.put(state, task_id, current_count + 1)
    end)
  end

  def get(task_id) do
    Agent.get(__MODULE__, fn state -> Map.get(state, task_id, 0) end)
  end

  def remove(task_id) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, task_id) end)
  end
end
