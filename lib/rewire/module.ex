defmodule Rewire.Module do
  @moduledoc false

  require Logger
  import Rewire.Utils

  def rewire_module(%{mod: mod} = opts) do
    # Find module's source file path.
    source_path =
      mod.module_info()
      |> Keyword.get(:compile)
      |> Keyword.get(:source)
      |> to_string()

    debug_log(opts, "source path: #{Path.relative_to(source_path, File.cwd!())}")

    # Load module's AST.
    source = File.read!(source_path)
    {:ok, ast} = Code.string_to_quoted(source)

    debug_log(opts, fn ->
      ["original AST:", inspect(ast, pretty: true), ""] |> Enum.join("\n\n")
    end)

    # Traverse through AST and create new module with rewired dependencies.
    old_mod_name = mod |> Atom.to_string() |> String.trim_leading("Elixir.")
    new_mod_name = Map.fetch!(opts, :new_module_ast) |> module_ast_to_name()
    new_module = "Elixir.#{new_mod_name}" |> String.to_atom()

    new_ast =
      traverse(
        ast,
        module_name_to_ast(old_mod_name),
        module_name_to_ast(new_mod_name),
        opts
      )

    debug_log(opts, fn ->
      ["new AST:", inspect(new_ast, pretty: true), ""] |> Enum.join("\n\n")
    end)

    debug_log(opts, fn ->
      ["new code:", Macro.to_string(quote do: unquote(new_ast)) <> "\n"] |> Enum.join("\n\n")
    end)

    Rewire.Cover.enable_abstract_code()

    # Now evaluate the new module's AST so the file location is correct.
    Code.eval_quoted(new_ast, [], file: source_path)
    |> Rewire.Cover.compile(old_mod_name)

    Rewire.Cover.track(new_module, mod)
    new_module
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

    # In some cases the generated AST is unnecessarily nested, which prevents
    # capturing the created module and compiling for coverage reporting.
    flatten(new_ast)
  end

  # Changes the rewired module's name to prevent a naming collision.
  defp rewrite(
         {:defmodule, l1, [{:__aliases__, l2, module_ast}, [do: {:__block__, [], body}]]},
         acc = %{
           overrides: overrides,
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
        debug_log(acc, "found module: #{inspect(full_module_ast)}")

        # To allow multiple rewire steps, we need to add rewire metadata to the module.
        # `__rewire__/0` will contain the original module name and the overrides.
        metadata =
          {:def, [line: 0],
           [
             {:__rewire__, [line: 0], []},
             [
               do:
                 {:%{}, [line: 0],
                  [
                    original: old_module_ast,
                    rewired: {:%{}, [line: 0], overrides |> Enum.map(fn item -> item end)}
                  ]}
             ]
           ]}

        {{:defmodule, l1, [{:__aliases__, l2, new_module_ast}, [do: [metadata | body]]]},
         %{acc | module_parent_ast: module_parent_ast ++ old_module_ast}}

      # We found a parent module of the module to rewrite,
      # let's extract all nested modules and continue.
      List.starts_with?(old_module_ast, full_module_ast) ->
        debug_log(acc, "found parent module: #{inspect(module_ast)}")

        {body
         |> Enum.filter(fn
           {:defmodule, _, _} -> true
           _ -> false
         end), %{acc | module_parent_ast: full_module_ast}}

      # Skip module entirely because it would just be redefined, causing a warning.
      true ->
        debug_log(acc, "ignoring inner module: #{inspect(module_ast)}")
        {[], %{acc | prev_module_asts: [module_ast | prev_module_asts]}}
    end
  end

  defp rewrite({:defmodule, l1, [{:__aliases__, l2, module_ast}, [do: body]]}, acc) do
    # We rewire the module body to always be a block in order to simplify things.
    rewrite(
      {:defmodule, l1, [{:__aliases__, l2, module_ast}, [do: {:__block__, [], [body]}]]},
      acc
    )
  end

  defp rewrite(use_ast = {:use, _l1, [{:__aliases__, _l2, _macro_ast} | _args]}, acc) do
    {:__block__, [], [{:__block__, [], [req, using]}]} = Macro.expand(use_ast, __ENV__)
    {:require, _counter_ctx, [required_module]} = req
    {:ok, env} = Macro.Env.define_require(__ENV__, [], required_module)

    {Macro.expand(using, env), acc}
  end

  # Removes a single alias (ie `alias A.A`) pointing to an overriden module dependency. Keeps the others.
  defp rewrite(
         expr = {:alias, _, [{:__aliases__, _, module_ast}]},
         acc = %{overrides: overrides}
       ) do
    case find_override(overrides, module_ast) do
      nil ->
        debug_log(acc, "removing `alias`: #{inspect(module_ast)}")
        {expr, acc}

      _ ->
        {[], acc}
    end
  end

  # Replace a single property (ie `@property Application.compile_env!(...)`).
  defp rewrite(
         expr = {:@, meta, [{property, _, body}]},
         acc = %{overrides: overrides, overrides_completed: overrides_completed}
       )
       when not is_nil(body) do
    case Map.get(overrides, [property]) do
      nil ->
        {expr, acc}

      over ->
        {{:@, meta, [{property, meta, [{:__aliases__, meta, over}]}]},
         %{acc | overrides_completed: overrides_completed ++ [[property]]}}
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
         acc = %{
           overrides: overrides,
           overrides_completed: overrides_completed,
           module_parent_ast: module_parent_ast,
           prev_module_asts: prev_module_asts
         }
       ) do
    case find_override(overrides, module_ast) do
      nil ->
        if Enum.member?(prev_module_asts, module_ast) do
          # It's referencing a previously defined module,
          # we're going to point it to the original module instead.
          debug_log(acc, "replacing inner module reference: #{inspect(module_ast)}")
          {{:__aliases__, l1, module_parent_ast ++ module_ast}, acc}
        else
          {expr, acc}
        end

      {identifier, new_ast} ->
        debug_log(acc, "replacing module reference: #{inspect(module_ast)}")

        {{:__aliases__, l1, new_ast},
         %{acc | overrides_completed: [identifier | overrides_completed]}}
    end
  end

  # Replaces any rewired module's Erlang references to point to mocks instead.
  defp rewrite(
         expr = {:., l1, [module, func]},
         acc = %{
           overrides: overrides,
           overrides_completed: overrides_completed
         }
       )
       when is_atom(module) do
    case find_override(overrides, [module]) do
      nil ->
        {expr, acc}

      {_, new_ast} ->
        debug_log(acc, "replacing Erlang module reference: #{inspect(module)}")

        {{:., l1, [{:__aliases__, l1, new_ast}, func]},
         %{acc | overrides_completed: [[module] | overrides_completed]}}
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
            "unable to rewire '#{module_ast_to_name(module_ast)}': dependency '#{module_ast_to_name(unused_override)}' not found",
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

  defp flatten({:__block__, [], [[], {:defmodule, _, _} = nested, []]}) do
    {:__block__, [], [nested]}
  end

  defp flatten(ast), do: ast
end
