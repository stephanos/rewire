defmodule RewireAliasTest do
  use ExUnit.Case
  use Rewire

  rewire Rewire.ModuleWithDependency, Hello: Bonjour
  rewire Rewire.ModuleWithDependency, Hello: Bonjour, as: RewiredModule

  describe "rewire as alias" do
    test "and use shorthand name" do
      assert ModuleWithDependency.hello() == "bonjour"
    end

    test "and use renamed alias" do
      assert RewiredModule.hello() == "bonjour"
    end

    test "however, the full path will stay the same" do
      assert Rewire.ModuleWithDependency.hello() == "hello"
    end
  end
end
