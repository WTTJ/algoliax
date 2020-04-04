defmodule Algoliax.Resources.Object do
  @moduledoc false

  import Algoliax.Utils,
    only: [
      index_name: 2,
      unprefix_attribute: 1,
      prefix_attribute: 1,
      object_id_attribute: 1
    ]

  alias Algoliax.{Requests, TemporaryIndexer}
  alias Algoliax.Resources.Index

  def get_object(module, settings, model, attributes) do
    Index.ensure_settings(module, settings)

    object_id = get_object_id(module, settings, model, attributes)
    Requests.get_object(index_name(module, settings), %{objectID: object_id})
  end

  def save_objects(module, settings, models, attributes, opts) do
    Index.ensure_settings(module, settings)

    index_name = index_name(module, settings)

    objects =
      Enum.map(models, fn model ->
        action = get_action(module, model, opts)

        if action do
          build_batch_object(module, settings, model, attributes, action)
        end
      end)
      |> Enum.reject(&is_nil/1)

    response = Requests.save_objects(index_name, %{requests: objects})
    call_indexer(:save_objects, module, settings, models, attributes, opts)
    response
  end

  def save_object(module, settings, model, attributes) do
    Index.ensure_settings(module, settings)

    if apply(module, :to_be_indexed?, [model]) do
      object = build_object(module, settings, model, attributes)
      index_name = index_name(module, settings)
      response = Requests.save_object(index_name, object)
      call_indexer(:save_object, module, settings, model, attributes)
      response
    else
      {:not_indexable, model}
    end
  end

  def delete_object(module, settings, model, attributes) do
    Index.ensure_settings(module, settings)
    call_indexer(:delete_object, module, settings, model, attributes)
    object = %{objectID: get_object_id(module, settings, model, attributes)}

    module
    |> index_name(settings)
    |> Requests.delete_object(object)
  end

  defp build_batch_object(module, settings, model, attributes, "deleteObject" = action) do
    %{
      action: action,
      body: %{objectID: get_object_id(module, settings, model, attributes)}
    }
  end

  defp build_batch_object(module, settings, model, attributes, action) do
    %{
      action: action,
      body: build_object(module, settings, model, attributes)
    }
  end

  defp build_object(module, settings, model, []) do
    apply(module, :build_object, [model])
    |> Map.put(:objectID, get_object_id(module, settings, model, []))
  end

  defp build_object(module, settings, model, attributes) do
    Enum.into(attributes, %{}, fn a ->
      {unprefix_attribute(a), apply(module, a, [model])}
    end)
    |> prepare_object(model, settings)
    |> Map.put(:objectID, get_object_id(module, settings, model, attributes))
  end

  defp prepare_object(object, model, settings) do
    do_prepare_object(object, model, Keyword.get(settings, :prepare_object))
  end

  defp do_prepare_object(object, model, prepare_object_fn)
       when is_function(prepare_object_fn, 2) do
    prepare_object_fn.(object, model)
  end

  defp do_prepare_object(object, _, _) do
    object
  end

  defp get_object_id(module, settings, model, attributes) do
    case Enum.find(attributes, fn a -> a == prefix_attribute(object_id_attribute(settings)) end) do
      nil ->
        Map.get(model, object_id_attribute(settings))

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

  defp call_indexer(action, module, settings, models, attributes, opts \\ []) do
    TemporaryIndexer.run(action, module, settings, models, attributes, opts)
  end
end
