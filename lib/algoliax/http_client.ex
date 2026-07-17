defmodule Algoliax.HttpClient do
  @moduledoc """
  Behaviour for the HTTP client used by Algoliax to talk to the Algolia API.

  Algoliax ships **no** HTTP client of its own. Each application using Algoliax
  provides its own implementation and configures it:

      config :algoliax, :http_client, MyApp.AlgoliaHttpClient

  This keeps you free to use whichever HTTP library you already depend on
  (`Req`, `Finch`, `hackney`, `:httpc`, ...).

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

  Raises a helpful error if none is configured.
  """
  @spec impl() :: module()
  def impl do
    case Application.fetch_env(:algoliax, :http_client) do
      {:ok, module} ->
        module

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
