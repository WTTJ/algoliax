defmodule Algoliax.Client do
  @moduledoc false

  @callback get_object(index_name :: binary(), object :: map()) :: {:ok, map()} | {:error, any()}

  @callback save_objects(index_name :: binary(), objects :: list()) ::
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

defmodule Algoliax.Client.Http do
  @moduledoc false
  require Logger

  @behaviour Algoliax.Client
  alias Algoliax.{Config, Routes}

  @impl Algoliax.Client
  def get_object(index_name, object) do
    Logger.debug("Getting object #{inspect(object)}")
    {method, url} = Routes.url(:get_object, index_name, object)
    request(method, url)
  end

  @impl Algoliax.Client
  def save_objects(index_name, objects) do
    Logger.debug("Saving objects #{inspect(objects)}")
    {method, url} = Routes.url(:save_objects, index_name, objects)
    request(method, url, objects)
  end

  @impl Algoliax.Client
  def save_object(index_name, object) do
    Logger.debug("Saving object #{inspect(object)}")
    {method, url} = Routes.url(:save_object, index_name, object)
    request(method, url, object)
  end

  @impl Algoliax.Client
  def delete_object(index_name, object) do
    Logger.debug("Deleting object #{inspect(object)}")
    {method, url} = Routes.url(:delete_object, index_name, object)
    request(method, url)
  end

  @impl Algoliax.Client
  def get_settings(index_name) do
    Logger.debug("Getting settings for index = #{index_name}")
    {method, url} = Routes.url(:get_settings, index_name, nil)
    request(method, url)
  end

  @impl Algoliax.Client
  def configure_index(index_name, settings) do
    Logger.debug("Configuring index = #{index_name} with #{inspect(settings)}")
    {method, url} = Routes.url(:configure_index, index_name, settings)
    request(method, url, settings)
  end

  @impl Algoliax.Client
  def delete_index(index_name) do
    Logger.debug("Deleting index = #{index_name}")
    {method, url} = Routes.url(:delete_index, index_name, nil)
    request(method, url)
  end

  @impl Algoliax.Client
  def move_index(index_name, body) do
    Logger.debug("Moving index = #{index_name}")
    {method, url} = Routes.url(:move_index, index_name, nil)
    request(method, url, body)
  end

  defp request(method, url, body \\ nil) do
    method
    |> :hackney.request(url, request_headers(), Jason.encode!(body), [:with_body])
    |> case do
      {:ok, code, _headers, response} when code in 200..299 ->
        {:ok, Jason.decode!(response)}

      {:ok, code, _, response} ->
        {:error, code, response}
    end
  end

  defp request_headers do
    [
      {"X-Algolia-API-Key", Config.api_key()},
      {"X-Algolia-Application-Id", Config.application_id()}
    ]
  end
end
