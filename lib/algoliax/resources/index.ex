defmodule Algoliax.Resources.Index do
  @moduledoc false

  alias Algoliax.{Agent, Utils, Config}

  @algolia_settings [
    :searchable_attributes,
    :attributes_for_faceting,
    :unretrievable_attributes,
    :attributes_to_retrieve,
    :ranking,
    :custom_ranking,
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
    :remove_stop_words,
    :camel_case_attributes,
    :decompounded_attributes,
    :keep_diacritics_on_characters,
    :query_languages,
    :enable_rules,
    :query_type,
    :remove_words_if_no_results,
    :advanced_syntax,
    :optional_words,
    :disable_prefix_on_attributes,
    :disable_exact_on_attributes,
    :exact_on_single_word_query,
    :alternatives_as_exact,
    :numeric_attributes_for_filtering,
    :allow_compression_of_integer_array,
    :numeric_attributes_to_index,
    :attribute_for_distinct,
    :distinct,
    :replace_synonyms_in_highlight,
    :min_proximity,
    :response_fields,
    :max_facet_hits,
    :synonyms,
    :placeholders,
    :alt_corrections
  ]

  def ensure_settings(settings) do
    index_name = Utils.index_name(settings)

    case Agent.get_settings(index_name) do
      nil ->
        configure_index(settings)
        get_settings(settings)

      _ ->
        true
    end
  end

  def get_settings(settings) do
    index_name = Utils.index_name(settings)
    algolia_remote_settings = Config.client_http().get_settings(index_name)
    Agent.set_settings(index_name, algolia_remote_settings)
    algolia_remote_settings
  end

  def configure_index(settings) do
    index_name = Utils.index_name(settings)

    algolia_settings =
      @algolia_settings
      |> Enum.into(%{}, fn setting ->
        value = Keyword.get(settings, setting)

        setting =
          setting
          |> Atom.to_string()
          |> Inflex.camelize(:lower)

        {setting, value}
      end)

    Config.client_http().configure_index(index_name, algolia_settings)
  end

  def delete_index(settings) do
    index_name = Utils.index_name(settings)
    Config.client_http().delete_index(index_name)
  end
end
