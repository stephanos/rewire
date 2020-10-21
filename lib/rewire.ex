defmodule Rewire do
  @moduledoc """
  Rewire is a libary for replacing hard-wired dependencies of the module your unit testing.
  This keeps your production code free from any unit testing-specific concerns.

  ## Usage

  Given a module such as this:

  ```elixir
  # this module has a hard-wired dependency on the `English` module
  defmodule Conversation do
    def start(), do: English.greet()
  end
  ```

  If you define a `mox` mock `EnglishMock` you can rewire the dependency in your unit test:

  ```elixir
  defmodule MyTest do
    use ExUnit.Case
    import Rewire                                  # (1) activate `rewire`
    import Mox

    rewire Conversation, English: EnglishMock      # (2) rewire `English` to `EnglishMock`

    test "start/0" do
      stub(EnglishMock, :greet, fn -> "g'day" end)
      assert Conversation.start() == "g'day"       # (3) test using the mock
    end
  end
  ```

  This example uses `mox`, but `rewire` is mocking library-agnostic.

  You can use multiple `rewire`s and multiple overrides:

  ```elixir
    rewire Conversation, English: EnglishMock
    rewire OnlineConversation, Email: EmailMock, Chat: ChatMock
  ```

  You can also give the alias a different name using `as`:

  ```elixir
    rewire Conversation, English: EnglishMock, as: SmallTalk
  ```

  Alternatively, you can also rewire a module inside a block:

  ```elixir
    rewire Conversation, English: EnglishMock do   # (1) only rewired inside the block
      stub(EnglishMock, :greet, fn -> "g'day" end)
      assert Conversation.start() == "g'day"       # (2) test using the mock
    end
  ```
  """

  import Rewire.Utils

  # left for backwards-compability
  defmacro __using__(_) do
    quote do
      # Needed for importing the `rewire` macro.
      import Rewire
    end
  end

  @doc false
  defmacro rewire({:__aliases__, _, _}),
    do: invalid_rewire("options are missing", __CALLER__)

  @doc false
  defmacro rewire(_),
    do: invalid_rewire("the first argument must be a module", __CALLER__)

  @doc false
  defmacro rewire({:__aliases__, _, _}, do: _block),
    do: invalid_rewire("options are missing", __CALLER__)

  @doc """
  Macro that allows to rewire (and alias) a module.

  ```elixir
  import Rewire

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
    opts = parse_opts(rewire_module_ast, opts, __CALLER__)
    Rewire.Alias.rewire_alias(opts)
  end

  @doc """
  Macro that allows to rewire a module within a block.

  ```elixir
  import Rewire

  rewire App.ModuleToRewire, ModuleDep: Mock do
    # `ModuleToRewire` will use `Mock` now
  end
  ```

  See `rewire/2` for a description of options.
  """
  defmacro rewire({:__aliases__, _, rewire_module_ast}, opts, do: block) do
    opts = parse_opts(rewire_module_ast, opts, __CALLER__)
    Rewire.Block.rewire_block(opts, block)
  end

  @doc false
  defmacro rewire(_, _opts, do: _block),
    do: invalid_rewire("the first argument must be a module", __CALLER__)

  defp invalid_rewire(reason, %{file: file, line: line}),
    do:
      raise(CompileError,
        description: "unable to rewire: #{reason}",
        file: file,
        line: line
      )
end
