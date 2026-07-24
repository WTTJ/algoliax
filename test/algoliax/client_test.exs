defmodule Algoliax.WrongShapeHttpClient do
  @moduledoc false
  @behaviour Algoliax.HttpClient

  # Signature-compatible with the behaviour, but returns the wrong success
  # shape (a Req-style {:ok, map} instead of the {:ok, status, headers, body}
  # 4-tuple the contract requires).
  @impl Algoliax.HttpClient
  def request(_opts), do: {:ok, %{status: 200, headers: [], body: "{}"}}
end

defmodule Algoliax.CapturingHttpClient do
  @moduledoc false
  @behaviour Algoliax.HttpClient

  # Sends the opts built by Algoliax.Client back to the test process so the
  # forwarded request options can be asserted directly.
  @impl Algoliax.HttpClient
  def request(opts) do
    send(:algoliax_capture_test, {:captured_opts, opts})
    {:ok, 200, [], "{}"}
  end
end

defmodule Algoliax.DecodedBodyHttpClient do
  @moduledoc false
  @behaviour Algoliax.HttpClient

  # Correctly-shaped 4-tuple with a valid 2xx status, but the body is a decoded
  # map instead of a raw binary — the classic "forgot decode_body: false" mistake.
  @impl Algoliax.HttpClient
  def request(_opts), do: {:ok, 200, [], %{"objectID" => "known"}}
end

defmodule Algoliax.TransportErrorHttpClient do
  @moduledoc false
  @behaviour Algoliax.HttpClient

  # Always reports a transport-level failure, so the Client-level retry loop
  # (host rotation, then give-up) is exercised end to end.
  @impl Algoliax.HttpClient
  def request(_opts), do: {:error, :econnrefused}
end

defmodule Algoliax.ClientTest do
  use Algoliax.RequestCase

  test "bodyless requests forward body: nil; requests with a body forward encoded JSON" do
    Process.register(self(), :algoliax_capture_test)
    original = Application.fetch_env(:algoliax, :http_client)
    Application.put_env(:algoliax, :http_client, Algoliax.CapturingHttpClient)
    Application.put_env(:algoliax, :api_key, "api_key")

    on_exit(fn -> restore(:http_client, original) end)

    # get_object never sets :body — it must be forwarded as nil, not "null".
    Algoliax.Client.request(
      %{action: :get_object, url_params: [index_name: :index_name, object_id: "known"]},
      0
    )

    assert_receive {:captured_opts, bodyless_opts}
    assert bodyless_opts[:body] == nil

    # A request that carries a body must forward it JSON-encoded.
    Algoliax.Client.request(
      %{
        action: :get_object,
        url_params: [index_name: :index_name, object_id: "known"],
        body: %{"foo" => "bar"}
      },
      0
    )

    assert_receive {:captured_opts, body_opts}
    assert body_opts[:body] == Jason.encode!(%{"foo" => "bar"})
  end

  test "forwards the configured :receive_timeout to the client" do
    Process.register(self(), :algoliax_capture_test)
    original_client = Application.fetch_env(:algoliax, :http_client)
    original_timeout = Application.fetch_env(:algoliax, :recv_timeout)
    Application.put_env(:algoliax, :http_client, Algoliax.CapturingHttpClient)
    Application.put_env(:algoliax, :api_key, "api_key")
    # A non-default value so the assertion can't pass by coincidence with the
    # 5000 default — proves the value is read from config and forwarded.
    Application.put_env(:algoliax, :recv_timeout, 1234)

    on_exit(fn ->
      restore(:http_client, original_client)
      restore(:recv_timeout, original_timeout)
    end)

    Algoliax.Client.request(
      %{action: :get_object, url_params: [index_name: :index_name, object_id: "known"]},
      0
    )

    assert_receive {:captured_opts, opts}
    assert opts[:receive_timeout] == 1234
  end

  test "a non-conforming http_client return raises instead of silently retrying" do
    original = Application.fetch_env(:algoliax, :http_client)
    Application.put_env(:algoliax, :http_client, Algoliax.WrongShapeHttpClient)
    Application.put_env(:algoliax, :api_key, "api_key")

    on_exit(fn -> restore(:http_client, original) end)

    assert_raise Algoliax.HttpClientContractError, fn ->
      Algoliax.Client.request(
        %{action: :get_object, url_params: [index_name: :index_name, object_id: "known"]},
        0
      )
    end
  end

  test "a well-shaped response with a non-binary body raises the contract error, not a decode crash" do
    original = Application.fetch_env(:algoliax, :http_client)
    Application.put_env(:algoliax, :http_client, Algoliax.DecodedBodyHttpClient)
    Application.put_env(:algoliax, :api_key, "api_key")

    on_exit(fn -> restore(:http_client, original) end)

    assert_raise Algoliax.HttpClientContractError, ~r/must be a raw binary/, fn ->
      Algoliax.Client.request(
        %{action: :get_object, url_params: [index_name: :index_name, object_id: "known"]},
        0
      )
    end
  end

  test "a transport {:error, reason} return is retried and gives up after 3 attempts" do
    original = Application.fetch_env(:algoliax, :http_client)
    Application.put_env(:algoliax, :http_client, Algoliax.TransportErrorHttpClient)
    Application.put_env(:algoliax, :api_key, "api_key")

    on_exit(fn -> restore(:http_client, original) end)

    assert Algoliax.Client.request(
             %{action: :get_object, url_params: [index_name: :index_name, object_id: "known"]},
             0
           ) == {:error, "Failed after 3 attempts"}
  end

  test "test retries" do
    Application.put_env(:algoliax, :api_key, "api_key")

    Algoliax.Client.request(
      %{action: :get_object, url_params: [index_name: :index_name, object_id: "error"]},
      0
    )

    assert_request("GET", %{path: "/APPLICATION_ID/read/index_name/error", body: %{}})
    assert_request("GET", %{path: "/APPLICATION_ID/retry/1/index_name/error", body: %{}})
    assert_request("GET", %{path: "/APPLICATION_ID/retry/2/index_name/error", body: %{}})
    assert_request("GET", %{path: "/APPLICATION_ID/retry/3/index_name/error", body: %{}})
  end

  test "Error http" do
    Application.put_env(:algoliax, :api_key, "api_key_invalid")

    message = """
    Algolia HTTP error:

    403 : Index not allowed with this API key
    """

    assert_raise(Algoliax.AlgoliaApiError, message, fn ->
      Algoliax.Client.request(
        %{
          action: :get_object,
          url_params: [index_name: :index_name_not_authorized, object_id: "Whatever"]
        },
        0
      )
    end)
  end

  defp restore(key, original) do
    case original do
      {:ok, value} -> Application.put_env(:algoliax, key, value)
      :error -> Application.delete_env(:algoliax, key)
    end
  end
end
