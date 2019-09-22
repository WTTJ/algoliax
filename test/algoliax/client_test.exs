defmodule Algoliax.ClientTest do
  use ExUnit.Case, async: true
  import Mock

  test_with_mock "save object", Algoliax.Request,
    request: fn %{
                  action: :save_object,
                  url_params: [index_name: :index_name, object_id: 10],
                  body: object
                } ->
      %{}
    end do
    Algoliax.Client.Http.save_object(:index_name, %{objectID: 10})

    assert_called(
      Algoliax.Request.request(%{
        action: :save_object,
        body: %{objectID: 10},
        url_params: [index_name: :index_name, object_id: 10]
      })
    )
  end

  test_with_mock "get object", Algoliax.Request,
    request: fn %{
                  action: :get_object,
                  url_params: [index_name: :index_name, object_id: 10]
                } ->
      %{}
    end do
    Algoliax.Client.Http.get_object(:index_name, %{objectID: 10})

    assert_called(
      Algoliax.Request.request(%{
        action: :get_object,
        url_params: [index_name: :index_name, object_id: 10]
      })
    )
  end

  test_with_mock "delete object", Algoliax.Request,
    request: fn %{
                  action: :delete_object,
                  url_params: [index_name: :index_name, object_id: 10]
                } ->
      %{}
    end do
    Algoliax.Client.Http.delete_object(:index_name, %{objectID: 10})

    assert_called(
      Algoliax.Request.request(%{
        action: :delete_object,
        url_params: [index_name: :index_name, object_id: 10]
      })
    )
  end

  test_with_mock "save objects", Algoliax.Request,
    request: fn %{
                  action: :save_objects,
                  url_params: [index_name: :index_name],
                  body: %{requests: [%{objectID: 10}]}
                } ->
      %{}
    end do
    Algoliax.Client.Http.save_objects(:index_name, %{requests: [%{objectID: 10}]})

    assert_called(
      Algoliax.Request.request(%{
        action: :save_objects,
        url_params: [index_name: :index_name]
      })
    )
  end
end
