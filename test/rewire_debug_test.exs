defmodule RewireDebugTest do
  use ExUnit.Case
  import TestHelpers

  test "debug mode" do
    output =
      capture_compile_time_io do
        import Rewire

        rewire Rewire.Hello, as: Hello, debug: true do
          :ok
        end
      end

    actual =
      output
      |> String.replace(~r/:R[0-9]+/, ":R")
      |> String.replace(~r/\.R[0-9]+/, ".R")
      |> String.replace(":\"::\"", ":::")
      |> String.split("\n")

    expected = [
      "\e[94m[Rewire] [Elixir.Rewire.Hello] old name: [:Rewire, :Hello]\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] new name: [:Rewire, :Hello, :R]\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] alias: :Hello\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] overrides: %{}\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] source path: fixtures/hello.ex\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] original AST:",
      "",
      "{:defmodule, [line: 1],",
      " [",
      "   {:__aliases__, [line: 1], [:Rewire, :Hello]},",
      "   [",
      "     do: {:__block__, [],",
      "      [",
      "        {:@, [line: 2],",
      "         [",
      "           {:callback, [line: 2],",
      "            [",
      "              {:::, [line: 2],",
      "               [",
      "                 {:hello, [line: 2], []},",
      "                 {{:., [line: 2], [{:__aliases__, [line: 2], [:String]}, :t]},",
      "                  [line: 2], []}",
      "               ]}",
      "            ]}",
      "         ]},",
      "        {:def, [line: 3], [{:hello, [line: 3], []}, [do: \"hello\"]]}",
      "      ]}",
      "   ]",
      " ]}",
      "",
      "\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] found module: [:Rewire, :Hello]\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] new AST:",
      "",
      "{:defmodule, [line: 1],",
      " [",
      "   {:__aliases__, [line: 1], [:Rewire, :Hello, :R]},",
      "   [",
      "     do: [",
      "       {:def, [line: 0],",
      "        [",
      "          {:__rewire__, [line: 0], []},",
      "          [",
      "            do: {:%{}, [line: 0],",
      "             [original: [:Rewire, :Hello], rewired: {:%{}, [line: 0], []}]}",
      "          ]",
      "        ]},",
      "       {:@, [line: 2],",
      "        [",
      "          {:callback, [line: 2],",
      "           [",
      "             {:::, [line: 2],",
      "              [",
      "                {:hello, [line: 2], []},",
      "                {{:., [line: 2], [{:__aliases__, [line: 2], [:String]}, :t]},",
      "                 [line: 2], []}",
      "              ]}",
      "           ]}",
      "        ]},",
      "       {:def, [line: 3], [{:hello, [line: 3], []}, [do: \"hello\"]]}",
      "     ]",
      "   ]",
      " ]}",
      "",
      "\e[0m",
      "\e[94m[Rewire] [Elixir.Rewire.Hello] new code:",
      "",
      "defmodule(Rewire.Hello.R) do",
      "  [def(__rewire__()) do",
      "    %{original: [:Rewire, :Hello], rewired: %{}}",
      "  end, @callback(hello() :: String.t()), def(hello()) do",
      "    \"hello\"",
      "  end]",
      "end",
      "\e[0m",
      ""
    ]

    assert actual == expected
  end
end
