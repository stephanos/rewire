ExUnit.start()

defmodule Bonjour do
  def hello(), do: "bonjour"
end

defmodule AuRevoir do
  def bye(), do: "au revoir"
end

Mox.defmock(HelloMock, for: Rewire.Hello)

defmodule TestHelpers do
  import ExUnit.CaptureIO

  defmodule DidNotRaise, do: defstruct(description: nil)

  defmacro capture_compile_time_io(do: block) do
    capture_io(:stdio, fn ->
      Code.eval_quoted(block)
    end)
  end

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
      assert unquote(actual_exception.file)
      assert unquote(actual_exception.line)
    end
  end
end
