defmodule Algoliax do
  @moduledoc """
  Algoliax is wrapper for Algolia api

  ### Example

  ```elixir
  defmodule People do
    use Algoliax,
      index_name: :people,
      attribute_for_faceting: ["age"],
      custom_ranking: ["desc(update_at)"],
      object_id: :reference

    defstruct reference: nil, last_name: nil, first_name: nil, age: nil

    attributes([:first_name, :last_name, :age])

    attribute(:updated_at, ~U[2019-07-18 08:45:56.639380Z] |> DateTime.to_unix())

    attribute :full_name do
      Map.get(model, :first_name, "") <> " " <> Map.get(model, :last_name, "")
    end

    attribute :nickname do
      Map.get(model, :first_name, "") |> String.downcase()
    end
  end
  ```
  """
  alias Algoliax.Resources.{Index, Object}
  alias Algoliax.{Config, Utils}

  @doc """
  Save object
  """
  @callback save_object(model :: map()) :: :ok | :error

  @doc """
  Save multiple object
  """
  @callback save_objects(models :: list()) :: :ok | :error

  @doc """
  Get an object
  """
  @callback get_object(model :: map()) :: :ok | :error

  @doc """
  Reindex atomicly
  """
  @callback reindex(query :: any()) :: :ok | :error

  @doc """
  Reindex atomicly
  """
  @callback reindex_atomic() :: :ok | :error

  @doc """
  Check if current object can be indexed
  """
  @callback to_be_indexed?(model :: map()) :: true | false

  @doc """
  Configure index
  """
  @callback configure_index() :: :ok | :error

  @doc """
  Delete index
  """
  @callback delete_index() :: :ok | :error

  defmacro __using__(settings) do
    quote do
      @behaviour Algoliax

      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :index_attributes, accumulate: true)

      settings = unquote(settings)
      @settings settings

      @before_compile unquote(__MODULE__)

      def get_settings do
        Index.get_settings(@settings)
      end

      def configure_index do
        Index.configure_index(@settings)
      end

      def delete_index do
        Index.delete_index(@settings)
      end

      def to_be_indexed?(model) do
        true
      end

      defoverridable(to_be_indexed?: 1)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def save_objects(models, opts \\ []) do
        Object.save_objects(
          @settings,
          __MODULE__,
          models,
          @index_attributes,
          opts
        )
      end

      def save_object(model) do
        apply(__MODULE__, :to_be_indexed?, [model])
        Object.save_object(@settings, __MODULE__, model, @index_attributes)
      end

      def delete_object(model) do
        Object.delete_object(@settings, __MODULE__, model, @index_attributes)
      end

      def get_object(model) do
        Object.get_object(@settings, __MODULE__, model, @index_attributes)
      end

      def reindex(query \\ nil) do
        Object.reindex(@settings, __MODULE__, @index_attributes, query)
      end

      def reindex_atomic do
        Object.reindex_atomic(@settings, __MODULE__, @index_attributes)
      end
    end
  end

  @doc """
  Define an attibutes to index with a static or computed value with access to the current model to index

  ```elixir
  attribute :utc_now, DateTime.utc_now()
  ```

  ```elixir
  attribute :uppcase_name do
    model.name |> String.upcase()
  end
  ```
  """
  defmacro attribute(attribute_name, do: block) do
    method_attribute_name = Utils.prefix_attribute(attribute_name)

    quote do
      @index_attributes unquote(method_attribute_name)
      def unquote(method_attribute_name)(model) do
        var!(model) = model
        unquote(block)
      end
    end
  end

  defmacro attribute(attribute_name, value) do
    method_attribute_name = Utils.prefix_attribute(attribute_name)

    quote do
      @index_attributes unquote(method_attribute_name)
      def unquote(method_attribute_name)(model) do
        unquote(value)
      end
    end
  end

  @doc """
  Define an attibute to index with a value taken from the model (map/struct)
  ```elixir
  attribute :id
  ```
  """
  defmacro attribute(attribute_name) do
    Algoliax.build_attribute(attribute_name)
  end

  @doc """
  Define multiple attibutes to index with a value taken from the model (map/struct)
    ```elixir
  attributes :id, :inserted_at
  ```
  """
  defmacro attributes(attribute_names) do
    Enum.map(attribute_names, fn attribute_name ->
      Algoliax.build_attribute(attribute_name)
    end)
  end

  @doc """
  Define multiple attibutes to index with a value taken from the model (map/struct)
    ```elixir
  attributes :id, :inserted_at
  ```
  """
  @spec generate_secured_api_key(filters :: list()) :: binary()
  def generate_secured_api_key(filters) do
    query_string = "filters=#{URI.encode_www_form("#{filters}")}"

    hmac =
      :crypto.hmac(
        :sha256,
        Config.api_key(),
        query_string
      )
      |> Base.encode16(case: :lower)

    Base.encode64(hmac <> query_string)
  end

  @doc false
  def build_attribute(attribute_name) do
    method_attribute_name = Utils.prefix_attribute(attribute_name)

    quote do
      @index_attributes unquote(method_attribute_name)
      def unquote(method_attribute_name)(model) do
        Map.get(model, unquote(attribute_name))
      end
    end
  end
end
