defmodule Rewire.ModuleWithMacroWithArgs do
  use Rewire.Macro, use_alias: true

  def hello_passthrough do
    Hello.hello()
  end

  def good_afternoon_passthrough do
    Macro.good_afternoon()
  end
end
