defmodule Rewire.Macro do
  defmacro __using__(opts) do
    case opts do
      [use_alias: true] ->
        quote do
          alias Rewire.Hello
        end

      _ ->
        quote do
          import Rewire.Hello
        end
    end
  end
end
