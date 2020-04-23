defmodule AlgoliaxTest do
  use ExUnit.Case, async: true

  import Mox
  alias Algoliax.Schemas.PeopleStruct

  setup :verify_on_exit!

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

  test "generate secured api key" do
    Application.put_env(:algoliax, :api_key, "api_key")
    assert Algoliax.generate_secured_api_key("reference:10")
  end
end
