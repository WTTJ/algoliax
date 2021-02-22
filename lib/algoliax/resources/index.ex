defmodule Algoliax.Resources.Index do
  @moduledoc false

  import Algoliax.Utils, only: [index_name: 2, camelize: 1, algolia_settings: 1]
  import Algoliax.Client, only: [request: 1]

  alias Algoliax.{Settings, SettingsStore}

  def ensure_settings(module, index_name, settings) do
    case SettingsStore.get_settings(index_name) do
      nil ->
        request_configure_index(index_name, settings_to_algolia_settings(module, settings))
        algolia_remote_settings = request_get_settings(index_name)
        SettingsStore.set_settings(index_name, algolia_remote_settings)
        replicas_names(module, settings)

      _ ->
        true
    end
  end

  def replicas_names(module, settings) do
    settings
    |> replicas_settings()
    |> Enum.map(fn replica_settings ->
      index_name(module, replica_settings)
    end)
  end

  def replicas_settings(settings) do
    replicas = Keyword.get(settings, :replicas, [])

    Enum.map(replicas, fn replica ->
      case Keyword.get(replica, :inherits, true) do
        true ->
          replica_algolia_settings = algolia_settings(replica)
          primary_algolia_setttings = algolia_settings(settings)

          Keyword.put(
            replica,
            :algolia,
            Keyword.merge(primary_algolia_setttings, replica_algolia_settings)
          )

        false ->
          replica
      end
    end)
  end

  def get_settings(module, settings) do
    index_name = index_name(module, settings)
    algolia_remote_settings = request_get_settings(index_name)
    SettingsStore.set_settings(index_name, algolia_remote_settings)
    algolia_remote_settings
  end

  def configure_index(module, settings) do
    index_name = index_name(module, settings)
    r = request_configure_index(index_name, settings_to_algolia_settings(module, settings))
    configure_replicas(module, settings)

    r
  end

  def configure_replicas(module, settings) do
    settings
    |> replicas_settings()
    |> Enum.map(fn replica_settings ->
      configure_index(module, replica_settings)
    end)
  end

  defp request_configure_index(index_name, settings) do
    request(%{
      action: :configure_index,
      url_params: [index_name: index_name],
      body: settings
    })
  end

  defp request_get_settings(index_name) do
    request(%{
      action: :get_settings,
      url_params: [index_name: index_name]
    })
  end

  def delete_index(module, settings) do
    request(%{action: :delete_index, url_params: [index_name: index_name(module, settings)]})
  end

  defp settings_to_algolia_settings(module, settings) do
    settings
    |> algolia_settings()
    |> Settings.map_algolia_settings()
    |> add_replicas_to_algolia_settings(module, settings)
  end

  defp add_replicas_to_algolia_settings(algolia_settings, module, settings) do
    algolia_settings |> Map.put(:replicas, replicas_names(module, settings))
  end

  defp replicas(settings), do: Keyword.get(settings, :replicas, [])

  defp map_algolia_settings(algolia_settings) do
    Settings.settings()
    |> Enum.into(%{}, fn setting ->
      {camelize(setting), Keyword.get(algolia_settings, setting)}
    end)
  end
end
