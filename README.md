rewire
===

[![Build Status](https://travis-ci.org/stephanos/rewire.svg?branch=master)](https://travis-ci.org/stephanos/rewire)
[![Hex.pm](https://img.shields.io/hexpm/v/rewire.svg)](https://hex.pm/packages/rewire)

Keep your application code free from dependency injection and mocking concerns by using `rewire` in your unit tests to inject module dependencies.

## Example

```elixir
defmodule Conversation do
  def start(), do: English.greet()      # the Converstaion module has a hard-wired dependency on the English module
end
```

You can rewire the dependency with a mock, using `mox` for example:

```elixir
defmodule MyTest do
  use ExUnit.Case
  use Rewire
  import Mox

  rewire Conversation, English: EnglishMock     # rewire the English dependency to the EnglishMock module (defined elsewhere)

  test "greet" do
    stub(EnglishMock, :greet, fn -> "bonjour" end)
    assert Conversation.start() == "bonjour"    # this uses EnglishMock now!
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
    rewire Conversation, English: EnglishMock do    # within the block it is rewired
      stub(EnglishMock, :greet, fn -> "bonjour" end)
      assert Conversation.start() == "bonjour"      # this uses EnglishMock now!
    end
  end
end
```

You can also give the alias a different name using `as`:

```elixir
  rewire Conversation, English: EnglishMock, as: SmallTalk
```

## FAQ

**Why?**

I have lots of modules that depend on other modules, and I haven't been happy with the existing tradeoffs of injecting those dependencies so I can alter their behavior in my unit tests.

For example, if you don't use `mox`, the best approach known to me is to pass-in dependencies via a function's parameters:

```elixir
defmodule Conversation do
  def start(mod \\ English), do: mod.greet()
end
```

The downsides to that approach are:

  1) Your application code is now littered with testing concerns.
  2) Navigation in your code editor doesn't work as well.
  3) Searches for usages of the module more difficult.
  4) The compiler is not able to warn you in case `greet/0` doesn't exist on the `English` module.

If you use `mox` for your mocking, there's a slightly better approach:

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

It works great with [mox](https://github.com/dashbitco/mox) since `rewire` focueses on the _injection_ and doesn't care about where the _mock_ module comes from. `rewire` and `mox` are a great pair!
