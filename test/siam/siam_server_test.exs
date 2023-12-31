defmodule Siam.ServerTest do
  @moduledoc false

  use ExUnit.Case
  doctest Siam.Server

  test "Start Siam.Server" do
    {:ok, pid_one} = Siam.Server.start()
    {:ok, pid_two} = Siam.Server.start()

    assert pid_one != nil
    assert pid_one != pid_two
  end

  test "No Undo turn on first turn" do
    {:ok, pid} = Siam.Server.start()
    {response, _message} = Siam.Server.undo_turn(pid)

    assert response == :error
  end
end
