defmodule Rewire.Macro do
  defmacro __using__(opts) do
    case opts do
      [use_alias: true] ->
        quote do
          alias Rewire.Hello
          alias Rewire.Macro
        end

      _ ->
        quote do
          import Rewire.Hello
          import Rewire.Macro
        end
    end
  end

  def good_afternoon do
    "good afternoon"
  end
end
