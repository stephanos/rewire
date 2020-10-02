rewire
===

[![Build Status](https://travis-ci.org/stephanos/rewire.svg?branch=master)](https://travis-ci.org/stephanos/rewire)
[![Hex.pm](https://img.shields.io/hexpm/v/rewire.svg)](https://hex.pm/packages/rewire)

Keep your code free from dependency injection and mocking concerns by using `rewire` in your unit tests to stub out any module dependencies.

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

## FAQ

**Why?**

I haven't been happy with the existing tradeoffs of making a module with dependencies easily unit testable.

If you don't use `mox`, the best approach known to me is to pass-in dependencies via a function's parameters:

```elixir
defmodule Conversation do
  def start(mod \\ English), do: mod.greet()
end
```

But this will (1) litter your code with testing concerns, (2) make navigation in your editor harder, (3) searches for usages of the module more difficult and (4) make it impossible for the compiler to warn you in case `greet/0` doesn't exist on the `English` module

If you use `mox`, there's a slightly better approach:

```elixir
defmodule Conversation do
  def start(), do: english().greet()
  defp english(), do: Application.get(:myapp, :english, English)
end
```

In this approach we use the app's config to replace a module with a `mox` mock during testing. This is a little better in my opinion, but still comes with most of the disadvantages described above.

**Witchcraft! How does this work??**

Simply put, `rewire` will create a copy of the module to rewire under a new name, replacing all hard-coded module references that should be changed in the process. Plus, it rewrites the test code in the `rewire` block to use the generated module instead.

**Will that slow down my tests?**

Possibly just a little? Conclusive data isn't in yet.

**Does it work with `mox`?**

It works great with [mox](https://github.com/dashbitco/mox) since `rewire` doesn't care about where the replacement module comes from. `rewire` and `mox` are a great pair!
