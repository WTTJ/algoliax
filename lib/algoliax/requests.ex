defmodule Algoliax.RequestsBehaviour do
  @moduledoc false
  @callback search_index(index_name :: binary(), object :: map()) ::
              {:ok, map()} | {:error, any()}

  @callback search_facet(index_name :: binary(), facet_name :: binary(), object :: map()) ::
              {:ok, map()} | {:error, any()}

  @callback get_object(index_name :: binary(), object :: map()) :: {:ok, map()} | {:error, any()}

  @callback save_objects(index_name :: binary(), objects :: map()) ::
              {:ok, map()} | {:error, any()}

  @callback save_object(index_name :: binary(), object :: map()) :: {:ok, map()} | {:error, any()}

  @callback delete_object(index_name :: binary(), object :: map()) ::
              {:ok, map()} | {:error, any()}

  @callback get_settings(index_name :: binary()) :: {:ok, map()} | {:error, any()}

  @callback configure_index(index_name :: binary(), Keyword.t()) :: {:ok, map()} | {:error, any()}

  @callback delete_index(index_name :: binary()) :: {:ok, map()} | {:error, any()}

  @callback move_index(index_name :: binary(), new_index_name :: binary()) ::
              {:ok, map()} | {:error, any()}
end

defmodule Algoliax.Requests do
  @moduledoc false
  require Logger

  import Algoliax.Client, only: [request: 1]

  @behaviour Algoliax.RequestsBehaviour

  @impl Algoliax.RequestsBehaviour
  def search_index(index_name, body) do
    Logger.debug("Searching object #{inspect(body)}")

    request(%{
      action: :search_index,
      url_params: [index_name: index_name],
      body: body
    })
  end

  @impl Algoliax.RequestsBehaviour
  def search_facet(index_name, facet_name, body) do
    Logger.debug("Searching object #{inspect(body)}")

    request(%{
      action: :search_facet,
      url_params: [index_name: index_name, facet_name: facet_name],
      body: body
    })
  end

  @impl Algoliax.RequestsBehaviour
  def get_object(index_name, %{objectID: object_id} = object) do
    Logger.debug("Getting object #{inspect(object)}")

    request(%{
      action: :get_object,
      url_params: [index_name: index_name, object_id: object_id]
    })
  end

  @impl Algoliax.RequestsBehaviour
  def save_objects(index_name, objects) do
    Logger.debug("Saving objects #{inspect(objects)}")

    request(%{
      action: :save_objects,
      url_params: [index_name: index_name],
      body: objects
    })
  end

  @impl Algoliax.RequestsBehaviour
  def save_object(index_name, %{objectID: object_id} = object) do
    Logger.debug("Saving object #{inspect(object)}")

    request(%{
      action: :save_object,
      url_params: [index_name: index_name, object_id: object_id],
      body: object
    })
  end

  @impl Algoliax.RequestsBehaviour
  def delete_object(index_name, %{objectID: object_id} = object) do
    Logger.debug("Deleting object #{inspect(object)}")

    request(%{
      action: :delete_object,
      url_params: [index_name: index_name, object_id: object_id],
      body: object
    })
  end

  @impl Algoliax.RequestsBehaviour
  def get_settings(index_name) do
    Logger.debug("Getting settings for index = #{index_name}")

    request(%{
      action: :get_settings,
      url_params: [index_name: index_name]
    })
  end

  @impl Algoliax.RequestsBehaviour
  def configure_index(index_name, settings) do
    Logger.debug("Configuring index = #{index_name} with #{inspect(settings)}")

    request(%{
      action: :configure_index,
      url_params: [index_name: index_name],
      body: settings
    })
  end

  @impl Algoliax.RequestsBehaviour
  def delete_index(index_name) do
    Logger.debug("Deleting index = #{index_name}")

    request(%{action: :delete_index, url_params: [index_name: index_name]})
  end

  @impl Algoliax.RequestsBehaviour
  def move_index(index_name, body) do
    Logger.debug("Moving index = #{index_name}")

    request(%{
      action: :move_index,
      url_params: [index_name: index_name],
      body: body
    })
  end
end
