defmodule Rewire.ModuleWithMacroWithArgs do
  use Rewire.Macro, arg1: :value1

  def hello_passthrough do
    hello()
  end
end
