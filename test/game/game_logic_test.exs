defmodule Game.LogicTest do
  use ExUnit.Case
  doctest Game.Logic

  alias Game.Server, as: Server

  test "Select Bullpen" do
    {:ok, pid} = Server.start()
    
    {_, %{actions: actions, bullpen: bullpen}} = Server.move(pid, {:elephant, :select, :bullpen})
    [turn | []] = Server.get_state(pid)

    assert actions == [{:elephant, :select, :bullpen}]
    assert bullpen[:elephant] == 5
    assert turn.actions == actions
  end

  test "Selecting a non-valid piece" do
    {:ok, pid} = Server.start()
    
    # Make sure server rejects selecting an empty square
    {type, _message} = Server.move(pid, {:elephant, :select, {1, 1}})
    assert type == :not_valid

    # There should be no actions added
    [turn | []] = Server.get_state(pid)
    assert turn.actions == []

    # Make sure server rejects selecting a mountain
    {type, _message} = Server.move(pid, {:elephant, :select, {3, 3}})
    assert type == :not_valid

    # There should be no actions added
    [turn | []] = Server.get_state(pid)
    assert turn.actions == []
  end

  test "Move Elephant to Board" do
    {:ok, pid} = Server.start()

    moves = [
      {:elephant, :select, :bullpen},
      {:elephant, :target, {1, 1}},
      {:elephant, :rotate, :up}
    ]

    Enum.map(
      moves,
      &Server.move(pid, &1)
    )

    state = Server.get_state(pid)
    # IO.inspect(state)
    [next | [prev | _rest]] = state

    assert prev.board[{1, 1}] == {:empty}
    assert prev.current_player == :elephant
    assert prev.bullpen[:elephant] == 5
    assert prev.turn_number == 0
    assert prev.actions == [{}, {}, {}]

    assert next.board[{1, 1}] == {:elephant, :up}
    assert next.current_player == :rhino
    assert next.bullpen[:elephant] == 4
    assert next.turn_number == 1
    assert next.actions == []
  end
end
