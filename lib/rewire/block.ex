defmodule Rewire.Block do
  @moduledoc """
  """

  import Rewire.Utils

  def __on_definition__(env = %{aliases: module_aliases}, _kind, _name, _args, _guards, _body) do
    known_aliases = Module.get_attribute(env.module, :rewire_aliases) || []

    # Storing the module's aliases in the module attribute.
    known_aliases = Keyword.merge(known_aliases, module_aliases)

    # Storing the test's aliases in the module attribute.
    # TODO

    Module.put_attribute(env.module, :rewire_aliases, known_aliases)
  end

  def rewire_block(rewire_expr = {:__aliases__, _, rewire_module_ast}, opts, aliases, block) do
    # This ID is used to generate a random module name. It has to start with an uppercase letter.
    context_id = "R#{Enum.random(0..10_000)}" |> String.to_atom()

    # We need to define the new module name here because
    # it's required to rewrite the test's module references at compile-time.
    new_module_ast = resolve_alias(rewire_module_ast, aliases) ++ [context_id]

    quote do
      # First, the module needs to be actually rewired.
      # This happens at runtime so we'll inject the call to do so right here.
      Rewire.rewire_module(
        unquote(rewire_expr),
        unquote(Keyword.put(opts, :new_module_ast, new_module_ast))
      )

      # Then, we'll replace all references to the original module with our rewired one.
      # We can do that because we already know the name of it ahead of time.
      unquote(rewire_test_block(block, rewire_module_ast, new_module_ast))
    end
  end

  def rewire_block(_expr, _opts, _block) do
    raise "unable to rewire: the first argument must be a module"
  end

  defp rewire_test_block(block, rewire_module_ast, new_module_ast) do
    Macro.prewalk(block, fn
      {:__aliases__, meta, module_ast} when module_ast == rewire_module_ast ->
        {:__aliases__, meta, new_module_ast}

      expr ->
        expr
    end)
  end
end
