defmodule Rewire.Module do
  @moduledoc """
  """

  import Rewire.Utils

  def rewire_module(mod, opts) do
    # We need to make sure that the module to rewire actually exists first.
    if Code.ensure_compiled(mod) == {:error, :nofile} do
      raise CompileError,
        description:
          "unable to rewire '#{module_to_name(mod)}': cannot find module - does it exist?"
    end

    # Find module's source file path.
    source_path =
      mod.module_info()
      |> Keyword.get(:compile)
      |> Keyword.get(:source)
      |> to_string()

    # Load module's AST.
    source = File.read!(source_path)
    {:ok, ast} = Code.string_to_quoted(source)

    # Create a copy of the AST with a new module name and replaced dependencies.
    old_mod_name = mod |> Atom.to_string() |> String.trim_leading("Elixir.")
    new_mod_name = Map.fetch!(opts, :new_module_ast) |> module_ast_to_name()

    new_ast =
      traverse(
        ast,
        module_name_to_ast(old_mod_name),
        module_name_to_ast(new_mod_name),
        opts
      )

    # Now evaluate the new module's AST so the file location is correct. (is there a better way?)
    Code.eval_quoted(new_ast, [], file: source_path)
    "Elixir.#{new_mod_name}" |> String.to_atom()
  end

  defp traverse(ast, old_module_ast, new_module_ast, opts) do
    acc =
      %{
        overrides: %{},
        overrides_completed: [],
        parent_module_ast: [],
        old_module_ast: old_module_ast,
        new_module_ast: new_module_ast
      }
      |> Map.merge(opts)

    pre = fn expr, acc -> rewrite(expr, acc) end
    post = fn expr, acc -> {expr, acc} end
    {new_ast, new_acc} = Macro.traverse(ast, acc, pre, post)

    %{overrides: overrides} = acc
    %{overrides_completed: overrides_completed} = new_acc
    report_broken_overrides(old_module_ast, Map.keys(overrides), overrides_completed)

    new_ast
  end

  # Changes the rewired module's name to prevent a naming collision.
  defp rewrite(
         {:defmodule, l1, [{:__aliases__, l2, module_ast} | rest]},
         acc = %{
           old_module_ast: old_module_ast,
           new_module_ast: new_module_ast,
           parent_module_ast: parent_module_ast
         }
       ) do
    full_module_ast = parent_module_ast ++ module_ast

    cond do
      full_module_ast == old_module_ast ->
        # We found the module to rewire,
        # let's generate a new one with a unique name.
        {{:defmodule, l1, [{:__aliases__, l2, new_module_ast} | rest]}, acc}

      List.starts_with?(full_module_ast, old_module_ast) ->
        # We found a nested module within the module to rewrite,
        # let's rewire that one too since it might contain references to the parent module.
        # TODO
        {[], acc}

      List.starts_with?(old_module_ast, full_module_ast) ->
        # We (possibly) found a wrapper module around the module to rewrite,
        # let's look ahead to find the nested module so we can skip the rest.
        # TODO
        {[], acc}

      true ->
        # Skip module entirely because it would just be redefined, causing a warning.
        {[], acc}
    end
  end

  # Removes the rewired module's aliases that point to the replaced modules.
  defp rewrite(
         expr = {:alias, _, [{:__aliases__, _, module_ast}]},
         acc = %{overrides: overrides}
       ) do
    case find_override(overrides, module_ast) do
      nil -> {expr, acc}
      _ -> {[], acc}
    end
  end

  defp rewrite(
         {:alias, _, [{{:., _, [{:__aliases__, _, root_module_ast}, :{}]}, _, aliases}]},
         acc
       ) do
    Enum.reduce(aliases, {[], acc}, fn {:__aliases__, l1, child_module_ast}, {exprs, acc} ->
      full_module_ast = root_module_ast ++ child_module_ast
      {new_expr, acc} = rewrite({:alias, l1, [{:__aliases__, l1, full_module_ast}]}, acc)
      {[new_expr | exprs], acc}
    end)
  end

  # Replaces any rewired module's references to point to mocks instead.
  defp rewrite(
         expr = {:__aliases__, l1, module_ast},
         acc = %{overrides: overrides, overrides_completed: overrides_completed}
       ) do
    case find_override(overrides, module_ast) do
      nil ->
        {expr, acc}

      {identifier, new_ast} ->
        {{:__aliases__, l1, new_ast},
         %{acc | overrides_completed: [identifier | overrides_completed]}}
    end
  end

  # Anything else just passes through.
  defp rewrite(expr, acc), do: {expr, acc}

  defp find_override(overrides, module_ast) do
    Enum.find(overrides, fn
      {[shorthand_name], _v} when is_atom(shorthand_name) ->
        List.last(module_ast) == shorthand_name

      {identifier, _v} ->
        String.ends_with?(
          ".#{module_ast_to_name(identifier)}",
          ".#{module_ast_to_name(module_ast)}"
        )
    end)
  end

  defp report_broken_overrides(module_ast, overrides, overrides_completed) do
    case overrides -- overrides_completed do
      [] ->
        :do_nothing

      [unused_override] ->
        raise CompileError,
          description:
            "unable to rewire '#{module_ast_to_name(module_ast)}': dependency '#{
              module_ast_to_name(unused_override)
            }' not found"

      unused_overrides ->
        dependency_list =
          (unused_overrides
           |> Enum.drop(-1)
           |> Enum.map_join(", ", fn ast -> "'#{module_ast_to_name(ast)}'" end)) <>
            " and '" <> module_ast_to_name(List.last(unused_overrides)) <> "'"

        raise CompileError,
          description:
            "unable to rewire '#{module_ast_to_name(module_ast)}': dependencies #{dependency_list} not found"
    end
  end
end
