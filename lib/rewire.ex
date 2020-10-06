defmodule Rewire do
  @moduledoc """
  Rewire is a libary for replacing hard-wired dependencies of the module your unit testing.
  This allows you to keep your production code free of any unit testing-specific concerns.

  ## Example

  ```elixir
  defmodule Conversation do
    def start(), do: English.greet()              # the dependency is hard-wired
  end
  ```

  You can rewire the dependency with a mock, using `mox` for example:

  ```elixir
  defmodule MyTest do
    use ExUnit.Case
    use Rewire
    import Mox

    rewire Conversation, English: Mock            # acts as an alias to the rewired module

    test "greet" do
      stub(Mock, :greet, fn -> "bonjour" end)
      assert Conversation.start() == "bonjour"    # this uses Mock now!
    end
  end
  ```

  ```elixir
  defmodule MyTest do
    use ExUnit.Case
    use Rewire
    import Mox

    rewire Conversation, English: Mock            # acts as an alias to the rewired module

    test "greet" do
      stub(Mock, :greet, fn -> "bonjour" end)
      assert Conversation.start() == "bonjour"    # this uses Mock now!
    end
  end
  ```

  Alternatively, you can also rewire a module on a test-by-test basis:

  ```elixir
  defmodule MyTest do
    use ExUnit.Case
    use Rewire
    import Mox

    test "greet" do
      rewire Conversation, English: Mock do       # within the block it is rewired
        stub(Mock, :greet, fn -> "bonjour" end)
        assert Conversation.start() == "bonjour"  # this uses Mock now!
      end
    end
  end
  ```

  You can also give the alias a different name using `as`:

  ```elixir
    rewire Conversation, English: Mock, as: SmallTalk
  ```
  """

  import Rewire.Utils

  defmacro __using__(_) do
    quote do
      # Needed for importing the `rewire` macro.
      import Rewire
    end
  end

  @doc """
  Macro that allows to rewire (and alias) a module.

  ```elixir
  use Rewire

  rewire App.ModuleToRewire, ModuleDep: Mock

  # `ModuleToRewire` will use `Mock` now
  end
  ```

  ## Options

  `opts` is a keyword list:

    * `as` - give the rewired module a different name

    * any other item, like `ModuleDep: Mock`, will be interpreted as a mapping from one module to another
  """
  defmacro rewire({:__aliases__, _, rewire_module_ast}, opts) do
    %{aliases: aliases} = __CALLER__
    opts = parse_opts(rewire_module_ast, opts, aliases)
    Rewire.Alias.rewire_alias(opts)
  end

  @doc """
  Macro that allows to rewire a module within a block.

  ```elixir
  use Rewire

  rewire App.ModuleToRewire, ModuleDep: Mock do
    # `ModuleToRewire` will use `Mock` now
  end
  ```

  See `rewire/2` for a description of options.
  """
  defmacro rewire({:__aliases__, _, rewire_module_ast}, opts, do: block) do
    %{aliases: aliases} = __CALLER__
    opts = parse_opts(rewire_module_ast, opts, aliases)
    Rewire.Block.rewire_block(opts, block)
  end
end
