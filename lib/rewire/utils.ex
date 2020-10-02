defmodule Rewire.Utils do
  @moduledoc """
  """

  def parse_opts(opts, aliases) do
    Enum.reduce(opts, %{overrides: %{}}, fn
      {:as, new_name}, acc ->
        Map.put(acc, :as, new_name)

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

  # Determine generated module's name. It has to be a unique name.
  def gen_new_module_ast(rewire_module_ast) do
    context_id = "R#{Enum.random(0..10_000)}" |> String.to_atom()
    rewire_module_ast ++ [context_id]
  end

  def resolve_alias(module_ast, aliases) do
    Enum.find_value(aliases, fn
      {alias_mod, full_mod_ast} ->
        if module_to_ast(alias_mod) == module_ast do
          module_to_ast(full_mod_ast)
        else
          false
        end
    end) || module_ast
  end

  def module_ast_to_name(ast), do: ast |> Enum.map_join(".", &Atom.to_string/1)
  def module_to_name(mod), do: mod |> Atom.to_string()
  def module_to_ast(mod), do: mod |> module_to_name() |> module_name_to_ast()

  def module_name_to_ast(name),
    do: name |> String.trim_leading("Elixir.") |> String.split(".") |> Enum.map(&String.to_atom/1)
end
