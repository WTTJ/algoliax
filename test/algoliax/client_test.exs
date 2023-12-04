defmodule Algoliax.ClientTest do
  use Algoliax.RequestCase

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
end
