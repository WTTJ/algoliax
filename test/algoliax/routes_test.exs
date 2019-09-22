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
               {:delete, "https://APPLICATION_ID.algolia.net/1/indexes/algolia_index"}
    end

    test "url get_settings" do
      assert Routes.url(:get_settings, index_name: @index_name) ==
               {:get, "https://APPLICATION_ID-dsn.algolia.net/1/indexes/algolia_index/settings"}
    end

    test "url configure_index" do
      assert Routes.url(:configure_index, index_name: @index_name) ==
               {:put, "https://APPLICATION_ID.algolia.net/1/indexes/algolia_index/settings"}
    end

    test "url save_objects" do
      assert Routes.url(:save_objects, index_name: @index_name) ==
               {:post, "https://APPLICATION_ID.algolia.net/1/indexes/algolia_index/batch"}
    end

    test "url get_object", %{people: people} do
      assert Routes.url(:get_object, index_name: @index_name, object_id: 10) ==
               {:get, "https://APPLICATION_ID-dsn.algolia.net/1/indexes/algolia_index/10"}
    end

    test "url save_object", %{people: people} do
      assert Routes.url(:save_object, index_name: @index_name, object_id: 10) ==
               {:put, "https://APPLICATION_ID.algolia.net/1/indexes/algolia_index/10"}
    end

    test "url delete_object", %{people: people} do
      assert Routes.url(:delete_object, index_name: @index_name, object_id: 10) ==
               {:delete, "https://APPLICATION_ID.algolia.net/1/indexes/algolia_index/10"}
    end
  end

  describe "First retry" do
    test "url delete_index" do
      assert Routes.url(:delete_index, [index_name: @index_name], 1) ==
               {:delete, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index"}
    end

    test "url get_settings" do
      assert Routes.url(:get_settings, [index_name: @index_name], 1) ==
               {:get, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index/settings"}
    end

    test "url configure_index" do
      assert Routes.url(:configure_index, [index_name: @index_name], 1) ==
               {:put, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index/settings"}
    end

    test "url save_objects" do
      assert Routes.url(:save_objects, [index_name: @index_name], 1) ==
               {:post, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index/batch"}
    end

    test "url get_object", %{people: people} do
      assert Routes.url(:get_object, [index_name: @index_name, object_id: 10], 1) ==
               {:get, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index/10"}
    end

    test "url save_object", %{people: people} do
      assert Routes.url(:save_object, [index_name: @index_name, object_id: 10], 1) ==
               {:put, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index/10"}
    end

    test "url delete_object", %{people: people} do
      assert Routes.url(:delete_object, [index_name: @index_name, object_id: 10], 1) ==
               {:delete, "https://APPLICATION_ID-1.algolianet.com/1/indexes/algolia_index/10"}
    end
  end
end
