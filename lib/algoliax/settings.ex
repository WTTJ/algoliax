defmodule Algoliax.Settings do
  @moduledoc false

  alias Algoliax.Utils

  # https://www.algolia.com/doc/api-reference/settings-api-parameters/
  @algolia_settings [
    # Attributes
    :searchable_attributes,
    :attributes_for_faceting,
    :unretrievable_attributes,
    :attributes_to_retrieve,
    # Ranking
    :mode,
    :ranking,
    :custom_ranking,
    :relevancy_strictness,
    # Faceting
    :max_values_per_facet,
    :sort_facet_values_by,
    # Highlighting/Snippeting
    :attributes_to_highlight,
    :attributes_to_snippet,
    :highlight_pre_tag,
    :highlight_post_tag,
    :snippet_ellipsis_text,
    :restrict_highlight_and_snippet_arrays,
    # Pagination
    :hits_per_page,
    :pagination_limited_to,
    # Typos
    :min_word_sizefor1_typo,
    :min_word_sizefor2_typos,
    :typo_tolerance,
    :allow_typos_on_numeric_tokens,
    :disable_typo_tolerance_on_attributes,
    :disable_typo_tolerance_on_words,
    :separators_to_index,
    # Languages
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
    # Rules
    :enable_rules,
    # Personalization
    :enable_personalization,
    # Query strategy
    :query_type,
    :remove_words_if_no_results,
    :advanced_syntax,
    :optional_words,
    :disable_prefix_on_attributes,
    :disable_exact_on_attributes,
    :exact_on_single_word_query,
    :alternatives_as_exact,
    :advanced_syntax_features,
    # Performance
    :numeric_attributes_for_filtering,
    :allow_compression_of_integer_array,
    # Advanced
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

  @default_synonyms_settings [
    synonyms: [],
    forward_to_replicas: true,
    replace_existing_synonyms: true
  ]

  @synonyms_settings Keyword.keys(@default_synonyms_settings)

  def settings do
    @algolia_settings
  end

  def replica_settings(settings, replica_settings),
    do: replica_settings(%{}, settings, replica_settings)

  def replica_settings(module, settings, replica_settings) do
    replica_settings =
      case Keyword.get(replica_settings, :inherit, true) do
        true -> replica_settings ++ Utils.algolia_settings(module, settings)
        false -> replica_settings
      end

    map_algolia_settings(replica_settings)
  end

  def map_algolia_settings(algolia_settings) do
    Enum.into(@algolia_settings, %{}, fn setting ->
      {Utils.camelize(setting), Keyword.get(algolia_settings, setting)}
    end)
  end

  def synonyms_settings(module, settings, index_name) do
    case Utils.synonyms_settings(module, settings, index_name) do
      nil ->
        nil

      synonyms_settings ->
        @default_synonyms_settings
        |> Keyword.merge(synonyms_settings)
        |> Keyword.take(@synonyms_settings)
    end
  end

  def map_synonyms_settings(synonyms_settings) do
    @default_synonyms_settings
    |> Enum.into(%{}, fn {key, value} ->
      {Utils.camelize(key), Keyword.get(synonyms_settings, key, value)}
    end)
    |> then(fn settings ->
      {
        Map.get(settings, "synonyms", []),
        Map.drop(settings, ["synonyms"])
      }
    end)
  end
end
