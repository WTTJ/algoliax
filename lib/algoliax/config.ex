defmodule Algoliax.Config do
  @moduledoc false

  def api_key do
    Application.get_env(:algoliax, :api_key)
  end

  def api_key(credenital_name) do
    :algoliax
    |> Application.get_env(:credentials, [])
    |> Map.fetch(credenital_name)
    |> then(fn
      {:ok, {_application_id, api_key}} -> api_key
      :error -> raise Algoliax.InvalidAlgoliaCredentialsError, %{name: inspect(credenital_name)}
    end)
  end

  def application_id do
    Application.get_env(:algoliax, :application_id)
  end

  def application_id(credenital_name) do
    :algoliax
    |> Application.get_env(:credentials, [])
    |> Map.fetch(credenital_name)
    |> then(fn
      {:ok, {application_id, _api_key}} -> application_id
      :error -> raise Algoliax.InvalidAlgoliaCredentialsError, %{name: inspect(credenital_name)}
    end)
  end

  def cursor_field do
    Application.get_env(:algoliax, :cursor_field)
  end
end
