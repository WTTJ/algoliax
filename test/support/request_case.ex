defmodule Algoliax.RequestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Algoliax.Assertions
    end
  end

  setup do
    Algoliax.RequestsStore.clean()

    :ok
  end
end
