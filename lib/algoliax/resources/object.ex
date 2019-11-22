defmodule Algoliax.Resources.Object do
  @moduledoc false

  alias Algoliax.{Config, Utils}
  alias Algoliax.Resources.Index

  import Ecto.Query

  def get_object(module, settings, model, attributes) do
    Index.ensure_settings(module, settings)

    object_id = get_object_id(module, settings, model, attributes)
    Config.requests().get_object(Utils.index_name(module, settings), %{objectID: object_id})
  end

  def save_objects(module, settings, models, attributes, opts) do
    Index.ensure_settings(module, settings)

    save_objects_tmp(module, settings, models, attributes, opts)

    index_name = Utils.index_name(module, settings)

    objects =
      Enum.map(models, fn model ->
        action = get_action(module, model, opts)

        if action do
          build_batch_object(module, settings, model, attributes, action)
        end
      end)
      |> Enum.reject(&is_nil/1)

    Config.requests().save_objects(index_name, %{requests: objects})
  end

  def save_object(module, settings, model, attributes) do
    Index.ensure_settings(module, settings)

    save_object_tmp(module, settings, model, attributes)

    if apply(module, :to_be_indexed?, [model]) do
      object = build_object(module, settings, model, attributes)
      index_name = Utils.index_name(module, settings)
      Config.requests().save_object(index_name, object)
    else
      {:not_indexable, model}
    end
  end

  def delete_object(module, settings, model, attributes) do
    Index.ensure_settings(module, settings)

    object = build_object(module, settings, model, attributes)
    index_name = Utils.index_name(module, settings)
    Config.requests().delete_object(index_name, object)
  end

  def reindex(module, settings, index_attributes, query, opts \\ []) do
    Index.ensure_settings(module, settings)

    repo = Utils.repo(settings)

    query =
      case query do
        %Ecto.Query{} = query ->
          query

        _ ->
          from(m in module)
      end

    Utils.find_in_batches(repo, query, 0, fn batch ->
      save_objects(module, settings, batch, index_attributes, opts)
    end)
  end

  def reindex_atomic(module, settings, index_attributes) do
    Utils.repo(settings)

    Index.ensure_settings(module, settings)

    index_name = Utils.index_name(module, settings)
    tmp_index_name = :"#{index_name}.tmp"
    tmp_settings = Keyword.put(settings, :index_name, tmp_index_name)

    Index.ensure_settings(module, tmp_settings)
    Algoliax.Agent.start_reindexing(index_name)

    reindex(module, tmp_settings, index_attributes, nil)

    response =
      Config.requests().move_index(tmp_index_name, %{
        operation: "move",
        destination: "#{index_name}"
      })

    Algoliax.Agent.delete_settings(tmp_index_name)
    Algoliax.Agent.stop_reindexing(index_name)

    response
  end

  def save_object_tmp(module, settings, model, attributes) do
    Task.async(fn ->
      index_name = Utils.index_name(module, settings)

      if Algoliax.Agent.reindexing?(index_name) do
        tmp_index_name = :"#{index_name}.tmp"
        tmp_settings = Algoliax.Agent.get_settings(tmp_index_name)

        save_object(module, tmp_settings, model, attributes)
      end
    end)
  end

  def save_objects_tmp(module, settings, models, attributes, opts) do
    Task.async(fn ->
      index_name = Utils.index_name(module, settings)

      if Algoliax.Agent.reindexing?(index_name) do
        tmp_index_name = :"#{index_name}.tmp"
        tmp_settings = Algoliax.Agent.get_settings(tmp_index_name)

        save_objects(module, tmp_settings, models, attributes, opts)
      end
    end)
  end

  defp build_batch_object(module, settings, model, attributes, action) do
    %{
      action: action,
      body: build_object(module, settings, model, attributes)
    }
  end

  defp build_object(module, settings, model, attributes) do
    Enum.into(attributes, %{}, fn a ->
      {Utils.unprefix_attribute(a), apply(module, a, [model])}
    end)
    |> Map.put(:objectID, get_object_id(module, settings, model, attributes))
  end

  defp get_object_id(module, settings, model, attributes) do
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
