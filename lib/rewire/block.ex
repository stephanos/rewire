defmodule Rewire.Block do
  @moduledoc """
  """

  import Rewire.Utils

  def __on_definition__(env = %{aliases: module_aliases}, _kind, _name, _args, _guards, _body) do
    known_aliases = Module.get_attribute(env.module, :rewire_aliases) || []

    # Adding the module's aliases in the module attribute.
    known_aliases = Keyword.merge(known_aliases, module_aliases)

    # Adding the function's aliases in the module attribute.
    # TODO

    Module.put_attribute(env.module, :rewire_aliases, known_aliases)
  end

  def rewire_block({:__aliases__, _, rewire_module_ast}, opts, aliases, block) do
    rewire_module_ast = resolve_alias(rewire_module_ast, aliases)
    rewire_module = "Elixir.#{module_ast_to_name(rewire_module_ast)}" |> String.to_atom()

    # Determine generated module's name. It has to be a unique name.
    context_id = "R#{Enum.random(0..10_000)}" |> String.to_atom()
    new_module_ast = rewire_module_ast ++ [context_id]
    opts = parse_opts(opts, aliases) |> Map.put(:new_module_ast, new_module_ast)

    quote do
      # First, we're generating the rewired module.
      unquote(Rewire.Module.rewire_module(rewire_module, opts))

      # Then, we'll replace all references to the original module with our rewired one.
      unquote(rewire_test_block(block, rewire_module_ast, new_module_ast, aliases))
    end
  end

  def rewire_block(_expr, _opts, _block) do
    raise CompileError, description: "unable to rewire: the first argument must be a module"
  end

  defp rewire_test_block(block, rewire_module_ast, new_module_ast, aliases) do
    Macro.prewalk(block, fn
      expr = {:__aliases__, meta, module_ast} ->
        cond do
          resolve_alias(module_ast, aliases) == rewire_module_ast ->
            {:__aliases__, meta, new_module_ast}

          true ->
            expr
        end

      expr ->
        expr
    end)
  end

  defp parse_opts(opts, aliases) do
    Enum.reduce(opts, %{overrides: %{}}, fn
      # Here the module to replace and the replacement are defined as fully-quallified aliases.
      {{:__aliases__, _, module_ast}, {:__aliases__, _, replacement_module_ast}}, acc ->
        put_in(acc, [:overrides, module_ast], resolve_alias(replacement_module_ast, aliases))

      # Here the module to replace is just an atom, ie in shorthand form.
      {k, {:__aliases__, _, replacement_module_ast}}, acc when is_atom(k) ->
        put_in(
          acc,
          [:overrides, module_to_ast(k)],
          resolve_alias(replacement_module_ast, aliases)
        )

      {k, _}, _acc ->
        raise CompileError, description: "unknown option passed to `rewire`: #{inspect(k)}"
    end)
  end
end
