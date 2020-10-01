defmodule Rewire do
  @moduledoc """
  """

  defmacro __using__(_) do
    quote do
      # Module attribute to collect module's aliases.
      Module.register_attribute(__MODULE__, :rewire_aliases, accumulate: false, persist: false)

      # Hook to keep track of functions and their aliases.
      @on_definition Rewire.Block

      # Required for importing the `rewire` macro.
      import Rewire
    end
  end

  defmacro rewire(rewire_expr, opts, do: block) do
    aliases = Module.get_attribute(__CALLER__.module, :rewire_aliases) || []
    Rewire.Block.rewire_block(rewire_expr, opts, aliases, block)
  end

  defmacro rewire(rewire_expr, do: block) do
    aliases = Module.get_attribute(__CALLER__.module, :rewire_aliases) || []
    Rewire.Block.rewire_block(rewire_expr, [], aliases, block)
  end
end
