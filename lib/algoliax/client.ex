defmodule Algoliax.Client do
  @moduledoc false

  @callback get_object(index_name :: binary(), object :: map()) :: map()
  @callback save_objects(index_name :: binary(), objects :: list()) :: map()
  @callback save_object(index_name :: binary(), object :: map()) :: map()
  @callback delete_object(index_name :: binary(), object :: map()) :: map()
  @callback get_settings(index_name :: binary()) :: map()
  @callback configure_index(index_name :: binary(), Keyword.t()) :: map()
  @callback delete_index(index_name :: binary()) :: map()
end

defmodule Algoliax.Client.Http do
  @moduledoc false

  @behaviour Algoliax.Client
  alias Algoliax.{Config, Routes}

  @impl Algoliax.Client
  def get_object(index_name, object) do
    {method, url} = Routes.url(:get_object, index_name, object)
    do_request(method, url)
  end

  @impl Algoliax.Client
  def save_objects(index_name, objects) do
    {method, url} = Routes.url(:save_objects, index_name, objects)
    do_request(method, url, objects)
  end

  @impl Algoliax.Client
  def save_object(index_name, object) do
    {method, url} = Routes.url(:save_object, index_name, object)
    do_request(method, url, object)
  end

  @impl Algoliax.Client
  def delete_object(index_name, object) do
    {method, url} = Routes.url(:delete_object, index_name, object)
    do_request(method, url)
  end

  @impl Algoliax.Client
  def get_settings(index_name) do
    {method, url} = Routes.url(:get_settings, index_name, nil)
    do_request(method, url)
  end

  @impl Algoliax.Client
  def configure_index(index_name, settings) do
    {method, url} = Routes.url(:configure_index, index_name, settings)
    do_request(method, url, settings)
  end

  @impl Algoliax.Client
  def delete_index(index_name) do
    {method, url} = Routes.url(:delete_index, index_name, nil)
    do_request(method, url)
  end

  defp do_request(method, url, body \\ nil) do
    {:ok, _status, _headers, ref} =
      :hackney.request(method, url, request_headers(), Jason.encode!(body))

    {:ok, response} = ref |> :hackney.body()
    response |> Jason.decode!()
  end

  defp request_headers do
    [
      {"X-Algolia-API-Key", Config.api_key()},
      {"X-Algolia-Application-Id", Config.application_id()}
    ]
  end
end
