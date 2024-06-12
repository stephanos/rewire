defmodule Rewire.ModuleWithMacro do
  use Rewire.Macro
  # require Rewire.Macro
  # Rewire.Macro.__using__([])

  def hello_passthrough do
    hello()
  end
end
