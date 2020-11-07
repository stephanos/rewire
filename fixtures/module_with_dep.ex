defmodule Rewire.ModuleWithDependency do
  def hello(), do: Rewire.Hello.hello()
  def bye(), do: Rewire.Goodbye.bye()
end
