defmodule Rewire.ModuleWithNested do
  defmodule RedHerring do
  end

  defmodule Nested do
    alias Rewire.ModuleWithNested.Nested.NestedNested

    def hello(), do: NestedNested.hello()

    defmodule NestedNested do
      def hello(), do: Rewire.Hello.hello()
    end
  end

  defmodule AnotherRedHerring do
  end

  def hello(), do: Nested.hello()
end
