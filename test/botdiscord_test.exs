defmodule BotdiscordTest do
  use ExUnit.Case
  doctest Botdiscord

  test "greets the world" do
    assert Botdiscord.hello() == :world
  end
end
