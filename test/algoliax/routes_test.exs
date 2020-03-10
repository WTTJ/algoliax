defmodule Algoliax.RoutesTest do
  use ExUnit.Case, async: true

  alias Algoliax.Routes

  @index_name :algolia_index

  setup do
    Application.put_env(:algoliax, :application_id, "APPLICATION_ID")

    people = %{objectID: 10}

    {:ok, %{people: people}}
  end

  describe "First attempts" do
    test "url delete_index" do
      assert Routes.url(:delete_index, index_name: @index_name) ==
               {:delete, "http://localhost:8002/APPLICATION_ID/write/algolia_index"}
    end

    test "url get_settings" do
      assert Routes.url(:get_settings, index_name: @index_name) ==
               {:get, "http://localhost:8002/APPLICATION_ID/read/algolia_index/settings"}
    end

    test "url configure_index" do
      assert Routes.url(:configure_index, index_name: @index_name) ==
               {:put, "http://localhost:8002/APPLICATION_ID/write/algolia_index/settings"}
    end

    test "url save_objects" do
      assert Routes.url(:save_objects, index_name: @index_name) ==
               {:post, "http://localhost:8002/APPLICATION_ID/write/algolia_index/batch"}
    end

    test "url get_object" do
      assert Routes.url(:get_object, index_name: @index_name, object_id: 10) ==
               {:get, "http://localhost:8002/APPLICATION_ID/read/algolia_index/10"}
    end

    test "url save_object" do
      assert Routes.url(:save_object, index_name: @index_name, object_id: 10) ==
               {:put, "http://localhost:8002/APPLICATION_ID/write/algolia_index/10"}
    end

    test "url delete_object" do
      assert Routes.url(:delete_object, index_name: @index_name, object_id: 10) ==
               {:delete, "http://localhost:8002/APPLICATION_ID/write/algolia_index/10"}
    end
  end

  describe "First retry" do
    test "url delete_index" do
      assert Routes.url(:delete_index, [index_name: @index_name], 1) ==
               {:delete, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index"}
    end

    test "url get_settings" do
      assert Routes.url(:get_settings, [index_name: @index_name], 1) ==
               {:get, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index/settings"}
    end

    test "url configure_index" do
      assert Routes.url(:configure_index, [index_name: @index_name], 1) ==
               {:put, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index/settings"}
    end

    test "url save_objects" do
      assert Routes.url(:save_objects, [index_name: @index_name], 1) ==
               {:post, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index/batch"}
    end

    test "url get_object" do
      assert Routes.url(:get_object, [index_name: @index_name, object_id: 10], 1) ==
               {:get, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index/10"}
    end

    test "url save_object" do
      assert Routes.url(:save_object, [index_name: @index_name, object_id: 10], 1) ==
               {:put, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index/10"}
    end

    test "url delete_object" do
      assert Routes.url(:delete_object, [index_name: @index_name, object_id: 10], 1) ==
               {:delete, "http://localhost:8002/APPLICATION_ID/retry/1/algolia_index/10"}
    end
  end
end
