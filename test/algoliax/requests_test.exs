defmodule Algoliax.RequestsTest do
  use ExUnit.Case, async: true
  import Mock

  test_with_mock "save object", Algoliax.Client,
    request: fn %{
                  action: :save_object,
                  url_params: [index_name: :index_name, object_id: 10],
                  body: _object
                } ->
      %{}
    end do
    Algoliax.Requests.save_object(:index_name, %{objectID: 10})

    assert_called(
      Algoliax.Client.request(%{
        action: :save_object,
        body: %{objectID: 10},
        url_params: [index_name: :index_name, object_id: 10]
      })
    )
  end

  test_with_mock "get object", Algoliax.Client,
    request: fn %{
                  action: :get_object,
                  url_params: [index_name: :index_name, object_id: 10]
                } ->
      %{}
    end do
    Algoliax.Requests.get_object(:index_name, %{objectID: 10})

    assert_called(
      Algoliax.Client.request(%{
        action: :get_object,
        url_params: [index_name: :index_name, object_id: 10]
      })
    )
  end

  test_with_mock "delete object", Algoliax.Client,
    request: fn %{
                  action: :delete_object,
                  url_params: [index_name: :index_name, object_id: 10]
                } ->
      %{}
    end do
    Algoliax.Requests.delete_object(:index_name, %{objectID: 10})

    assert_called(
      Algoliax.Client.request(%{
        action: :delete_object,
        url_params: [index_name: :index_name, object_id: 10]
      })
    )
  end

  test_with_mock "save objects", Algoliax.Client,
    request: fn %{
                  action: :save_objects,
                  url_params: [index_name: :index_name],
                  body: %{requests: [%{objectID: 10}]}
                } ->
      %{}
    end do
    Algoliax.Requests.save_objects(:index_name, %{requests: [%{objectID: 10}]})

    assert_called(
      Algoliax.Client.request(%{
        action: :save_objects,
        url_params: [index_name: :index_name]
      })
    )
  end
end
