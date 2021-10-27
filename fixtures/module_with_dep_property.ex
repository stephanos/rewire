defmodule Rewire.ModuleWithPropertyDependency do
  @hello Application.compile_env!(:rewire, :hello)
  @hello_explicit Rewire.Hello

  def hello(), do: @hello.hello()
  def hello_explicit(), do: @hello_explicit.hello()
end
