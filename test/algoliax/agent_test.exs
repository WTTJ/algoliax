defmodule Algoliax.SettingsStoreTest do
  use ExUnit.Case, async: false

  alias Algoliax.SettingsStore, as: Agent

  @index_name :algoliax_people

  setup do
    pid = Process.whereis(Agent)

    Agent.reset()
    %{agent_pid: pid}
  end

  test "set index settings", %{agent_pid: agent_pid} do
    Agent.set_settings(@index_name, foo: :bar)
    assert :sys.get_state(agent_pid) == %{@index_name => [foo: :bar]}
  end

  test "get index settings", %{agent_pid: agent_pid} do
    Agent.set_settings(@index_name, foo: :bar)
    settings = Agent.get_settings(@index_name)
    assert :sys.get_state(agent_pid) == %{@index_name => [foo: :bar]}
    assert settings == [foo: :bar]
  end

  test "delete index settings", %{agent_pid: agent_pid} do
    Agent.delete_settings(@index_name)
    settings = Agent.get_settings(@index_name)
    assert :sys.get_state(agent_pid) == %{}
    refute settings
  end

  test "start reindexing", %{agent_pid: agent_pid} do
    Agent.start_reindexing(@index_name)
    assert :sys.get_state(agent_pid) == %{reindexing: %{algoliax_people: "working"}}
  end

  test "stop reindexing", %{agent_pid: agent_pid} do
    Agent.start_reindexing(@index_name)
    assert :sys.get_state(agent_pid) == %{reindexing: %{algoliax_people: "working"}}
    Agent.stop_reindexing(@index_name)
    assert :sys.get_state(agent_pid) == %{reindexing: %{}}
  end

  test "reindexing?" do
    Agent.start_reindexing(@index_name)
    assert Agent.reindexing?(@index_name) == true
    Agent.stop_reindexing(@index_name)
    assert Agent.reindexing?(@index_name) == false
  end
end
