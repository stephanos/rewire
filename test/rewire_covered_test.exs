defmodule RewireCoveredTest do
  use ExUnit.Case
  import Rewire

  # Set up for coverage validation in fixtures/test_cover.ex
  # This should add up to a total of 8 calls to Rewire.Covered.hello/0

  test "the module being rewired reports test coverage" do
    rewire Rewire.Covered, Hello: Bonjour

    # Two through the original module
    assert Rewire.Covered.hello() == "hello"
    assert Rewire.Covered.hello() == "hello"
    # And two through the rewired copy
    assert Covered.hello() == "bonjour"
    assert Covered.hello() == "bonjour"
  end

  test "coverage from second rewire stacks with the first" do
    rewire Rewire.Covered, Hello: Bonjour
    assert Rewire.Covered.hello() == "hello"
    assert Rewire.Covered.hello() == "hello"
    assert Covered.hello() == "bonjour"
    assert Covered.hello() == "bonjour"
  end
end
