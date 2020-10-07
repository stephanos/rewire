defmodule Rewire do
  @moduledoc """
  Rewire is a libary for replacing hard-wired dependencies of the module your unit testing.
  This allows you to keep your production code free of any unit testing-specific concerns.

  ## Usage

  ```elixir
  # this module has a hard-wired dependency on the `English` module
  defmodule Conversation do
    def start(), do: English.greet()
  end
  ```

  If you define the following `mox` mock:

  ```elixir
  # defining the mock in test_helper.exs
  Mox.defmock(EnglishMock, for: English)
  ```

  You can rewire the dependency in your unit test:

  ```elixir
  defmodule MyTest do
    use ExUnit.Case
    use Rewire
    import Mox

    # rewire dependency on `English` to `EnglishMock`
    rewire Conversation, English: EnglishMock

    test "start/0" do
      stub(EnglishMock, :greet, fn -> "g'day" end)
      assert Conversation.start() == "g'day"          # using the mock!
    end
  end
  ```

  You can also give the alias a different name using `as`:

  ```elixir
    rewire Conversation, English: EnglishMock, as: SmallTalk
  ```

  Alternatively, you can also rewire a module on a test-by-test basis:

  ```elixir
  defmodule MyTest do
    use ExUnit.Case
    use Rewire
    import Mox

    test "start/0" do
      rewire Conversation, English: EnglishMock do
        # within the block `Conversation` is rewired
        stub(EnglishMock, :greet, fn -> "g'day" end)
        assert Conversation.start() == "g'day"        # using the mock!
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
