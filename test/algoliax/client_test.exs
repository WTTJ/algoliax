defmodule Algoliax.ClientTest do
  use Algoliax.RequestCase

  test "test retries" do
    Application.put_env(:algoliax, :api_key, "api_key")

    Algoliax.Client.request(
      %{action: :get_object, url_params: [index_name: :index_name, object_id: "error"]},
      0
    )

    assert_request("GET", "/APPLICATION_ID/read/index_name/error", %{})
    assert_request("GET", "/APPLICATION_ID/retry/1/index_name/error", %{})
    assert_request("GET", "/APPLICATION_ID/retry/2/index_name/error", %{})
    assert_request("GET", "/APPLICATION_ID/retry/3/index_name/error", %{})
  end
end
