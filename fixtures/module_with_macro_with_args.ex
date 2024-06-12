defmodule Rewire.ModuleWithMacroWithArgs do
  use Rewire.Macro, use_alias: true

  def hello_passthrough do
    Hello.hello()
  end
end
