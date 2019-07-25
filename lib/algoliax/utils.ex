defmodule Algoliax.Utils do
  @moduledoc false

  @attribute_prefix "algoliax_attr_"

  def prefix_attribute(attribute) do
    :"#{@attribute_prefix}#{attribute}"
  end

  def unprefix_attribute(attribute) do
    attribute
    |> Atom.to_string()
    |> String.replace(@attribute_prefix, "")
    |> String.to_atom()
  end

  def index_name(settings) do
    index_name = Keyword.get(settings, :index_name)

    if index_name do
      index_name
    else
      raise "No index_name configured"
    end
  end

  def repo(settings) do
    repo = Keyword.get(settings, :repo)

    if repo do
      repo
    else
      raise "No repo configured"
    end
  end
end
