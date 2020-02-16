defmodule ElixirDockerTestTest do
  use ExUnit.Case
  doctest ElixirDockerTest

  test "greets the world" do
    assert ElixirDockerTest.hello() == :world
  end
end
