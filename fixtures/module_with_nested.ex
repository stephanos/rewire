defmodule Rewire.ModuleWithNested do
  defmodule RedHerring do
  end

  defmodule Nested do
    alias Rewire.ModuleWithNested.Nested.NestedNested
    @nested Rewire.ModuleWithNested.Nested.NestedNested

    def hello(), do: NestedNested.hello()
    def hello_with_property(), do: @nested.hello_with_property()

    defmodule NestedNested do
      @hello Application.compile_env!(:rewire, :hello)
      def hello(), do: Rewire.Hello.hello()
      def hello_with_property(), do: @hello.hello()
    end
  end

  defmodule AnotherRedHerring do
  end

  @nested Nested

  def hello(), do: Nested.hello()
  def hello_with_property(), do: @nested.hello_with_property()
end
