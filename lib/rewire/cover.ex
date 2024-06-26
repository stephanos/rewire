defmodule Rewire.Cover do
  @moduledoc """
  Abuse cover private functions to move stuff around.

  Adapted from mimic's solution:
  https://github.com/edgurgel/mimic/blob/5d3e651ce78473195c70ab86c9d2d0609a12dd3b/lib/mimic/cover.ex

  Which is based on meck's solution:
  https://github.com/eproxus/meck/blob/2c7ba603416e95401500d7e116c5a829cb558665/src/meck_cover.erl#L67-L91
  """

  use Agent

  @tmp_coverdata_dir Mix.Project.build_path() <> "/rewire_coverdata"

  def start_link(_) do
    if enabled?() do
      export_private_functions()
      ExUnit.after_suite(&after_suite/1)
    end

    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def enable_abstract_code do
    if enabled?() && Version.compare(System.version(), "1.14.0") in [:gt, :eq] do
      # Code.eval_quoted/3 does not seem to include abstract code in generated
      # modules by default without this after Elixir 1.14.
      apply(Code, :put_compiler_option, [:debug_info, true])
    end
  end

  def compile(eval_result, old_mod_name) do
    if enabled?() do
      case eval_result do
        # Capture created module and compile for coverage reporting.
        {{:module, module, binary, _}, []} ->
          apply(:cover, :compile_beams, [[{module, binary}]])

        {[_, {:module, module, binary, _}, _], []} ->
          apply(:cover, :compile_beams, [[{module, binary}]])

        {[_, [{:module, module, binary, _}], _], []} ->
          apply(:cover, :compile_beams, [[{module, binary}]])

        _ ->
          IO.warn("Failed to compile code coverage for: #{old_mod_name}")
      end
    end
  end

  def track(new_module, original_module) do
    if enabled?(original_module) do
      Agent.update(__MODULE__, &[{new_module, original_module} | &1])
    end
  end

  defp enabled?(), do: Version.compare(System.version(), "1.8.0") in [:gt, :eq]
  defp enabled?(module), do: enabled?() && :cover.is_compiled(module) != false

  defp after_suite(_) do
    Agent.get(__MODULE__, & &1)
    |> Enum.each(fn {new_module, mod} ->
      replace_coverdata!(new_module, mod)
    end)

    File.rm_rf!(@tmp_coverdata_dir)
  end

  defp export_private_functions do
    {_, binary, _} = :code.get_object_code(:cover)
    abstract_code = get_abstract_code(binary)
    {:ok, module, binary} = :compile.forms(abstract_code, [:export_all])
    :code.load_binary(module, '', binary)
  end

  defp get_abstract_code(binary) do
    try do
      {:ok, {_, [{_, {_, abstract_code}}]}} = :beam_lib.chunks(binary, [:abstract_code])
      abstract_code
    rescue
      _e -> {:ok, {_, [abstract_code: abstract_code]}} = :beam_lib.chunks(binary, [:abstract_code])
      abstract_code
    end
  end

  defp replace_coverdata!(rewired, original_module) do
    rewired_path = export_coverdata!(rewired)
    rewrite_coverdata!(rewired_path, original_module)
    :ok = :cover.import(String.to_charlist(rewired_path))
    File.rm(rewired_path)
  end

  defp export_coverdata!(module) do
    File.mkdir_p!(@tmp_coverdata_dir)
    path = Path.expand("#{module}-#{:os.getpid()}.coverdata", @tmp_coverdata_dir)
    :ok = :cover.export(String.to_charlist(path), module)
    path
  end

  defp rewrite_coverdata!(path, module) do
    terms = get_terms(path)
    terms = replace_module_name(terms, module)
    write_coverdata!(path, terms)
  end

  defp replace_module_name(terms, module) do
    Enum.map(terms, fn term -> do_replace_module_name(term, module) end)
  end

  defp do_replace_module_name({:file, old, file}, module) do
    {:file, module, String.replace(file, to_string(old), to_string(module))}
  end

  defp do_replace_module_name({bump = {:bump, _mod, _, _, _, _}, value}, module) do
    {put_elem(bump, 1, module), value}
  end

  defp do_replace_module_name({_mod, clauses}, module) do
    {module, replace_module_name(clauses, module)}
  end

  defp do_replace_module_name(clause = {_mod, _, _, _, _}, module) do
    put_elem(clause, 0, module)
  end

  defp get_terms(path) do
    {:ok, resource} = File.open(path, [:binary, :read, :raw])
    terms = get_terms(resource, [])
    File.close(resource)
    terms
  end

  defp get_terms(resource, terms) do
    case apply(:cover, :get_term, [resource]) do
      :eof -> terms
      term -> get_terms(resource, [term | terms])
    end
  end

  defp write_coverdata!(path, terms) do
    {:ok, resource} = File.open(path, [:write, :binary, :raw])
    Enum.each(terms, fn term -> apply(:cover, :write, [term, resource]) end)
    File.close(resource)
  end
end
