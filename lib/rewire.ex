defmodule Rewire do
  @moduledoc """
  """

  defmacro __using__(_) do
    quote do
      # Needed for importing the `rewire` macro.
      import Rewire
    end
  end

  defmacro rewire(rewire_expr) do
    %{aliases: aliases} = __CALLER__
    Rewire.Alias.rewire_alias(rewire_expr, [], aliases)
  end

  defmacro rewire(rewire_expr, do: block) do
    %{aliases: aliases} = __CALLER__
    Rewire.Block.rewire_block(rewire_expr, [], aliases, block)
  end

  defmacro rewire(rewire_expr, opts) do
    %{aliases: aliases} = __CALLER__
    Rewire.Alias.rewire_alias(rewire_expr, opts, aliases)
  end

  defmacro rewire(rewire_expr, opts, do: block) do
    %{aliases: aliases} = __CALLER__
    Rewire.Block.rewire_block(rewire_expr, opts, aliases, block)
  end
end
