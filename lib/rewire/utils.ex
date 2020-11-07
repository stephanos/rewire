defmodule Rewire.Utils do
  @moduledoc false

  def parse_opts(old_module_ast, opts, %{aliases: aliases, file: file, line: line}) do
    old_module_ast = resolve_alias(old_module_ast, aliases)
    mod = module_ast_to_atom(old_module_ast)

    # First, we need to make sure that the module to rewire actually exists.
    if Code.ensure_compiled(mod) == {:error, :nofile} do
      raise CompileError,
        description: "unable to rewire '#{module_to_name(mod)}': cannot find module",
        file: file,
        line: line
    end

    # Then, we need to check if the module to rewire has actually been rewired before.
    # If so, we'll use the original module's name for generating a new name and
    # add the previously overridden dependencies to the overrides.
    previously_rewired =
      mod.module_info() |> Keyword.get(:exports) |> Keyword.fetch(:__rewire__) == {:ok, 0}

    {old_module_ast, inherited_overrides} =
      if previously_rewired do
        %{original: original, rewired: rewired} = mod.__rewire__()
        {original, rewired}
      else
        {old_module_ast, %{}}
      end

    default_opts = %{
      mod: mod,
      file: file,
      line: line,
      debug: false,
      old_module_ast: old_module_ast,
      new_module_ast: gen_new_module_ast(old_module_ast),
      module_shorthand: List.last(old_module_ast),
      overrides: inherited_overrides
    }

    # Customize rewire options from user input.
    opts =
      Enum.reduce(opts, default_opts, fn
        {:as, {:__aliases__, _, [new_name]}}, acc ->
          Map.put(acc, :module_shorthand, new_name)

        {:debug, debug}, acc ->
          Map.put(acc, :debug, debug)

        # Here the module to replace and the replacement are defined as fully-qualified aliases.
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
          raise CompileError,
            description: "unknown option passed to `rewire`: #{inspect(k)}",
            file: file,
            line: line
      end)

    debug_log(opts, fn -> "old name: #{inspect(Map.get(opts, :old_module_ast))}" end)
    debug_log(opts, fn -> "new name: #{inspect(Map.get(opts, :new_module_ast))}" end)
    debug_log(opts, fn -> "alias: #{inspect(Map.get(opts, :module_shorthand))}" end)
    debug_log(opts, fn -> "overrides: #{inspect(Map.get(opts, :overrides))}" end)

    opts
  end

  # Determine generated module's name. It has to be a unique name.
  def gen_new_module_ast(old_module_ast) do
    context_id = "R#{Enum.random(0..10_000)}" |> String.to_atom()
    old_module_ast ++ [context_id]
  end

  defp resolve_alias(module_ast, aliases) do
    Enum.find_value(aliases, fn
      {alias_mod, full_mod_ast} ->
        if module_to_ast(alias_mod) == module_ast do
          module_to_ast(full_mod_ast)
        else
          false
        end
    end) || module_ast
  end

  def module_ast_to_atom(ast),
    do: "Elixir.#{module_ast_to_name(ast)}" |> String.to_atom()

  def module_ast_to_name(ast),
    do: ast |> Enum.map_join(".", &Atom.to_string/1)

  def module_to_name(mod),
    do: mod |> Atom.to_string()

  def module_to_ast(mod),
    do: mod |> module_to_name() |> module_name_to_ast()

  def module_name_to_ast(name),
    do: name |> String.trim_leading("Elixir.") |> String.split(".") |> Enum.map(&String.to_atom/1)

  def debug_log(%{debug: true} = opts, message_func) when is_function(message_func) do
    debug_log(opts, message_func.())
  end

  def debug_log(%{debug: true, mod: mod}, message) do
    IO.puts(IO.ANSI.format([:light_blue, "[Rewire] [#{mod}] #{message}"]))
  end

  def debug_log(_opts, _message), do: :ok
end
