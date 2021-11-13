defmodule Rewire.Application do
  @moduledoc """
  Mock for "Application" (does not exist on older elixir versions).
  """

  def compile_env!(_app, _property), do: Rewire.Hello
end
