rewire
===

[![Build Status](https://travis-ci.org/stephanos/rewire.svg?branch=master)](https://travis-ci.org/stephanos/rewire)
[![Hex.pm](https://img.shields.io/hexpm/v/rewire.svg)](https://hex.pm/packages/rewire)

Keep your code free from dependency injection and mocking concerns by using `rewire` in your unit tests to stub out any module dependencies:

```elixir
defmodule MyModule do
  def do_something(), do: MyDep.foo()
end


defmodule MyTest do
  use ExUnit.Case
  use Rewire

  defmodule MyMock do
    def foo(), do: "bar"
  end

  test "my test" do
    rewire MyModule, MyDep: MyMock do
      assert MyModule.foo() == "bar"
    end
  end
end
```

## FAQ

**Witchcraft! How does this work??**

Simply put, `rewire` will create a copy of the module to rewire under a new name, replacing all hard-coded module references that should be changed in the process. Plus, it rewrites the test code in the `rewire` block to use the generated module instead.

**Will that slow down my tests?**

Possibly just a little? Conclusive data isn't in yet.

**Does it work with `mox`?**

It works great with [mox](https://github.com/dashbitco/mox) since `rewire` doesn't care about where the replacement module comes from. `rewire` and `mox` are a great pair!
