defmodule Algoliax.Resources.Object do
  @moduledoc false

  import Algoliax.Utils, only: [index_name: 2, object_id_attribute: 1]
  import Algoliax.Client, only: [request: 1]

  alias Algoliax.TemporaryIndexer

  def get_object(module, settings, model) do
    request(%{
      action: :get_object,
      url_params: [
        index_name: index_name(module, settings),
        object_id: get_object_id(module, settings, model)
      ]
    })
  end

  def save_objects(module, settings, models, opts) do
    objects =
      Enum.map(models, fn model ->
        action = get_action(module, model, opts)

        if action do
          build_batch_object(module, settings, model, action)
        end
      end)
      |> Enum.reject(&is_nil/1)

    if Enum.any?(objects) do
      call_indexer(:save_objects, module, settings, models, opts)

      request(%{
        action: :save_objects,
        url_params: [index_name: index_name(module, settings)],
        body: %{requests: objects}
      })
    end
  end

  def save_object(module, settings, model) do
    if apply(module, :to_be_indexed?, [model]) do
      object = build_object(module, settings, model)
      call_indexer(:save_object, module, settings, model)

      request(%{
        action: :save_object,
        url_params: [index_name: index_name(module, settings), object_id: object.objectID],
        body: object
      })
    else
      {:not_indexable, model}
    end
  end

  def delete_object(module, settings, model) do
    call_indexer(:delete_object, module, settings, model)

    request(%{
      action: :delete_object,
      url_params: [
        index_name: index_name(module, settings),
        object_id: get_object_id(module, settings, model)
      ]
    })
  end
  def delete_by(module, settings, matching_filter) do
    call_indexer(:delete_by, module, settings, matching_filter)

    body =
      case matching_filter do
        nil ->
          %{}

        _ ->
          %{params: "filters=#{matching_filter}"}
      end
    request(%{
      action: :delete_by,
      url_params: [
        index_name: index_name(module, settings),
      ],
      body: body
    })

  end

  defp build_batch_object(module, settings, model, "deleteObject" = action) do
    %{
      action: action,
      body: %{objectID: get_object_id(module, settings, model)}
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
    |> Map.put(:objectID, get_object_id(module, settings, model))
  end

  defp get_object_id(module, settings, model) do
    case apply(module, :get_object_id, [model]) do
      :default ->
        Map.fetch!(model, object_id_attribute(settings))

      value ->
        to_string(value)
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

  defp call_indexer(action, module, settings, models, opts \\ []) do
    TemporaryIndexer.run(action, module, settings, models, opts)
  end
end
