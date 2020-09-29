defmodule Rewire.ModuleWithNested do
  defmodule Nested do
    defmodule NestedNested do
      def hello(), do: "hello"
    end
  end
end
