defmodule Rewire.ModuleWithMacro do
  use Rewire.Macro

  def hello_passthrough do
    hello()
  end
end
