defmodule Algoliax.RequestsTest do
  use ExUnit.Case, async: true
  import Mock

  test_with_mock "search index", Algoliax.Client,
    request: fn %{
                  action: :search,
                  url_params: [index_name: :index_name],
                  body: %{}
                } ->
      %{}
    end do
    Algoliax.Requests.search(:index_name, %{})

    assert_called(
      Algoliax.Client.request(%{
        action: :search,
        body: %{},
        url_params: [index_name: :index_name]
      })
    )
  end

  test_with_mock "search facet", Algoliax.Client,
    request: fn %{
                  action: :search_facet,
                  url_params: [index_name: :index_name, facet_name: "age"],
                  body: %{}
                } ->
      %{}
    end do
    Algoliax.Requests.search_facet(:index_name, "age", %{})

    assert_called(
      Algoliax.Client.request(%{
        action: :search_facet,
        body: %{},
        url_params: [index_name: :index_name, facet_name: "age"]
      })
    )
  end

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

  test_with_mock "get settings", Algoliax.Client,
    request: fn %{
                  action: :get_settings,
                  url_params: [index_name: :index_name]
                } ->
      %{}
    end do
    Algoliax.Requests.get_settings(:index_name)

    assert_called(
      Algoliax.Client.request(%{
        action: :get_settings,
        url_params: [index_name: :index_name]
      })
    )
  end

  test_with_mock "configure index", Algoliax.Client,
    request: fn %{
                  action: :configure_index,
                  url_params: [index_name: :index_name],
                  body: %{}
                } ->
      %{}
    end do
    Algoliax.Requests.configure_index(:index_name, %{})

    assert_called(
      Algoliax.Client.request(%{
        action: :configure_index,
        url_params: [index_name: :index_name],
        body: %{}
      })
    )
  end

  test_with_mock "delete index", Algoliax.Client,
    request: fn %{
                  action: :delete_index,
                  url_params: [index_name: :index_name]
                } ->
      %{}
    end do
    Algoliax.Requests.delete_index(:index_name)

    assert_called(
      Algoliax.Client.request(%{
        action: :delete_index,
        url_params: [index_name: :index_name]
      })
    )
  end

  test_with_mock "move index", Algoliax.Client,
    request: fn %{
                  action: :move_index,
                  url_params: [index_name: :index_name],
                  body: %{operation: "move", destination: "new_index_name"}
                } ->
      %{}
    end do
    Algoliax.Requests.move_index(:index_name, %{operation: "move", destination: "new_index_name"})

    assert_called(
      Algoliax.Client.request(%{
        action: :move_index,
        url_params: [index_name: :index_name],
        body: %{operation: "move", destination: "new_index_name"}
      })
    )
  end
end
