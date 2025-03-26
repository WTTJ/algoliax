defmodule Algoliax.Config do
  @moduledoc false

  def api_key do
    Application.get_env(:algoliax, :api_key)
  end

  def application_id do
    Application.get_env(:algoliax, :application_id)
  end

  def cursor_field do
    Application.get_env(:algoliax, :cursor_field)
  end

  def env do
    Application.get_env(:algoliax, :env, "prod") |> String.to_atom()
  end
end
