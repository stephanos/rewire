defmodule RewireBlockTest do
  use ExUnit.Case
  import Rewire

  import ExUnit.CaptureIO

  describe "rewire a block with" do
    test "non-aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithDependency, [{Rewire.Hello, Bonjour}] do
            assert ModuleWithDependency.hello() == "bonjour"
          end

          rewire Rewire.ModuleWithDependency, Hello: Bonjour do
            assert ModuleWithDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithAliasedDependency, Hello: Bonjour do
            assert ModuleWithAliasedDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "property dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithPropertyDependency, hello: Bonjour do
            assert ModuleWithPropertyDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "explicit property dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithPropertyDependency, hello_explicit: Bonjour do
            assert ModuleWithPropertyDependency.hello_explicit() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "nested, aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithNested.Nested.NestedNested, Hello: Bonjour do
            assert NestedNested.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "nested, property" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithNested.Nested.NestedNested, hello: Bonjour do
            assert NestedNested.hello_with_property() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "renamed aliased dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithRenamedDependency, Hello: Bonjour do
            assert ModuleWithRenamedDependency.hello() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "an Erlang module" do
      defmodule StringMock do
        def titlecase("hello"), do: "Hello!"
      end

      output =
        capture_io(:stderr, fn ->
          rewire Rewire.HelloErlang, string: StringMock do
            assert HelloErlang.hello() == "Hello!"
          end
        end)

      refute output =~ "warning"
    end

    test "imported dependency" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithImportedDependency, Hello: Bonjour do
            assert ModuleWithImportedDependency.helloooo() == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "module with state" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithGenServer, Hello: Bonjour do
            pid = start_supervised!(ModuleWithGenServer)
            assert ModuleWithGenServer.hello(pid) == "bonjour"
          end
        end)

      refute output =~ "warning"
    end

    test "multiple modules" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithNested.Nested.NestedNested, Hello: Bonjour do
            rewire Rewire.ModuleWithNested.Nested, NestedNested: NestedNested do
              rewire Rewire.ModuleWithNested, Nested: Nested do
                assert ModuleWithNested.hello() == "bonjour"
              end
            end
          end
        end)

      refute output =~ "warning"
    end

    test "multiple modules with property" do
      output =
        capture_io(:stderr, fn ->
          rewire Rewire.ModuleWithNested.Nested.NestedNested, hello: Bonjour do
            rewire Rewire.ModuleWithNested.Nested, nested: NestedNested do
              rewire Rewire.ModuleWithNested, nested: Nested do
                assert ModuleWithNested.hello_with_property() == "bonjour"
              end
            end
          end
        end)

      refute output =~ "warning"
    end

    test "stracktrace still points to original file location" do
      try do
        rewire Rewire.Goodbye, as: Goodbye do
          Goodbye.bye()
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
