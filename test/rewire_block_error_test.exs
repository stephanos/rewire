defmodule RewireBlockErrorTest do
  use ExUnit.Case
  use Rewire

  import TestHelpers

  describe "rewiring of a block fails" do
    test "if module to replace can not be found" do
      assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependency 'Rewire.NonExistant' not found" do
        defmodule ModuleToReplaceNotFound do
          use Rewire

          def func do
            rewire Rewire.ModuleWithAliasedDependency, [{Rewire.NonExistant, Bonjour}] do
              # nothing here
            end
          end
        end
      end
    end

    test "if module shorthand to replace can not be found" do
      assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependency 'NonExistant' not found" do
        defmodule ModuleReplacementNotFound do
          use Rewire

          def func do
            rewire Rewire.ModuleWithAliasedDependency, NonExistant: Bonjour do
              # nothing here
            end
          end
        end
      end
    end

    test "if multiple module shorthands to replace can not be found" do
      assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependencies 'NonExistant' and 'OtherNonExistant' not found" do
        defmodule ModuleShorthandReplacementNotFound do
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

    test "if module does not exist" do
      assert_compile_time_raise "unable to rewire 'Elixir.ModuleDoesNotExist': cannot find module - does it exist?" do
        defmodule ModuleNotFound do
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
end
