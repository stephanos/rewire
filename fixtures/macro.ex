defmodule Rewire.Macro do
  defmacro __using__(_opts) do
    quote do
      import Rewire.Hello
    end
  end
end
