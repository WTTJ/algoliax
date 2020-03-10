defmodule Algoliax.SettingsStoreTest do
  use ExUnit.Case, async: false

  alias Algoliax.SettingsStore

  @index_name :algoliax_people

  setup do
    pid = Process.whereis(SettingsStore)

    SettingsStore.reset()
    %{agent_pid: pid}
  end

  test "set index settings", %{agent_pid: agent_pid} do
    SettingsStore.set_settings(@index_name, foo: :bar)
    assert :sys.get_state(agent_pid) == %{@index_name => [foo: :bar]}
  end

  test "get index settings", %{agent_pid: agent_pid} do
    SettingsStore.set_settings(@index_name, foo: :bar)
    settings = SettingsStore.get_settings(@index_name)
    assert :sys.get_state(agent_pid) == %{@index_name => [foo: :bar]}
    assert settings == [foo: :bar]
  end

  test "delete index settings", %{agent_pid: agent_pid} do
    SettingsStore.delete_settings(@index_name)
    settings = SettingsStore.get_settings(@index_name)
    assert :sys.get_state(agent_pid) == %{}
    refute settings
  end

  test "start reindexing", %{agent_pid: agent_pid} do
    SettingsStore.start_reindexing(@index_name)
    assert :sys.get_state(agent_pid) == %{reindexing: %{algoliax_people: "working"}}
  end

  test "stop reindexing", %{agent_pid: agent_pid} do
    SettingsStore.start_reindexing(@index_name)
    assert :sys.get_state(agent_pid) == %{reindexing: %{algoliax_people: "working"}}
    SettingsStore.stop_reindexing(@index_name)
    assert :sys.get_state(agent_pid) == %{reindexing: %{}}
  end

  test "reindexing?" do
    SettingsStore.start_reindexing(@index_name)
    assert SettingsStore.reindexing?(@index_name) == true
    SettingsStore.stop_reindexing(@index_name)
    assert SettingsStore.reindexing?(@index_name) == false
  end
end
