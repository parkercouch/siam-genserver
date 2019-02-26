defmodule Game.LogicTest do
  use ExUnit.Case
  doctest Game.Logic
  
  alias Game.Server, as: Server

  test "Move Elephant to Board" do
    {:ok, pid} = Server.start()
    moves = [
      {:elephant, :select, :elephant_pool},
      {:elephant, :target, {1, 1}},
      {:elephant, :rotate, :up},
    ]

    steps = Enum.map(
      moves,
      &(Server.move(pid, &1))
    )

    state = Server.get_state(pid)
    # IO.inspect(state)
    [next | [prev | _rest]] = state


    assert prev.board[{1, 1}] == {:empty}
    assert prev.current_player == :elephant
    assert prev.elephant_pool == 5
    assert prev.turn_number == 0
    assert prev.actions == [{}, {}, {}]

    assert next.board[{1, 1}] == {:elephant, :up}
    assert next.current_player == :rhino
    assert next.elephant_pool == 4
    assert next.turn_number == 1
    assert next.actions == []
  end
end