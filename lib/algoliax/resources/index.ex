defmodule Algoliax.Resources.Index do
  @moduledoc false

  import Algoliax.Utils, only: [index_name: 2, algolia_settings: 1, render_response: 1]
  import Algoliax.Client, only: [request: 1]

  alias Algoliax.{Settings, SettingsStore}

  def ensure_settings(module, index_name, settings, replica_index) do
    case SettingsStore.get_settings(index_name) do
      nil ->
        request_configure_index(
          index_name,
          settings_to_algolia_settings(module, settings, replica_index)
        )

        algolia_remote_settings = request_get_settings(index_name)
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
    |> Enum.filter(fn replica -> maybe_filter_replica(module, replica) end)
    |> Enum.map(fn replica ->
      case Keyword.get(replica, :inherit, true) do
        true ->
          replica_algolia_settings = algolia_settings(replica)
          primary_algolia_settings = algolia_settings(settings)

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

  defp maybe_filter_replica(module, replica) do
    index_name = Keyword.get(replica, :index_name, nil)

    error_message =
      "`to_be_deployed?` must be `nil|true|false` or be the name of a 0-arity func which returns a boolean."

    case Keyword.get(replica, :to_be_deployed?, nil) do
      nil ->
        true

      atom when is_atom(atom) ->
        is_valid_func = module.__info__(:functions) |> Keyword.get(atom) == 0

        cond do
          is_valid_func ->
            apply(module, atom, []) == true

          atom == true or atom == false ->
            atom

          true ->
            raise Algoliax.InvalidReplicaConfigurationError, %{
              index_name: index_name,
              error: error_message
            }
        end

      _ ->
        raise Algoliax.InvalidReplicaConfigurationError, %{
          index_name: index_name,
          error: error_message
        }
    end
  end

  def get_settings(module, settings) do
    index_name(module, settings)
    |> Enum.map(fn index_name ->
      algolia_remote_settings = request_get_settings(index_name)
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
    index_name(module, settings)
    |> Enum.map(fn index_name ->
      request(%{action: :delete_index, url_params: [index_name: index_name]})
    end)
    |> render_response()
  end

  defp settings_to_algolia_settings(module, settings, replica_index) do
    settings
    |> algolia_settings()
    |> Settings.map_algolia_settings()
    |> add_replicas_to_algolia_settings(module, settings, replica_index)
  end

  defp add_replicas_to_algolia_settings(algolia_settings, module, settings, replica_index) do
    algolia_settings |> Map.put(:replicas, replicas_names(module, settings, replica_index))
  end
end
