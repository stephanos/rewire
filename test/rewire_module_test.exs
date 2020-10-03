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

    # TODO
    # test "a nested module" do
    #   output =
    #     capture_io(:stderr, fn ->
    #       original_module = Rewire.ModuleWithNested.Nested.NestedNested

    #       rewire Rewire.ModuleWithNested.Nested.NestedNested do
    #         assert Rewire.ModuleWithNested.Nested.NestedNested != original_module
    #         assert Rewire.ModuleWithNested.Nested.NestedNested.hello() == original_module.hello()
    #       end
    #     end)

    #   refute output =~ "warning"
    # end
  end
end
