defmodule Rewire.ModuleWithRenamedDependency do
  alias Rewire.Hello, as: Hi

  def hello(), do: Hi.hello()
end
