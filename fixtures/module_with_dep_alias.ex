defmodule Rewire.ModuleWithAliasedDependency do
  alias Rewire.Hello

  # here for testing edge cases:
  alias Rewire.Hello
  alias Rewire.{Hello, Hello}

  def hello(), do: Hello.hello()
end
