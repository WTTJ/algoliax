defmodule Algoliax.Routes do
  @moduledoc false

  @suffix_host_read "-dsn.algolia.net/1/indexes"
  @suffix_host_write ".algolia.net/1/indexes"

  def url(:delete_index, index_name, _) do
    path = "/#{index_name}"
    url = url(:write, path)
    {:delete, url}
  end

  def url(:get_settings, index_name, _) do
    path = "/#{index_name}/settings"
    url = url(:read, path)
    {:get, url}
  end

  def url(:configure_index, index_name, _) do
    path = "/#{index_name}/settings"
    url = url(:write, path)
    {:put, url}
  end

  def url(:save_objects, index_name, _) do
    path = "/#{index_name}/batch"
    url = url(:write, path)
    {:post, url}
  end

  def url(:get_object, index_name, %{objectID: object_id}) do
    path = "/#{index_name}/#{object_id}"
    url = url(:read, path)
    {:get, url}
  end

  def url(:save_object, index_name, %{objectID: object_id}) do
    path = "/#{index_name}/#{object_id}"
    url = url(:write, path)
    {:put, url}
  end

  def url(:delete_object, index_name, %{objectID: object_id}) do
    path = "/#{index_name}/#{object_id}"
    url = url(:write, path)
    {:delete, url}
  end

  defp url(:write, path) do
    "https://" <> application_id() <> @suffix_host_write <> path
  end

  defp url(:read, path) do
    "https://" <> application_id() <> @suffix_host_read <> path
  end

  defp application_id do
    System.get_env("ALGOLIA_APPLICATION_ID") || Application.get_env(:algoliax, :application_id)
  end
end
