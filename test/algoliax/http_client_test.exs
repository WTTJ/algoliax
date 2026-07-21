defmodule Algoliax.HttpClientTest do
  # async: false — mutates global application env
  use ExUnit.Case, async: false

  setup do
    original = Application.fetch_env(:algoliax, :http_client)

    on_exit(fn ->
      case original do
        {:ok, value} -> Application.put_env(:algoliax, :http_client, value)
        :error -> Application.delete_env(:algoliax, :http_client)
      end
    end)

    :ok
  end

  describe "impl/0" do
    test "returns the configured implementation" do
      Application.put_env(:algoliax, :http_client, Algoliax.Support.HttpClient)

      assert Algoliax.HttpClient.impl() == Algoliax.Support.HttpClient
    end

    test "raises a helpful error when no client is configured" do
      Application.delete_env(:algoliax, :http_client)

      assert_raise RuntimeError, ~r/No HTTP client configured for Algoliax/, fn ->
        Algoliax.HttpClient.impl()
      end
    end

    test "raises a distinct error when configured with a non-module value" do
      Application.put_env(:algoliax, :http_client, nil)

      assert_raise RuntimeError, ~r/Invalid HTTP client configured for Algoliax/, fn ->
        Algoliax.HttpClient.impl()
      end

      Application.put_env(:algoliax, :http_client, "not a module")

      assert_raise RuntimeError, ~r/Invalid HTTP client configured for Algoliax/, fn ->
        Algoliax.HttpClient.impl()
      end
    end
  end
end
