defmodule Rewire.ModuleWithMacro do
  use Rewire.Macro

  def hello_passthrough do
    hello()
  end

  def good_afternoon_passthrough do
    good_afternoon()
  end
end
