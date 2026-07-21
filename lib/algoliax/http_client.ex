defmodule Algoliax.HttpClient do
  @moduledoc """
  Behaviour for the HTTP client used by Algoliax to talk to the Algolia API.

  Algoliax ships **no** HTTP client of its own. Each application using Algoliax
  provides its own implementation and configures it:

      config :algoliax, :http_client, MyApp.AlgoliaHttpClient

  This keeps you free to use whichever HTTP library you already depend on
  (`Req`, `Finch`, `hackney`, `:httpc`, ...).

  > #### Verify TLS certificates {: .warning}
  >
  > Algoliax sends your Algolia API key as a header on every request. Make sure
  > your implementation verifies TLS certificates. `Req`/`Finch`/`Mint` do so by
  > default, but Erlang's `:httpc`/`:ssl` default to `verify_none` — if you build
  > an adapter on those, pass `ssl: [verify: :verify_peer, ...]` explicitly.

  ## Implementing the behaviour

      defmodule MyApp.AlgoliaHttpClient do
        @behaviour Algoliax.HttpClient

        @impl Algoliax.HttpClient
        def request(opts) do
          # perform the HTTP call described by `opts`
          {:ok, status, headers, body}
        end
      end

  ## Supported options

  The `opts` keyword list passed to `request/1` contains at minimum:

    * `:method` - HTTP verb as an atom (`:get`, `:post`, `:put`, `:delete`)
    * `:url` - full URL string (query parameters already appended)
    * `:headers` - list of `{name, value}` tuples
    * `:body` - request body as a binary (already JSON-encoded by Algoliax), or `nil`
    * `:receive_timeout` - response timeout in milliseconds

  Unknown options should be silently ignored.

  ## Retries and redirects

  Implementations **must disable any retry and redirect-following** their
  underlying HTTP library performs by default:

    * Algoliax already retries transport failures itself, rotating to a
      different Algolia host on each attempt. A client that also retries would
      hammer the same already-failed host instead of letting Algoliax rotate.
    * Algoliax routes `3xx`/`4xx` status codes to its own error handling, so a
      client that transparently follows redirects would hide those responses.

  The shipped reference adapter does this with `Req`'s `retry: false` and
  `redirect: false` options; use the equivalent for your library.

  ## Return value

  On a completed HTTP exchange (any status code), return:

      {:ok, status :: non_neg_integer(), headers :: [{String.t(), String.t()}], body :: binary()}

  The body is always a **raw binary** — Algoliax decodes the JSON itself.

  On a transport-level failure (connection refused, timeout, DNS error), return:

      {:error, reason :: term()}

  Algoliax retries transport failures against Algolia's retry hosts.

  > #### Contract compatibility {: .info}
  >
  > The `request/1` contract intentionally mirrors a generic
  > `{:ok, status, headers, body}` / `{:error, reason}` shape, so an existing
  > shared HTTP-client behaviour with the same signature can be configured
  > directly.
  """

  @type method :: :get | :post | :put | :delete

  @type opts :: [
          method: method(),
          url: String.t(),
          headers: [{String.t(), String.t()}],
          body: binary() | nil,
          receive_timeout: non_neg_integer()
        ]

  @type result ::
          {:ok, status :: non_neg_integer(), headers :: [{String.t(), String.t()}],
           body :: binary()}
          | {:error, reason :: term()}

  @callback request(opts()) :: result()

  @doc """
  Returns the configured HTTP client implementation.

  Raises a helpful error if none is configured, or if the configured value is
  not a module.
  """
  @spec impl() :: module()
  def impl do
    case Application.fetch_env(:algoliax, :http_client) do
      {:ok, module} when is_atom(module) and not is_nil(module) ->
        module

      {:ok, other} ->
        raise """
        Invalid HTTP client configured for Algoliax.

        Expected a module implementing the `Algoliax.HttpClient` behaviour, got:

            #{inspect(other)}

        Configure it like:

            config :algoliax, :http_client, MyApp.AlgoliaHttpClient

        See the `Algoliax.HttpClient` documentation for the expected contract.
        """

      :error ->
        raise """
        No HTTP client configured for Algoliax.

        Algoliax no longer ships an HTTP client. Configure a module implementing
        the `Algoliax.HttpClient` behaviour:

            config :algoliax, :http_client, MyApp.AlgoliaHttpClient

        See the `Algoliax.HttpClient` documentation for the expected contract.
        """
    end
  end
end
