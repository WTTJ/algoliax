defmodule Algoliax.Utils do
  @moduledoc false

  alias Algoliax.Resources.Index

  def index_name(module, settings) do
    index_name = Keyword.get(settings, :index_name)
    Index.ensure_settings(index_name, settings)

    if index_name do
      if module.__info__(:functions)
         |> Keyword.get(index_name) == 0 do
        apply(module, index_name, [])
      else
        index_name
      end
    else
      raise Algoliax.MissingIndexNameError
    end
  end

  def algolia_settings(settings) do
    Keyword.get(settings, :algolia, [])
  end

  def object_id_attribute(settings) do
    Keyword.get(settings, :object_id, :id)
  end

  def schemas(settings, default) do
    Keyword.get(settings, :schemas, default)
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
end
