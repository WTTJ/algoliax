defmodule Algoliax.Config do
  @moduledoc false

  def api_key do
    System.get_env("ALGOLIA_API_KEY") || Application.get_env(:algoliax, :api_key)
  end

  def application_id do
    System.get_env("ALGOLIA_APPLICATION_ID") || Application.get_env(:algoliax, :application_id)
  end

  def cursor_field do
    Application.get_env(:algoliax, :cursor_field)
  end
end
