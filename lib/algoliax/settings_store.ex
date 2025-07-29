defmodule Algoliax.SettingsStore do
  @moduledoc false

  use Agent

  @callback start_reindexing(binary) :: :ok

  @callback stop_reindexing(binary) :: :ok

  @callback reindexing?(binary) :: boolean()

  @callback set_settings(binary, map) :: :ok

  @callback get_settings(binary) :: map

  @callback delete_settings(binary) :: :ok
end
