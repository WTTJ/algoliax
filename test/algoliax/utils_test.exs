defmodule Algoliax.UtilsTest do
  use ExUnit.Case, async: false

  defmodule NoRepo do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(updated_at)"],
      object_id: :reference
  end

  defmodule IndexNameFromFunction do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(updated_at)"],
      object_id: :reference

    def algoliax_people do
      :algoliax_people_from_function
    end

    def additional_indexes do
      [:index_en, :index_fr]
    end
  end

  defmodule NoIndexName do
    use Algoliax.Indexer,
      attributes_for_faceting: ["age"],
      searchable_attributes: ["full_name"],
      custom_ranking: ["desc(updated_at)"],
      object_id: :reference
  end

  describe "Raise exception if trying Ecto specific methods" do
    test "Algoliax.MissingRepoError" do
      assert_raise(Algoliax.MissingRepoError, fn ->
        Algoliax.UtilsTest.NoRepo.reindex()
      end)

      assert_raise(Algoliax.MissingRepoError, fn ->
        Algoliax.UtilsTest.NoRepo.reindex_atomic()
      end)
    end
  end

  describe "Raise exception if index_name missing" do
    test "Algoliax.MissingRepoError" do
      assert_raise(Algoliax.MissingIndexNameError, fn ->
        Algoliax.UtilsTest.NoIndexName.get_settings()
      end)
    end
  end

  describe "Camelize" do
    test "an atom" do
      assert Algoliax.Utils.camelize(:foo_bar) == "fooBar"
    end

    test "a map" do
      a = %{foo_bar: "test", bar_foo: "test"}
      assert Algoliax.Utils.camelize(a) == %{"fooBar" => "test", "barFoo" => "test"}
    end
  end

  describe "index_name/2" do
    test "with a function" do
      assert Algoliax.Utils.index_name(IndexNameFromFunction, index_name: :algoliax_people) ==
               [:algoliax_people_from_function]
    end

    test "without a function" do
      assert Algoliax.Utils.index_name(NoRepo, index_name: :algoliax_people) ==
               [:algoliax_people]
    end
  end
end
