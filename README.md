rewire
===

[![Build Status](https://travis-ci.org/stephanos/rewire.svg?branch=master)](https://travis-ci.org/stephanos/rewire)
[![Hex.pm](https://img.shields.io/hexpm/v/rewire.svg)](https://hex.pm/packages/rewire)

`rewire` is a **dependency injection** library.

It keeps your application code completely free from testing concerns.

And you can bring your own mock (`mox` is recommended).

## Installation

Just add `rewire` to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:rewire, "~> 0.4", only: :test}
  ]
end
```

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
  use Rewire                                     # (1) activate `rewire`
  import Mox

  rewire Conversation, English: EnglishMock      # (2) rewire `English` to `EnglishMock`

  test "start/0" do
    stub(EnglishMock, :greet, fn -> "g'day" end)
    assert Conversation.start() == "g'day"       # (3) test using the mock
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
  use Rewire                                       # (1) activate `rewire`
  import Mox

  test "start/0" do
    rewire Conversation, English: EnglishMock do   # (2) only rewired inside the block
      stub(EnglishMock, :greet, fn -> "g'day" end)
      assert Conversation.start() == "g'day"       # (3) test using the mock
    end
  end
end
```

This example uses `mox`, but `rewire` is mocking library-agnostic.

## FAQ

**Why?**

I haven't been happy with the existing tradeoffs of injecting dependencies into Elixir modules that allows me to alter their behavior in my unit tests.

For example, if you don't use `mox`, the best approach known to me is to pass-in dependencies via a function's parameters:

```elixir
defmodule Conversation do
  def start(mod \\ English), do: mod.greet()
end
```

The downsides to that approach are:

  1) Your application code is now littered with testing concerns.
  2) Navigation in your code editor doesn't work as well.
  3) Searches for usages of the module are more difficult.
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

**How do I stop `mix format` from adding parentheses around `rewire`?**

Add this to your `.formatter.exs` file:

```
import_deps: [:rewire]
```

**Does it work with `mox`?**

It works great with [mox](https://github.com/dashbitco/mox) since `rewire` focuses on the _injection_ and doesn't care about where the _mock_ module comes from. `rewire` and `mox` are a great pair!
