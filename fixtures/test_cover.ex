defmodule Rewire.TestCover do
  @moduledoc false

  @doc false
  def start(compile_path, _opts) do
    :cover.stop()
    :cover.start()

    compile_path
    |> String.to_charlist()
    |> :cover.compile_beam_directory()

    &execute/0
  end

  defp execute do
    {:result, results, _fail} = :cover.analyse(:calls, :function)

    results
    |> Enum.find(fn
      {{Rewire.Covered, :hello, 0}, _} -> true
      _ -> false
    end)
    |> validate
  end

  defp validate({{Rewire.Covered, :hello, 0}, 8}) do
    :ok
  end

  defp validate({{Rewire.Covered, :hello, 0}, times_called}) when is_integer(times_called) do
    IO.puts("""
    Cover results are incorrect!
    Rewired.Covered.hello/0 was expected to be called 8 times,
    but coverage reports #{times_called}"
    """)

    throw(:test_cover_failed)
  end

  defp validate(_) do
    IO.puts("""
    Cover results are incorrect!
    Rewired.Covered.hello/0 was expected to be called 8 times,
    but no coverage was reported.
    """)

    throw(:test_cover_failed)
  end
end
