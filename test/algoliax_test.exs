defmodule AlgoliaxTest do
  use ExUnit.Case, async: true

  import Mox
  alias Algoliax.Schemas.PeopleStruct

  setup :verify_on_exit!

  setup do
    Algoliax.Agent.set_settings(:algoliax_people, %{})
    :ok
  end

  test "People has algoliax_attr_ functions" do
    [
      :algoliax_attr_age,
      :algoliax_attr_first_name,
      :algoliax_attr_full_name,
      :algoliax_attr_last_name,
      :algoliax_attr_nickname,
      :algoliax_attr_updated_at
    ]
    |> Enum.each(fn f ->
      assert f in Keyword.keys(PeopleStruct.__info__(:functions))
    end)
  end

  test "People algolia_attr_ functions" do
    people = %PeopleStruct{reference: 10, last_name: "Doe", first_name: "John", age: 20}

    assert PeopleStruct.algoliax_attr_age(people) == 20
    assert PeopleStruct.algoliax_attr_first_name(people) == "John"
    assert PeopleStruct.algoliax_attr_full_name(people) == "John Doe"
    assert PeopleStruct.algoliax_attr_last_name(people) == "Doe"
    assert PeopleStruct.algoliax_attr_nickname(people) == "john"
    assert PeopleStruct.algoliax_attr_updated_at(people) == 1_546_300_800
    refute PeopleStruct.to_be_indexed?(people)
  end

  test "People algolia_attr_ functions older than 50 " do
    people = %PeopleStruct{reference: 10, last_name: "Doe", first_name: "John", age: 55}

    assert PeopleStruct.algoliax_attr_age(people) == 55
    assert PeopleStruct.algoliax_attr_first_name(people) == "John"
    assert PeopleStruct.algoliax_attr_full_name(people) == "John Doe"
    assert PeopleStruct.algoliax_attr_last_name(people) == "Doe"
    assert PeopleStruct.algoliax_attr_nickname(people) == "john"
    assert PeopleStruct.algoliax_attr_updated_at(people) == 1_546_300_800
    assert PeopleStruct.to_be_indexed?(people)
  end

  test "generate secured api key" do
    Application.put_env(:algoliax, :api_key, "api_key")
    assert Algoliax.generate_secured_api_key("reference:10")
  end
end
