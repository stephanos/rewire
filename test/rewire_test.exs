defmodule RewireTest do
  use ExUnit.Case
  use Rewire

  import ExUnit.CaptureIO
  import Assertions

  alias Rewire.Hello

  defmodule Bonjour do
    def hello(), do: "bonjour"
  end

  test "creates copy of a module" do
    output =
      capture_io(:stderr, fn ->
        original_module = Rewire.Hello

        rewire Rewire.Hello do
          assert Rewire.Hello != original_module
          assert Rewire.Hello.hello() == original_module.hello()
        end
      end)

    refute output =~ "warning"
  end

  test "creates copy of an aliased module" do
    output =
      capture_io(:stderr, fn ->
        original_module = Hello

        rewire Hello do
          assert Hello != original_module
          assert Hello.hello() == original_module.hello()
        end
      end)

    refute output =~ "warning"
  end

  # TODO
  # test "creates copy of a nested module" do
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

  test "rewires non-aliased dependency" do
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

  test "rewires aliased dependency" do
    output =
      capture_io(:stderr, fn ->
        rewire Rewire.ModuleWithAliasedDependency, Hello: Bonjour do
          assert Rewire.ModuleWithAliasedDependency.hello() == "bonjour"
        end
      end)

    refute output =~ "warning"
  end

  test "rewires renamed aliased dependency" do
    output =
      capture_io(:stderr, fn ->
        rewire Rewire.ModuleWithRenamedDependency, Hello: Bonjour do
          assert Rewire.ModuleWithRenamedDependency.hello() == "bonjour"
        end
      end)

    refute output =~ "warning"
  end

  test "rewires imported dependency" do
    output =
      capture_io(:stderr, fn ->
        rewire Rewire.ModuleWithImportedDependency, Hello: Bonjour do
          assert Rewire.ModuleWithImportedDependency.helloooo() == "bonjour"
        end
      end)

    refute output =~ "warning"
  end

  test "rewires module with state" do
    output =
      capture_io(:stderr, fn ->
        rewire Rewire.ModuleWithGenServer, Hello: Bonjour do
          pid = start_supervised!(Rewire.ModuleWithGenServer)
          assert Rewire.ModuleWithGenServer.hello(pid) == "bonjour"
        end
      end)

    refute output =~ "warning"
  end

  test "fails if module to replace can not be found" do
    assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependency 'Rewire.NonExistant' not found" do
      defmodule TestModuleNotFound do
        use Rewire

        def func do
          rewire Rewire.ModuleWithAliasedDependency, [{Rewire.NonExistant, Bonjour}] do
            # nothing here
          end
        end
      end
    end
  end

  test "fails if module shorthand to replace can not be found" do
    assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependency 'NonExistant' not found" do
      defmodule TestModuleNotFound do
        use Rewire

        def func do
          rewire Rewire.ModuleWithAliasedDependency, NonExistant: Bonjour do
            # nothing here
          end
        end
      end
    end
  end

  test "fails if multiple module shorthands to replace can not be found" do
    assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependencies 'NonExistant' and 'OtherNonExistant' not found" do
      defmodule TestModuleNotFound do
        use Rewire

        def func do
          rewire Rewire.ModuleWithAliasedDependency,
            NonExistant: Bonjour,
            OtherNonExistant: Bonjour do
            # nothing here
          end
        end
      end
    end
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

  test "fails if module does not exist" do
    assert_compile_time_raise "unable to rewire 'Elixir.ModuleDoesNotExist': cannot find module - does it exist?" do
      defmodule TestModuleNotFound do
        use Rewire

        def func do
          rewire ModuleDoesNotExist do
            # nothing
          end
        end
      end
    end
  end
end
