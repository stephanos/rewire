defmodule RewireModuleTest do
  use ExUnit.Case
  use Rewire

  alias Rewire.Hello
  import ExUnit.CaptureIO

  describe "creates module from" do
    test "a module" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.Hello, as: Rewired do
            assert Rewired != Rewire.Hello
            assert Rewired.hello() == Rewire.Hello.hello()
          end
        end)

      refute output =~ "warning"
    end

    test "an aliased module" do
      output =
        capture_io(:stderr, fn ->
          rewire Hello, as: Rewired do
            assert Rewired != Hello
            assert Rewired.hello() == Hello.hello()
          end
        end)

      refute output =~ "warning"
    end

    test "a module with a nested module inside" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithNested, as: Rewired do
            assert Rewired != Rewire.ModuleWithNested
            assert Rewired.hello() == Rewire.ModuleWithNested.hello()

            # nested ones have been copied, too
            assert Rewired.Nested != Rewire.ModuleWithNested.Nested
            assert Rewired.Nested.NestedNested != Rewire.ModuleWithNested.Nested.NestedNested
          end
        end)

      refute output =~ "warning"
    end

    test "a nested module" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithNested.Nested, as: Rewired do
            assert Rewired != Rewire.ModuleWithNested.Nested
            assert Rewired.hello() == Rewire.ModuleWithNested.Nested.hello()
          end

          rewire Rewire.ModuleWithNested.Nested.NestedNested, as: Rewired do
            assert Rewired != Rewire.ModuleWithNested.Nested.NestedNested
            assert Rewired.hello() == Rewire.ModuleWithNested.Nested.NestedNested.hello()
          end
        end)

      refute output =~ "warning"
    end
  end
end
