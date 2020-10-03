defmodule Rewire.Block do
  @moduledoc """
  """

  import Rewire.Utils

  def rewire_block({:__aliases__, _, rewire_module_ast}, opts, aliases, block) do
    rewire_module_ast = resolve_alias(rewire_module_ast, aliases)
    new_module_ast = gen_new_module_ast(rewire_module_ast)
    rewire_module = "Elixir.#{module_ast_to_name(rewire_module_ast)}" |> String.to_atom()
    opts = parse_opts(opts, aliases) |> Map.put(:new_module_ast, new_module_ast)
    old_module_alias = Map.get(opts, :as, [List.last(rewire_module_ast)])

    quote do
      # First, we generate the rewired module.
      unquote(Rewire.Module.rewire_module(rewire_module, opts))

      # Then, we replace all references to the original module with our rewired one.
      unquote(rewire_test_block(block, old_module_alias, new_module_ast))
    end
  end

  def rewire_block(_expr, _opts, _block) do
    raise CompileError, description: "unable to rewire: the first argument must be a module"
  end

  defp rewire_test_block(block, old_module_alias, new_module_ast) do
    Macro.prewalk(block, fn
      {:__aliases__, meta, ^old_module_alias} ->
        {:__aliases__, meta, new_module_ast}

      expr ->
        expr
    end)
  end
end
