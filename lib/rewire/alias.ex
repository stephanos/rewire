defmodule Rewire.Alias do
  @moduledoc """
  """

  import Rewire.Utils

  def rewire_alias({:__aliases__, _, rewire_module_ast}, opts, aliases) do
    rewire_module_ast = resolve_alias(rewire_module_ast, aliases)
    new_module_ast = gen_new_module_ast(rewire_module_ast)
    rewire_module = "Elixir.#{module_ast_to_name(rewire_module_ast)}" |> String.to_atom()
    opts = parse_opts(opts, aliases) |> Map.put(:new_module_ast, new_module_ast)

    quote do
      # First, we generate the rewired module.
      unquote(Rewire.Module.rewire_module(rewire_module, opts))

      # Then, we add an alias for the newly generated module using the name of the original module.
      unquote(
        {:alias, [context: Elixir], [
          {:__aliases__, [alias: false], new_module_ast},
          [as: {:__aliases__, [alias: false], [Map.get(opts, :as, List.last(rewire_module_ast))]}]
        ]}
      )
    end
  end
end
