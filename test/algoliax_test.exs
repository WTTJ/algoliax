defmodule AlgoliaxTest do
  use ExUnit.Case, async: true

  alias Algoliax.Schemas.PeopleStruct

  setup do
    Algoliax.SettingsStore.set_settings(:algoliax_people, %{})
    :ok
  end

  test "People has algoliax_attr_ functions" do
    [
      :build_object,
      :to_be_indexed?
    ]
    |> Enum.each(fn f ->
      assert f in Keyword.keys(PeopleStruct.__info__(:functions))
    end)
  end

  test "People algolia_attr_ functions" do
    people = %PeopleStruct{reference: 10, last_name: "Doe", first_name: "John", age: 20}

    assert PeopleStruct.build_object(people) == %{
             age: 20,
             first_name: "John",
             full_name: "John Doe",
             last_name: "Doe",
             nickname: "john",
             updated_at: 1_546_300_800
           }

    refute PeopleStruct.to_be_indexed?(people)
  end

  test "People algolia_attr_ functions older than 50 " do
    people = %PeopleStruct{reference: 10, last_name: "Dark", first_name: "Vador", age: 55}

    assert PeopleStruct.build_object(people) == %{
             age: 55,
             first_name: "Vador",
             full_name: "Vador Dark",
             last_name: "Dark",
             nickname: "vador",
             updated_at: 1_546_300_800
           }

    assert PeopleStruct.to_be_indexed?(people)
  end

  describe "generate_secured_api_key/2" do
    test "should generate key if correct params" do
      assert {:ok, _} = Algoliax.generate_secured_api_key("api_key", %{filters: "reference:10"})
    end

    test "should return invalid params if api_key but invalid params" do
      assert {:error, "Invalid params"} =
               Algoliax.generate_secured_api_key("api_key", %{sdfsd: "reference:10"})
    end

    test "should return invalid api key if api_key not provided" do
      assert {:error, "Invalid api key"} =
               Algoliax.generate_secured_api_key(nil, %{sdfsd: "reference:10"})
    end

    test "should raise an InvalidApiKeyParamsError if no api_key provided" do
      assert_raise(Algoliax.InvalidApiKeyParamsError, "Invalid api key", fn ->
        Algoliax.generate_secured_api_key!(nil, %{filters: "reference:10"})
      end)
    end

    test "should raise an InvalidApiKeyParamsError if api key and invalid params" do
      assert_raise(Algoliax.InvalidApiKeyParamsError, "Invalid params", fn ->
        Algoliax.generate_secured_api_key!("api_key", %{sdfsd: "reference:10"})
      end)
    end
  end
end
