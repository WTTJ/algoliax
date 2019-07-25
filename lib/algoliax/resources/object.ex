defmodule Algoliax.Resources.Object do
  @moduledoc false

  alias Algoliax.{Config, Utils}
  alias Algoliax.Resources.Index

  import Ecto.Query

  def get_object(settings, module, model, attributes) do
    Index.ensure_settings(settings)

    object_id = get_object_id(settings, module, model, attributes)
    Config.client_http().get_object(Utils.index_name(settings), %{objectID: object_id})
  end

  def save_objects(settings, module, models, attributes, opts) do
    Index.ensure_settings(settings)

    index_name = Utils.index_name(settings)

    objects =
      Enum.map(models, fn model ->
        action = get_action(module, model, opts)

        if action do
          build_batch_object(settings, module, model, attributes, action)
        end
      end)
      |> Enum.reject(&is_nil/1)

    body = %{
      requests: objects
    }

    Config.client_http().save_objects(index_name, body)
  end

  def save_object(settings, module, model, attributes) do
    Index.ensure_settings(settings)

    if apply(module, :to_be_indexed?, [model]) do
      object = build_object(settings, module, model, attributes)
      index_name = Utils.index_name(settings)
      Config.client_http().save_object(index_name, object)
    else
      {:not_indexable, model}
    end
  end

  def delete_object(settings, module, model, attributes) do
    Index.ensure_settings(settings)

    object = build_object(settings, module, model, attributes)
    index_name = Utils.index_name(settings)
    Config.client_http().delete_object(index_name, object)
  end

  def reindex(settings, module, index_attributes, query, opts \\ []) do
    Index.ensure_settings(settings)

    repo = Utils.repo(settings)

    query =
      case query do
        %Ecto.Query{} = query ->
          query

        _ ->
          from(m in module)
      end

    stream = repo.stream(query)

    repo.transaction(fn ->
      save_objects(settings, module, stream, index_attributes, opts)
    end)
  end

  def reindex_atomic(settings, _module, _index_attributes) do
    Index.ensure_settings(settings)

    index_name = Utils.index_name(settings)
    tmp_index_name = index_name <> ".tmp"
    _tmp_settings = Keyword.put(settings, :index_name, tmp_index_name)
    :ok
  end

  defp build_batch_object(settings, module, model, attributes, action) do
    %{
      action: action,
      body: build_object(settings, module, model, attributes)
    }
  end

  defp build_object(settings, module, model, attributes) do
    Enum.into(attributes, %{}, fn a ->
      {Utils.unprefix_attribute(a), apply(module, a, [model])}
    end)
    |> Map.put(:objectID, get_object_id(settings, module, model, attributes))
  end

  defp get_object_id(settings, module, model, attributes) do
    object_id_attribute = Keyword.get(settings, :object_id)

    case Enum.find(attributes, fn a -> a == Utils.prefix_attribute(object_id_attribute) end) do
      nil ->
        Map.get(model, object_id_attribute)

      a ->
        apply(module, a, [model])
    end
  end

  defp get_action(module, model, opts) do
    if apply(module, :to_be_indexed?, [model]) do
      "updateObject"
    else
      if Keyword.get(opts, :force_delete) do
        "deleteObject"
      end
    end
  end
end
