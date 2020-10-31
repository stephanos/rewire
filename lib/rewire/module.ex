defmodule Rewire.Module do
  @moduledoc false

  import Rewire.Utils

  def rewire_module(module_ast, %{file: file, line: line} = opts) do
    mod = "Elixir.#{module_ast_to_name(module_ast)}" |> String.to_atom()

    # We need to make sure that the module to rewire actually exists first.
    if Code.ensure_compiled(mod) == {:error, :nofile} do
      raise CompileError,
        description: "unable to rewire '#{module_to_name(mod)}': cannot find module",
        file: file,
        line: line
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

    # Determine new generated module name.
    old_mod_name = mod |> Atom.to_string() |> String.trim_leading("Elixir.")
    new_mod_name = Map.fetch!(opts, :new_module_ast) |> module_ast_to_name()

    # Traverse through AST and create new module with rewired dependencies.
    new_ast =
      traverse(
        ast,
        module_name_to_ast(old_mod_name),
        module_name_to_ast(new_mod_name),
        opts
      )

    # If enabled, save debug output.
    if Map.get(opts, :debug) do
      content =
        [
          "Rewire #{module_to_name(mod)}\n====",
          "[ AST ]",
          inspect(new_ast, pretty: true),
          "[ CODE ]",
          Macro.to_string(quote do: unquote(new_ast)) <> "\n"
        ]
        |> Enum.join("\n\n")

      debug_source_path = String.trim_trailing(source_path, ".ex") <> ".debug"
      File.write!(debug_source_path, content)
    end

    # Now evaluate the new module's AST so the file location is correct.
    Code.eval_quoted(new_ast, [], file: source_path)
    "Elixir.#{new_mod_name}" |> String.to_atom()
  end

  defp traverse(ast, old_module_ast, new_module_ast, opts) do
    acc =
      %{
        overrides: %{},
        overrides_completed: [],
        module_parent_ast: [],
        prev_module_asts: [],
        old_module_ast: old_module_ast,
        new_module_ast: new_module_ast
      }
      |> Map.merge(opts)

    pre = fn expr, acc -> rewrite(expr, acc) end
    post = fn expr, acc -> {expr, acc} end

    {new_ast, new_acc} = Macro.traverse(ast, acc, pre, post)

    %{overrides: overrides} = acc
    %{overrides_completed: overrides_completed} = new_acc
    report_broken_overrides(old_module_ast, Map.keys(overrides), overrides_completed, opts)

    new_ast
  end

  # Changes the rewired module's name to prevent a naming collision.
  defp rewrite(
         {:defmodule, l1, [{:__aliases__, l2, module_ast}, rest]},
         acc = %{
           prev_module_asts: prev_module_asts,
           new_module_ast: new_module_ast,
           old_module_ast: old_module_ast,
           module_parent_ast: module_parent_ast
         }
       ) do
    full_module_ast = module_parent_ast ++ module_ast

    cond do
      # We found the module to rewire,
      # let's create a copy with a new name.
      full_module_ast == old_module_ast ->
        {{:defmodule, l1, [{:__aliases__, l2, new_module_ast}, rest]},
         %{acc | module_parent_ast: module_parent_ast ++ old_module_ast}}

      # We found a parent module of the module to rewrite,
      # let's extract all nested modules and continue.
      List.starts_with?(old_module_ast, full_module_ast) ->
        [do: {:__block__, _, body}] = rest

        {body
         |> Enum.filter(fn
           {:defmodule, _, _} -> true
           _ -> false
         end), %{acc | module_parent_ast: full_module_ast}}

      # Skip module entirely because it would just be redefined, causing a warning.
      true ->
        {[], %{acc | prev_module_asts: [module_ast | prev_module_asts]}}
    end
  end

  # Removes a single alias (ie `alias A.A`) pointing to an overriden module dependency. Keeps the others.
  defp rewrite(
         expr = {:alias, _, [{:__aliases__, _, module_ast}]},
         acc = %{overrides: overrides}
       ) do
    case find_override(overrides, module_ast) do
      nil -> {expr, acc}
      _ -> {[], acc}
    end
  end

  # Removes a multi-aliases (ie `alias A.{B, C}`) overriden module dependencies. Keeps the others.
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
         acc = %{overrides: overrides, overrides_completed: overrides_completed, module_parent_ast: module_parent_ast, prev_module_asts: prev_module_asts}
       ) do
    case find_override(overrides, module_ast) do
      nil ->
        if Enum.member?(prev_module_asts, module_ast) do
          # It's referencing a previously define module,
          # we're going to point the alias to the original module instead.
          {{:__aliases__, l1, module_parent_ast ++ module_ast}, acc}
        else
          {expr, acc}
        end

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

  defp report_broken_overrides(module_ast, overrides, overrides_completed, %{
         file: file,
         line: line
       }) do
    case overrides -- overrides_completed do
      [] ->
        :do_nothing

      [unused_override] ->
        raise CompileError,
          description:
            "unable to rewire '#{module_ast_to_name(module_ast)}': dependency '#{
              module_ast_to_name(unused_override)
            }' not found",
          file: file,
          line: line

      unused_overrides ->
        dependency_list =
          (unused_overrides
           |> Enum.drop(-1)
           |> Enum.map_join(", ", fn ast -> "'#{module_ast_to_name(ast)}'" end)) <>
            " and '" <> module_ast_to_name(List.last(unused_overrides)) <> "'"

        raise CompileError,
          description:
            "unable to rewire '#{module_ast_to_name(module_ast)}': dependencies #{dependency_list} not found",
          file: file,
          line: line
    end
  end
end
