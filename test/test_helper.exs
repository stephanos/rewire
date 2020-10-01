ExUnit.start()

Mox.defmock(Rewire.HelloMock, for: Rewire.Hello)

defmodule Assertions do
  defmodule DidNotRaise, do: defstruct(description: nil)

  defmacro assert_compile_time_raise(expected_message, do: block) do
    actual_exception =
      try do
        Code.eval_quoted(block)
        %DidNotRaise{}
      rescue
        e -> e
      end

    quote do
      assert unquote(actual_exception.__struct__) == unquote(CompileError)
      assert unquote(actual_exception.description) == unquote(expected_message)
    end
  end
end
