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
            |> case do
              indexes when is_list(indexes) -> indexes
              index -> [index]
            end
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

  def algolia_settings(settings) do
    Keyword.get(settings, :algolia, [])
  end

  def object_id_attribute(settings) do
    Keyword.get(settings, :object_id, :id)
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
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&match?({:not_indexable, _model}, &1))
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
end
