defmodule Algoliax.Resources.Index do
  @moduledoc false

  import Algoliax.Utils, only: [index_name: 2, camelize: 1, algolia_settings: 1]
  import Algoliax.Client, only: [request: 1]

  alias Algoliax.{Settings, SettingsStore}

  def ensure_settings(index_name, settings) do
    case SettingsStore.get_settings(index_name) do
      nil ->
        request_configure_index(index_name, settings_to_algolia_settings(settings))
        algolia_remote_settings = request_get_settings(index_name)
        SettingsStore.set_settings(index_name, algolia_remote_settings)

      _ ->
        true
    end
  end

  def get_settings(module, settings) do
    index_name = index_name(module, settings)
    algolia_remote_settings = request_get_settings(index_name)
    SettingsStore.set_settings(index_name, algolia_remote_settings)
    algolia_remote_settings
  end

  def configure_index(module, settings) do
    index_name = index_name(module, settings)
    request_configure_index(index_name, settings_to_algolia_settings(settings))
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

  defp settings_to_algolia_settings(settings) do
    Settings.settings()
    |> Enum.into(%{}, fn setting ->
      {camelize(setting), Keyword.get(algolia_settings(settings), setting)}
    end)
  end
end
