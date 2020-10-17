defmodule Rewire.Block do
  @moduledoc false

  def rewire_block(
        opts = %{
          old_module_ast: old_module_ast,
          module_shorthand: module_shorthand,
          new_module_ast: new_module_ast
        },
        block
      ) do
    quote do
      # First, we generate the rewired module.
      unquote(Rewire.Module.rewire_module(old_module_ast, opts))

      # Then, we replace all references to the original module with our rewired one.
      unquote(rewire_test_block(block, module_shorthand, new_module_ast))
    end
  end

  defp rewire_test_block(block, module_shorthand, new_module_ast) do
    Macro.prewalk(block, fn
      {:__aliases__, meta, [^module_shorthand]} ->
        {:__aliases__, meta, new_module_ast}

      expr ->
        expr
    end)
  end
end
