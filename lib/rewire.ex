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

  defmacro __using__(_) do
    quote do
      # Needed for importing the `rewire` macro.
      import Rewire
    end
  end

  defmacro rewire(rewire_expr) do
    %{aliases: aliases} = __CALLER__
    Rewire.Alias.rewire_alias(rewire_expr, [], aliases)
  end

  defmacro rewire(rewire_expr, do: block) do
    %{aliases: aliases} = __CALLER__
    Rewire.Block.rewire_block(rewire_expr, [], aliases, block)
  end

  defmacro rewire(rewire_expr, opts) do
    %{aliases: aliases} = __CALLER__
    Rewire.Alias.rewire_alias(rewire_expr, opts, aliases)
  end

  defmacro rewire(rewire_expr, opts, do: block) do
    %{aliases: aliases} = __CALLER__
    Rewire.Block.rewire_block(rewire_expr, opts, aliases, block)
  end
end
