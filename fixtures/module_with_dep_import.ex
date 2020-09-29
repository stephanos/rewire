defmodule Rewire.ModuleWithImportedDependency do
  import Rewire.Hello

  def helloooo(), do: hello()
end
