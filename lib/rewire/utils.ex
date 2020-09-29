defmodule Rewire.Utils do
  @moduledoc """
  """

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
