defmodule Algoliax.Utils do
  @moduledoc false

  alias Algoliax.Resources.Index

  def index_name(module, settings) do
    indexes =
      case Keyword.get(settings, :index_name) do
        nil ->
          raise Algoliax.MissingIndexNameError

        atom when is_atom(atom) ->
          if module.__info__(:functions) |> Keyword.get(atom) == 0 do
            apply(module, atom, [])
            |> to_list()
          else
            [atom]
          end

        list when is_list(list) ->
          list
      end

    indexes
    |> Enum.with_index()
    |> Enum.each(fn {index, i} -> Index.ensure_settings(module, index, settings, i) end)

    indexes
  end

  def algolia_settings(module, settings) do
    case Keyword.get(settings, :algolia, []) do
      # Could be a 0-arity function that returns a list
      atom when is_atom(atom) ->
        with 0 <- Keyword.get(module.__info__(:functions), atom),
             result when is_list(result) <- apply(module, atom, []) do
          result
        else
          _any ->
            raise Algoliax.InvalidAlgoliaSettingsFunctionError, %{
              function_name: inspect(atom)
            }
        end

      # Could be a list
      list when is_list(list) ->
        list

      # Refuse anything else
      _other ->
        raise Algoliax.InvalidAlgoliaSettingsConfigurationError
    end
  end

  def synonyms_settings(module, settings, index_name) do
    case Keyword.get(settings, :synonyms, nil) do
      # Could be nil
      nil ->
        nil

      # Could be a 1-arity function that returns a keyword list or nil
      atom when is_atom(atom) ->
        with 1 <- Keyword.get(module.__info__(:functions), atom),
             result when is_list(result) or is_nil(result) <- apply(module, atom, [index_name]) do
          result
        else
          _any ->
            raise Algoliax.InvalidSynonymsSettingsFunctionError, %{
              function_name: inspect(atom)
            }
        end

      # Could be an hardcoded list
      list when is_list(list) ->
        list

      # Refuse anything else
      _other ->
        raise Algoliax.InvalidSynonymsSettingsConfigurationError
    end
  end

  def object_id_attribute(settings) do
    Keyword.get(settings, :object_id, :id)
  end

  def default_filters(module, settings) do
    case Keyword.get(settings, :default_filters, %{}) do
      fn_name when is_atom(fn_name) ->
        apply(module, fn_name, [])

      default_filters ->
        default_filters
    end
  end

  def schemas(module, settings) do
    with fn_name when is_atom(fn_name) <- Keyword.get(settings, :schemas, [module]) do
      apply(module, fn_name, [])
    end
  end

  def camelize(params) when is_map(params) do
    Enum.into(params, %{}, fn {k, v} ->
      {camelize(k), v}
    end)
  end

  def camelize(key) do
    key
    |> Atom.to_string()
    |> Inflex.camelize(:lower)
  end

  def render_response([response]), do: response

  def render_response([_ | _] = responses) do
    results =
      responses
      |> List.flatten()
      |> Enum.reject(&(match?({:not_indexable, _model}, &1) or is_nil(&1)))
      |> Enum.group_by(fn
        {:ok, %Algoliax.Response{params: params}} -> params[:index_name]
        {:error, _, _, %{url_params: params}} -> params[:index_name]
      end)
      |> Enum.map(fn {index_name, results} ->
        %Algoliax.Responses{
          index_name: index_name,
          responses: results
        }
      end)

    {:ok, results}
  end

  defp to_list(indexes) when is_list(indexes), do: indexes
  defp to_list(index), do: [index]
end
