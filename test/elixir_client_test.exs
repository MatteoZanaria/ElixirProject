defmodule ElixirClientTest do
  use ExUnit.Case
  doctest ElixirClient

  test "greets the world" do
    assert ElixirClient.hello() == :world
  end
end
