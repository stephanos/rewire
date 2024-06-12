defmodule RewireAliasTest do
  use ExUnit.Case
  import Rewire

  describe "rewire as alias" do
    # test "and use shorthand name" do
    #   rewire Rewire.ModuleWithDependency, Hello: Bonjour, debug: true
    #   assert ModuleWithDependency.hello() == "bonjour"
    # end

    # test "and use renamed alias" do
    #   rewire Rewire.ModuleWithDependency, Hello: Bonjour, as: RewiredModule, debug: true
    #   assert RewiredModule.hello() == "bonjour"
    # end

    # test "multiple ones" do
    #   rewire Rewire.ModuleWithNested.Nested.NestedNested, Hello: Bonjour
    #   rewire Rewire.ModuleWithNested.Nested, NestedNested: NestedNested
    #   rewire Rewire.ModuleWithNested, Nested: Nested

    #   assert ModuleWithNested.hello() == "bonjour"
    # end

    # test "however, the original module will stay the same" do
    #   rewire Rewire.ModuleWithDependency, Hello: Bonjour
    #   assert Rewire.ModuleWithDependency.hello() == "hello"
    # end

    # test "works together with a block" do
    #   rewire Rewire.ModuleWithDependency, Hello: Bonjour

    #   rewire ModuleWithDependency, Goodbye: AuRevoir do
    #     assert ModuleWithDependency.hello() == "bonjour"
    #     assert ModuleWithDependency.bye() == "au revoir"
    #   end
    # end

    test "works for macro" do
      rewire Rewire.ModuleWithMacro, Hello: Bonjour, debug: true
      assert ModuleWithMacro.hello_passthrough() == "bonjour"

      # rewire Rewire.ModuleWithMacroWithArgs, Hello: Bonjour, debug: true
      # assert ModuleWithMacroWithArgs.hello_passthrough() == "bonjour"
    end
  end
end
