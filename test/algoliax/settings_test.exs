defmodule Algoliax.SettingsTest do
  use ExUnit.Case, async: true

  defmodule ModuleWithAlgoliaSettingsFunc do
    def algolia_settings do
      [
        attributes_for_faceting: ["location"],
        searchable_attributes: ["first_name"]
      ]
    end
  end

  defmodule SynonymsWithFunc do
    use Algoliax.Indexer,
      index_name: :algoliax_people,
      algolia: [],
      object_id: :reference,
      synonyms: :get_synonyms

    def get_synonyms("list"), do: [forward_to_replicas: false]
    def get_synonyms("nil"), do: nil
    def get_synonyms(_), do: [extra_keys: "should be removed"]
  end

  test "settings/0" do
    assert Algoliax.Settings.settings() == [
             :searchable_attributes,
             :attributes_for_faceting,
             :unretrievable_attributes,
             :attributes_to_retrieve,
             :mode,
             :ranking,
             :custom_ranking,
             :relevancy_strictness,
             :max_values_per_facet,
             :sort_facet_values_by,
             :attributes_to_highlight,
             :attributes_to_snippet,
             :highlight_pre_tag,
             :highlight_post_tag,
             :snippet_ellipsis_text,
             :restrict_highlight_and_snippet_arrays,
             :hits_per_page,
             :pagination_limited_to,
             :min_word_sizefor1_typo,
             :min_word_sizefor2_typos,
             :typo_tolerance,
             :allow_typos_on_numeric_tokens,
             :disable_typo_tolerance_on_attributes,
             :disable_typo_tolerance_on_words,
             :separators_to_index,
             :ignore_plurals,
             :attributes_to_transliterate,
             :remove_stop_words,
             :camel_case_attributes,
             :decompounded_attributes,
             :keep_diacritics_on_characters,
             :custom_normalization,
             :query_languages,
             :index_languages,
             :decompound_query,
             :enable_rules,
             :enable_personalization,
             :query_type,
             :remove_words_if_no_results,
             :advanced_syntax,
             :optional_words,
             :disable_prefix_on_attributes,
             :disable_exact_on_attributes,
             :exact_on_single_word_query,
             :alternatives_as_exact,
             :advanced_syntax_features,
             :numeric_attributes_for_filtering,
             :allow_compression_of_integer_array,
             :attribute_for_distinct,
             :distinct,
             :replace_synonyms_in_highlight,
             :min_proximity,
             :response_fields,
             :max_facet_hits,
             :attribute_criteria_computed_by_min_proximity,
             :user_data,
             :rendering_content
           ]
  end

  describe "replica_settings/2" do
    test "default" do
      replica_settings = [
        name: :algoliax_people_by_age_asc,
        attributes_for_faceting: ["age"],
        ranking: ["asc(age)"]
      ]

      settings = [
        index_name: :algoliax_people,
        object_id: :reference,
        repo: MyApp.Repo,
        algolia: [
          attributes_for_faceting: ["location"],
          searchable_attributes: ["full_name"]
        ],
        replicas: [replica_settings]
      ]

      assert result = Algoliax.Settings.replica_settings(settings, replica_settings)

      assert result["attributesForFaceting"] == ["age"]
      assert result["searchableAttributes"] == ["full_name"]
      assert result["ranking"] == ["asc(age)"]
    end

    test "inherit:true" do
      replica_settings = [
        name: :algoliax_people_by_age_asc,
        attributes_for_faceting: ["age"],
        ranking: ["asc(age)"],
        inherit: true
      ]

      settings = [
        index_name: :algoliax_people,
        object_id: :reference,
        repo: MyApp.Repo,
        algolia: [
          attributes_for_faceting: ["location"],
          searchable_attributes: ["full_name"]
        ],
        replicas: [replica_settings]
      ]

      assert result = Algoliax.Settings.replica_settings(settings, replica_settings)

      assert result["attributesForFaceting"] == ["age"]
      assert result["searchableAttributes"] == ["full_name"]
      assert result["ranking"] == ["asc(age)"]
    end

    test "inherit:false" do
      replica_settings = [
        name: :algoliax_people_by_age_asc,
        attributes_for_faceting: ["age"],
        ranking: ["asc(age)"],
        inherit: false
      ]

      settings = [
        index_name: :algoliax_people,
        object_id: :reference,
        repo: MyApp.Repo,
        algolia: [
          attributes_for_faceting: ["location"],
          searchable_attributes: ["full_name"]
        ],
        replicas: [replica_settings]
      ]

      assert result = Algoliax.Settings.replica_settings(settings, replica_settings)

      assert result["attributesForFaceting"] == ["age"]
      assert result["searchableAttributes"] == nil
      assert result["ranking"] == ["asc(age)"]
    end

    test "with algolia settings func" do
      replica_settings = [
        name: :algoliax_people_by_age_asc,
        attributes_for_faceting: ["age"],
        ranking: ["asc(age)"],
        inherit: true
      ]

      settings = [
        index_name: :algoliax_people,
        object_id: :reference,
        repo: MyApp.Repo,
        algolia: :algolia_settings,
        replicas: [replica_settings]
      ]

      assert result =
               Algoliax.Settings.replica_settings(
                 ModuleWithAlgoliaSettingsFunc,
                 settings,
                 replica_settings
               )

      assert result["attributesForFaceting"] == ["age"]
      assert result["searchableAttributes"] == ["first_name"]
      assert result["ranking"] == ["asc(age)"]
    end
  end
end
