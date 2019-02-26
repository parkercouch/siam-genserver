defmodule Game.ServerTest do
  use ExUnit.Case
  doctest Game.Server

  test "Start Game Server" do
    {:ok, pid_one} = Game.Server.start()
    {:ok, pid_two} = Game.Server.start()

    assert pid_one != nil
    assert pid_one != pid_two
  end
end
