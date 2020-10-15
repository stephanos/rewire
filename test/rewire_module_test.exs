defmodule RewireModuleTest do
  use ExUnit.Case
  use Rewire

  alias Rewire.Hello
  import ExUnit.CaptureIO

  describe "creates module from" do
    test "a module" do
      output =
        capture_io(:stderr, fn ->
          original_module = Rewire.Hello

          rewire Rewire.Hello, as: Hello do
            assert Hello != original_module
            assert Hello.hello() == original_module.hello()
          end
        end)

      refute output =~ "warning"
    end

    test "an aliased module" do
      output =
        capture_io(:stderr, fn ->
          original_module = Hello

          rewire Hello, as: Hello do
            assert Hello != original_module
            assert Hello.hello() == original_module.hello()
          end
        end)

      refute output =~ "warning"
    end

    # test "a module with nested modules inside" do
    #   output =
    #     capture_io(:stderr, fn ->
    #       original_module = Rewire.ModuleWithNested
    #       original_nested_module = Rewire.ModuleWithNested.Nested
    #       original_nested_nested_module = Rewire.ModuleWithNested.Nested.NestedNested

    #       rewire Rewire.ModuleWithNested, as: ModuleWithNested do
    #         assert ModuleWithNested != original_module
    #         assert ModuleWithNested.hello() == original_module.hello()

    #         assert ModuleWithNested.Nested != original_nested_module
    #         assert ModuleWithNested.Nested.hello() == original_nested_module.hello()

    #         assert ModuleWithNested.Nested.NestedNested != original_nested_nested_module
    #         assert ModuleWithNested.Nested.NestedNested.hello() == original_nested_nested_module.hello()
    #       end
    #     end)

    #   refute output =~ "warning"
    # end

    # test "a nested module" do
    #   output =
    #     capture_io(:stderr, fn ->
    #       original_module = Rewire.ModuleWithNested.Nested.NestedNested

    #       rewire Rewire.ModuleWithNested.Nested.NestedNested, as: NestedNested do
    #         assert NestedNested != original_module
    #         assert NestedNested.hello() == original_module.hello()
    #       end
    #     end)

    #   refute output =~ "warning"
    # end
  end
end
