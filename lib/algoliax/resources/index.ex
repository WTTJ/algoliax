defmodule Algoliax.Resources.Index do
  @moduledoc false

  alias Algoliax.{Agent, Settings, Utils, Config}

  def ensure_settings(settings) do
    index_name = Utils.index_name(settings)

    case Agent.get_settings(index_name) do
      nil ->
        configure_index(settings)
        get_settings(settings)

      _ ->
        true
    end
  end

  def get_settings(settings) do
    index_name = Utils.index_name(settings)
    algolia_remote_settings = Config.client_http().get_settings(index_name)
    Agent.set_settings(index_name, algolia_remote_settings)
    algolia_remote_settings
  end

  def configure_index(settings) do
    index_name = Utils.index_name(settings)

    algolia_settings =
      Settings.settings()
      |> Enum.into(%{}, fn setting ->
        {Settings.to_algolia_setting(setting), Keyword.get(settings, setting)}
      end)

    Config.client_http().configure_index(index_name, algolia_settings)
  end

  def delete_index(settings) do
    index_name = Utils.index_name(settings)
    Config.client_http().delete_index(index_name)
  end
end
