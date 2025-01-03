defmodule Algoliax.Resources.Index do
  @moduledoc false

  import Algoliax.Client, only: [request: 1]

  import Algoliax.Utils,
    only: [
      algolia_settings: 2,
      api_key: 2,
      application_id: 2,
      index_name: 2,
      render_response: 1
    ]

  alias Algoliax.{Settings, SettingsStore}

  def ensure_settings(module, index_name, settings, replica_index) do
    case SettingsStore.get_settings(index_name) do
      nil ->
        request_configure_index(
          index_name,
          module,
          settings,
          settings_to_algolia_settings(module, settings, replica_index)
        )

        algolia_remote_settings = request_get_settings(index_name, module, settings)
        SettingsStore.set_settings(index_name, algolia_remote_settings)
        replicas_names(module, settings, replica_index)

      _ ->
        true
    end
  end

  def replicas_names(module, settings, replica_index) do
    module
    |> replicas_settings(settings)
    |> Enum.map(fn replica_settings ->
      index_name(module, replica_settings)
      |> Enum.at(replica_index)
    end)
  end

  def replicas_settings(module, settings) do
    settings
    |> Keyword.get(:replicas, [])
    |> Enum.filter(fn replica -> should_be_updated?(module, replica) end)
    |> Enum.map(fn replica ->
      case Keyword.get(replica, :inherit, true) do
        true ->
          replica_algolia_settings = algolia_settings(module, replica)
          primary_algolia_settings = algolia_settings(module, settings)

          Keyword.put(
            replica,
            :algolia,
            Keyword.merge(primary_algolia_settings, replica_algolia_settings)
          )

        false ->
          replica
      end
    end)
  end

  defp should_be_updated?(module, replica) do
    index_name = Keyword.get(replica, :index_name, nil)

    error_message =
      "`if` must be `nil|true|false` or be the name of a 0-arity func which returns a boolean."

    value = Keyword.get(replica, :if, nil)

    cond do
      # No config, defaults to true
      is_nil(value) ->
        true

      # Boolean, use this value
      value == true || value == false ->
        value

      # Name of a 0-arity func
      is_atom(value) ->
        if module.__info__(:functions) |> Keyword.get(value) == 0 do
          apply(module, value, []) == true
        else
          raise Algoliax.InvalidReplicaConfigurationError, %{
            index_name: index_name,
            error: error_message
          }
        end

      # Any other value, raise an error
      true ->
        raise Algoliax.InvalidReplicaConfigurationError, %{
          index_name: index_name,
          error: error_message
        }
    end
  end

  def get_settings(module, settings) do
    index_name(module, settings)
    |> Enum.map(fn index_name ->
      algolia_remote_settings = request_get_settings(index_name, module, settings)
      SettingsStore.set_settings(index_name, algolia_remote_settings)
      algolia_remote_settings
    end)
    |> render_response()
  end

  def configure_index(module, settings) do
    index_name(module, settings)
    |> Enum.with_index()
    |> Enum.map(fn {index_name, replica_index} ->
      r =
        request_configure_index(
          index_name,
          module,
          settings,
          settings_to_algolia_settings(module, settings, replica_index)
        )

      configure_replicas(module, settings)
      r
    end)
    |> render_response()
  end

  def configure_replicas(module, settings) do
    module
    |> replicas_settings(settings)
    |> Enum.map(fn replica_settings ->
      configure_index(module, replica_settings)
    end)
  end

  defp request_configure_index(index_name, module, settings, alogolia_settings) do
    api_key = api_key(module, settings)
    application_id = application_id(module, settings)

    request(%{
      action: :configure_index,
      url_params: [index_name: index_name, application_id: application_id],
      body: alogolia_settings,
      api_key: api_key,
      application_id: application_id
    })
  end

  defp request_get_settings(index_name, module, settings) do
    api_key = api_key(module, settings)
    application_id = application_id(module, settings)

    request(%{
      action: :get_settings,
      url_params: [index_name: index_name, application_id: application_id],
      api_key: api_key,
      application_id: application_id
    })
  end

  def delete_index(module, settings) do
    api_key = api_key(module, settings)
    application_id = application_id(module, settings)

    index_name(module, settings)
    |> Enum.map(fn index_name ->
      request(%{
        action: :delete_index,
        url_params: [index_name: index_name, application_id: application_id],
        api_key: api_key,
        application_id: application_id
      })
    end)
    |> render_response()
  end

  defp settings_to_algolia_settings(module, settings, replica_index) do
    module
    |> algolia_settings(settings)
    |> Settings.map_algolia_settings()
    |> add_replicas_to_algolia_settings(module, settings, replica_index)
  end

  defp add_replicas_to_algolia_settings(algolia_settings, module, settings, replica_index) do
    algolia_settings |> Map.put(:replicas, replicas_names(module, settings, replica_index))
  end
end
