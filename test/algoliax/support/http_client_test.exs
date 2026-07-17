defmodule Algoliax.Support.HttpClientTest do
  use ExUnit.Case, async: true

  alias Algoliax.Support.HttpClient

  @mock_port System.get_env("API_MOCK_SERVER_PORT", "8002")

  describe "request/1" do
    test "returns {:ok, status, flattened_headers, raw_body} on a completed exchange" do
      # Hits the local Algoliax.ApiMockServer booted in test_helper.exs.
      result =
        HttpClient.request(
          method: :get,
          url: "http://localhost:#{@mock_port}/APPLICATION_ID/read/index_name/known",
          headers: [],
          body: nil,
          receive_timeout: 1000
        )

      assert {:ok, 200, headers, body} = result

      # normalize_headers/1 must flatten Req's %{name => [values]} map into a
      # flat list of {binary, binary} tuples — not {name, [values]}.
      assert Enum.all?(headers, fn h ->
               match?({k, v} when is_binary(k) and is_binary(v), h)
             end)

      # decode_body: false must keep the body a raw binary Algoliax decodes itself.
      assert is_binary(body)
      assert Jason.decode!(body) == %{"objectID" => "known"}
    end

    test "unwraps a Req transport failure into an {:error, reason} tuple" do
      # Port 1 is not listening, so Req raises a transport error that the
      # adapter must map to the behaviour's {:error, reason} contract.
      result =
        HttpClient.request(
          method: :get,
          url: "http://localhost:1/",
          headers: [],
          body: nil,
          receive_timeout: 100
        )

      assert {:error, reason} = result
      refute match?(%Req.TransportError{}, reason)
    end
  end

  describe "to_result/1" do
    test "passes a non-transport error through verbatim" do
      # The adapter's fixed options mean Req only returns TransportError over
      # the wire, so this defensive passthrough is covered directly rather than
      # via a live request.
      assert HttpClient.to_result({:error, :boom}) == {:error, :boom}
    end
  end
end
