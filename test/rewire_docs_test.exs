defmodule English do
  @callback greet() :: String.t()
  def greet(), do: "hello"
end


defmodule Conversation do
  @punctuation "!"
  def start(), do: English.greet() <> @punctuation
end


defmodule RewireTest do
  use ExUnit.Case, async: true
  import Rewire
  import Mox

  Mox.defmock(EnglishMock, for: English)
  rewire Conversation, English: EnglishMock

  describe "docs" do
    test "work" do
      stub(EnglishMock, :greet, fn -> "g'day" end)
      assert Conversation.start() == "g'day!"
    end
  end
end
