defmodule Rewire.Hello do
  @callback hello() :: String.t()
  def hello(), do: "hello"
end
