defmodule ShowtimeExTest do
  use ExUnit.Case

  test "join server" do
    assert ShowtimeEx.Bridge.join("ws://localhost:40005", "elixir_test") == :ok
  end

  test "leave server" do
    ShowtimeEx.Bridge.join("ws://localhost:40005", "elixir_test")
    assert ShowtimeEx.Bridge.leave("elixir_test", "QUIT") == :ok
  end
end
