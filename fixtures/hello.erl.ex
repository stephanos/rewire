defmodule Rewire.HelloErlang do
  @callback hello() :: String.t()
  def hello(), do: :string.titlecase("hello")
end
