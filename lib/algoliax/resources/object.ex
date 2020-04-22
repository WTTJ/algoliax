defmodule Algoliax.Resources.Object do
  @moduledoc false

  import Algoliax.Utils,
    only: [
      index_name: 2,
      object_id_attribute: 1
    ]

  alias Algoliax.{Requests, TemporaryIndexer}
  alias Algoliax.Resources.Index

  def get_object(module, settings, model) do
    Index.ensure_settings(module, settings)

    object_id = get_object_id(settings, model)
    Requests.get_object(index_name(module, settings), %{objectID: object_id})
  end

  def save_objects(module, settings, models, opts) do
    Index.ensure_settings(module, settings)

    index_name = index_name(module, settings)

    objects =
      Enum.map(models, fn model ->
        action = get_action(module, model, opts)

        if action do
          build_batch_object(module, settings, model, action)
        end
      end)
      |> Enum.reject(&is_nil/1)

    response = Requests.save_objects(index_name, %{requests: objects})
    call_indexer(:save_objects, module, settings, models, opts)
    response
  end

  def save_object(module, settings, model) do
    Index.ensure_settings(module, settings)

    if apply(module, :to_be_indexed?, [model]) do
      object = build_object(module, settings, model)
      index_name = index_name(module, settings)
      response = Requests.save_object(index_name, object)
      call_indexer(:save_object, module, settings, model)
      response
    else
      {:not_indexable, model}
    end
  end

  def delete_object(module, settings, model) do
    Index.ensure_settings(module, settings)
    call_indexer(:delete_object, module, settings, model)
    object = %{objectID: get_object_id(settings, model)}

    module
    |> index_name(settings)
    |> Requests.delete_object(object)
  end

  defp build_batch_object(_module, settings, model, "deleteObject" = action) do
    %{
      action: action,
      body: %{objectID: get_object_id(settings, model)}
    }
  end

  defp build_batch_object(module, settings, model, action) do
    %{
      action: action,
      body: build_object(module, settings, model)
    }
  end

  defp build_object(module, settings, model) do
    apply(module, :build_object, [model])
    |> Map.put(:objectID, get_object_id(settings, model))
  end

  defp get_object_id(settings, model) do
    Map.get(model, object_id_attribute(settings))
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

  defp call_indexer(action, module, settings, models, opts \\ []) do
    TemporaryIndexer.run(action, module, settings, models, opts)
  end
end
