defmodule RewireBlockErrorTest do
  use ExUnit.Case
  import TestHelpers

  describe "rewiring via alias fails" do
    test "if no module is passed in" do
      assert_compile_time_raise "unable to rewire: the first argument must be an Elixir module" do
        import Rewire

        rewire(:not_a_module)
      end
    end

    test "if no options are passed in" do
      assert_compile_time_raise "unable to rewire: options are missing" do
        import Rewire

        rewire(Rewire.ModuleWithAliasedDependency)
      end
    end
  end

  describe "rewiring via a block fails" do
    test "if no module is passed in" do
      assert_compile_time_raise "unable to rewire: the first argument must be an Elixir module" do
        defmodule NoModule do
          import Rewire

          def func do
            rewire :not_a_module, as: Rewired do
              # nothing here
            end
          end
        end
      end
    end

    test "if no options are passed in" do
      assert_compile_time_raise "unable to rewire: options are missing" do
        defmodule NoModule do
          import Rewire

          def func do
            rewire Rewire.ModuleWithAliasedDependency do
              # nothing here
            end
          end
        end
      end
    end

    test "if module to replace can not be found" do
      assert_compile_time_raise "unable to rewire 'Rewire.ModuleWithAliasedDependency': dependency 'Rewire.NonExistant' not found" do
        defmodule ModuleToReplaceNotFound do
          import Rewire

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
          import Rewire

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
          import Rewire

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
      assert_compile_time_raise "unable to rewire 'Elixir.ModuleDoesNotExist': cannot find module" do
        defmodule ModuleNotFound do
          import Rewire

          def func do
            rewire ModuleDoesNotExist, as: Rewired do
              # nothing
            end
          end
        end
      end
    end

    test "if option is invalid" do
      assert_compile_time_raise "unknown option passed to `rewire`: :invalid_option" do
        defmodule ModuleInvalidOption do
          import Rewire

          def func do
            rewire Rewire.ModuleWithAliasedDependency, invalid_option: true do
              # nothing
            end
          end
        end
      end
    end
  end
end
