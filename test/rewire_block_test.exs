defmodule RewireBlockTest do
  use ExUnit.Case
  use Rewire

  import ExUnit.CaptureIO

  describe "rewire a block with" do
    test "non-aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithDependency, [{Rewire.Hello, Bonjour}] do
            assert Rewire.ModuleWithDependency.hello() == "bonjour"
          end

          rewire Rewire.ModuleWithDependency, Hello: Bonjour do
            assert Rewire.ModuleWithDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithAliasedDependency, Hello: Bonjour do
            assert Rewire.ModuleWithAliasedDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "renamed aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithRenamedDependency, Hello: Bonjour do
            assert Rewire.ModuleWithRenamedDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "imported dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithImportedDependency, Hello: Bonjour do
            assert Rewire.ModuleWithImportedDependency.helloooo() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "module with state" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithGenServer, Hello: Bonjour do
            pid = start_supervised!(Rewire.ModuleWithGenServer)
            assert Rewire.ModuleWithGenServer.hello(pid) == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "stracktrace still points to original file location" do
      try do
        rewire Rewire.Goodbye do
          Rewire.Goodbye.hello()
        end

        refute "we never get here"
      rescue
        err ->
          stacktrace = Exception.format(:error, err, __STACKTRACE__)
          refute String.contains?(stacktrace, "nofile")
          assert String.contains?(stacktrace, "fixtures/goodbye.ex:2: Rewire.Goodbye")
      end
    end
  end
end