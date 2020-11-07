defmodule RewireAliasTest do
  use ExUnit.Case
  import Rewire

  describe "rewire as alias" do
    test "and use shorthand name" do
      rewire Rewire.ModuleWithDependency, Hello: Bonjour
      assert ModuleWithDependency.hello() == "bonjour"
    end

    test "and use renamed alias" do
      rewire Rewire.ModuleWithDependency, Hello: Bonjour, as: RewiredModule
      assert RewiredModule.hello() == "bonjour"
    end

    test "multiple ones" do
      rewire Rewire.ModuleWithNested.Nested.NestedNested, Hello: Bonjour
      rewire Rewire.ModuleWithNested.Nested, NestedNested: NestedNested
      rewire Rewire.ModuleWithNested, Nested: Nested

      assert ModuleWithNested.hello() == "bonjour"
    end

    test "however, the original module will stay the same" do
      rewire Rewire.ModuleWithDependency, Hello: Bonjour
      assert Rewire.ModuleWithDependency.hello() == "hello"
    end

    test "works together with a block" do
      rewire Rewire.ModuleWithDependency, Hello: Bonjour
      rewire ModuleWithDependency, Goodbye: AuRevoir do
        assert ModuleWithDependency.hello() == "bonjour"
        assert ModuleWithDependency.bye() == "au revoir"
      end
    end
  end
end
