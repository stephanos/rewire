defmodule Rewire.ModuleWithNested do
  def hello(), do: Rewire.ModuleWithNested.Nested.hello()

  defmodule Nested do
    alias Rewire.ModuleWithNested.Nested.NestedNested

    def hello(), do: NestedNested.hello()

    defmodule NestedNested do
      def hello(), do: "hello"
    end
  end
end
