defmodule Rewire.ModuleWithDependency do
  def hello(), do: Rewire.Hello.hello()
end
