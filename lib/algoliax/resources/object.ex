defmodule Algoliax.Resources.Object do
  @moduledoc false

  import Algoliax.Client, only: [request: 1]

  import Algoliax.Utils,
    only: [
      api_key: 1,
      application_id: 1,
      index_name: 2,
      object_id_attribute: 1,
      render_response: 1
    ]

  alias Algoliax.TemporaryIndexer

  def get_object(module, settings, model) do
    api_key = api_key(settings)
    application_id = application_id(settings)

    index_name(module, settings)
    |> Enum.map(fn index_name ->
      request(%{
        action: :get_object,
        url_params: [
          index_name: index_name,
          object_id: get_object_id(module, settings, model),
          application_id: application_id
        ],
        api_key: api_key,
        application_id: application_id
      })
    end)
    |> render_response()
  end

  def save_objects(module, settings, models, opts) do
    api_key = api_key(settings)
    application_id = application_id(settings)

    objects =
      index_name(module, settings)
      |> Enum.reduce(%{}, fn index_name, acc ->
        objects = build_batch_objects(index_name, module, models, settings, opts)
        Map.put(acc, index_name, objects)
      end)
      |> Enum.reject(fn {_index_name, objects} -> Enum.empty?(objects) end)

    if Enum.any?(objects) do
      call_indexer(:save_objects, module, settings, models, opts)

      objects
      |> Enum.map(fn {index_name, objects} ->
        request(%{
          action: :save_objects,
          url_params: [
            index_name: index_name,
            application_id: application_id
          ],
          body: %{requests: objects},
          api_key: api_key,
          application_id: application_id
        })
      end)
      |> render_response()
    end
  end

  defp build_batch_objects(index_name, module, models, settings, opts) do
    Enum.map(models, fn model ->
      action = get_action(module, model, opts)

      if action do
        build_batch_object(module, settings, model, action, index_name)
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def save_object(module, settings, model) do
    index_name(module, settings)
    |> Enum.map(fn index_name ->
      save_object(module, settings, model, index_name)
    end)
    |> render_response()
  end

  defp save_object(module, settings, model, index_name) do
    if apply(module, :to_be_indexed?, [model]) do
      api_key = api_key(settings)
      application_id = application_id(settings)

      object = build_object(module, settings, model, index_name)
      call_indexer(:save_object, module, settings, model)

      request(%{
        action: :save_object,
        url_params: [
          index_name: index_name,
          object_id: object.objectID,
          application_id: application_id
        ],
        body: object,
        api_key: api_key,
        application_id: application_id
      })
    else
      {:not_indexable, model}
    end
  end

  def delete_object(module, settings, model) do
    api_key = api_key(settings)
    application_id = application_id(settings)

    call_indexer(:delete_object, module, settings, model)

    index_name(module, settings)
    |> Enum.map(fn index_name ->
      request(%{
        action: :delete_object,
        url_params: [
          index_name: index_name,
          object_id: get_object_id(module, settings, model),
          application_id: application_id
        ],
        api_key: api_key,
        application_id: application_id
      })
    end)
    |> render_response()
  end

  def delete_by(module, settings, matching_filter) do
    api_key = api_key(settings)
    application_id = application_id(settings)

    call_indexer(:delete_by, module, settings, matching_filter)

    body =
      case matching_filter do
        nil ->
          %{}

        _ ->
          %{params: "filters=#{matching_filter}"}
      end

    index_name(module, settings)
    |> Enum.map(fn index_name ->
      request(%{
        action: :delete_by,
        url_params: [
          index_name: index_name,
          application_id: application_id
        ],
        body: body,
        api_key: api_key,
        application_id: application_id
      })
    end)
    |> render_response()
  end

  defp build_batch_object(module, settings, model, "deleteObject" = action, _index_name) do
    %{
      action: action,
      body: %{objectID: get_object_id(module, settings, model)}
    }
  end

  defp build_batch_object(module, settings, model, action, index_name) do
    %{
      action: action,
      body: build_object(module, settings, model, index_name)
    }
  end

  defp build_object(module, settings, model, index_name) do
    case apply(module, :build_object, [model, index_name]) do
      object when object == %{} -> apply(module, :build_object, [model])
      object -> object
    end
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
