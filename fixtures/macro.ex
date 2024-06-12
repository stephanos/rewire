defmodule Rewire.Macro do
  defmacro __using__(_opts) do
    quote do
      import Rewire.Hello
      import Rewire.Goodbye
    end
  end

  # defmacro __using__(opts) do
  #   case opts do
  #     [] ->
  #       quote do
  #         import Rewire.Hello
  #       end

  #     _ ->
  #       quote do
  #         import Rewire.Hello, only: [hello: 0]
  #       end
  #   end
  # end
end
