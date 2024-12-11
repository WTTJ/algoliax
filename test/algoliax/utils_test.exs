defmodule Algoliax.UtilsTest do
  use ExUnit.Case, async: false

  defmodule NoRepo do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference
  end

  defmodule IndexNameFromFunction do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference

    def algoliax_people do
      :algoliax_people_from_function
    end
  end

  defmodule MultipleIndexNames do
    use Algoliax.Indexer,
      index_name: [:algoliax_people_en, :algoliax_people_fr],
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference
  end

  defmodule MultipleIndexNameFromFunction do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference

    def algoliax_people do
      [:algoliax_people_from_function_en, :algoliax_people_from_function_fr]
    end
  end

  defmodule NoIndexName do
    use Algoliax.Indexer,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference
  end

  defmodule NoDefaultFilters do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference
  end

  defmodule DefaultFiltersInSettings do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference,
      default_filters: %{where: [age: 42]}
  end

  defmodule DefaultFiltersWithFunction do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [
        attributes_for_faceting: ["age"],
        searchable_attributes: ["full_name"],
        custom_ranking: ["desc(updated_at)"]
      ],
      object_id: :reference,
      default_filters: :default_filters

    def default_filters do
      %{where: [age: 43]}
    end
  end

  defmodule AlgoliaSettingsFunction do
    def valid_func do
      [
        attributes_for_faceting: ["age2"],
        searchable_attributes: ["full_name2"]
      ]
    end

    def invalid_return_func do
      :invalid
    end

    def invalid_arity_func(arg) do
      arg
    end
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

    test "multiple indexes with a function" do
      assert Algoliax.Utils.index_name(MultipleIndexNameFromFunction,
               index_name: :algoliax_people
             ) ==
               [:algoliax_people_from_function_en, :algoliax_people_from_function_fr]
    end

    test "multiple indexes without a function" do
      assert Algoliax.Utils.index_name(MultipleIndexNames,
               index_name: [:algoliax_people_en, :algoliax_people_fr]
             ) ==
               [:algoliax_people_en, :algoliax_people_fr]
    end
  end

  describe "algolia_settings/2" do
    test "with a nothing" do
      assert Algoliax.Utils.algolia_settings(%{}, []) == []
    end

    test "with a list" do
      assert Algoliax.Utils.algolia_settings(%{},
               algolia: [
                 attributes_for_faceting: ["age"],
                 searchable_attributes: ["full_name"]
               ]
             ) == [
               attributes_for_faceting: ["age"],
               searchable_attributes: ["full_name"]
             ]
    end

    test "with a function" do
      assert Algoliax.Utils.algolia_settings(AlgoliaSettingsFunction, algolia: :valid_func) == [
               attributes_for_faceting: ["age2"],
               searchable_attributes: ["full_name2"]
             ]
    end

    test "with a function with invalid return" do
      assert_raise(Algoliax.InvalidAlgoliaSettingsFunctionError, fn ->
        Algoliax.Utils.algolia_settings(AlgoliaSettingsFunction, algolia: :invalid_return_func)
      end)
    end

    test "with an unknown function" do
      assert_raise(Algoliax.InvalidAlgoliaSettingsFunctionError, fn ->
        Algoliax.Utils.algolia_settings(AlgoliaSettingsFunction, algolia: :unknown_func)
      end)
    end

    test "with an non-0-arity function" do
      assert_raise(Algoliax.InvalidAlgoliaSettingsFunctionError, fn ->
        Algoliax.Utils.algolia_settings(AlgoliaSettingsFunction, algolia: :invalid_arity_func)
      end)
    end

    test "with a map" do
      assert_raise(Algoliax.InvalidAlgoliaSettingsConfigurationError, fn ->
        Algoliax.Utils.algolia_settings(AlgoliaSettingsFunction, algolia: 42)
      end)
    end
  end

  describe "default_filters/2" do
    test "not provided" do
      assert Algoliax.Utils.default_filters(NoDefaultFilters, []) == %{}
    end

    test "provided in settings" do
      assert Algoliax.Utils.default_filters(DefaultFiltersInSettings,
               default_filters: %{where: [age: 42]}
             ) == %{where: [age: 42]}
    end

    test "provided as a function" do
      assert Algoliax.Utils.default_filters(DefaultFiltersWithFunction,
               default_filters: :default_filters
             ) == %{where: [age: 43]}
    end
  end
end
