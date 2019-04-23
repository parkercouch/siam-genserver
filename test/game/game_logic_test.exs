defmodule Game.LogicTest do
  @moduledoc false

  use ExUnit.Case
  doctest Game.Logic

  alias Game.Logic, as: Logic
  alias Game.TurnState, as: TurnState


  test "Move elephant to the board" do
    turn = %TurnState{}

    select_move = {:elephant, :select, :bullpen}
    target_move = {:elephant, :target, {1, 2}}
    finalize_move = {:elephant, :finalize, :up}

    assert {:continue , turn_after_select} = Logic.process_move(turn, select_move)
    assert turn_after_select.selected == :bullpen

    assert {:continue , turn_after_target} = Logic.process_move(turn_after_select, target_move)
    assert turn_after_target.targeted == {1, 2}

    assert {:next , turn_after_finalize, next_turn} = Logic.process_move(turn_after_target, finalize_move)

    assert turn_after_finalize.action == {:move_and_rotate, :up}
    assert turn_after_finalize.completed == true

    assert next_turn.bullpen.elephant == 4
    assert next_turn.board[{1, 2}] == {:elephant, :up}
  end

  test "Move elephant to empty square" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}}
    turn = %{turn | board: board}

    select_move = {:elephant, :select, {1, 1}}
    target_move = {:elephant, :target, {1, 2}}
    finalize_move = {:elephant, :finalize, :up}

    assert {:continue , turn_after_select} = Logic.process_move(turn, select_move)
    assert turn_after_select.selected == {1, 1}

    assert {:continue , turn_after_target} = Logic.process_move(turn_after_select, target_move)
    assert turn_after_target.targeted == {1, 2}

    assert {:next , turn_after_finalize, next_turn} = Logic.process_move(turn_after_target, finalize_move)

    assert turn_after_finalize.action == {:move_and_rotate, :up}
    assert turn_after_finalize.completed == true

    assert turn_after_finalize.board[{1, 1}] == {:elephant, :up}
    assert turn_after_finalize.board[{1, 2}] == {:empty}

    assert next_turn.board[{1, 1}] == {:empty}
    assert next_turn.board[{1, 2}] == {:elephant, :up}
  end

  test "Elephant pushes rhino facing sideways" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}, {1, 2} => {:rhino, :left}}
    turn = %{turn | board: board}

    select_move = {:elephant, :select, {1, 1}}
    target_move = {:elephant, :target, {1, 2}}
    finalize_move = {:elephant, :finalize, :confirm}

    assert {:continue , turn_after_select} = Logic.process_move(turn, select_move)
    assert turn_after_select.selected == {1, 1}

    assert {:continue , turn_after_target} = Logic.process_move(turn_after_select, target_move)
    assert turn_after_target.targeted == {1, 2}

    assert {:next , turn_after_finalize, next_turn} = Logic.process_move(turn_after_target, finalize_move)

    assert turn_after_finalize.action == {:push, :up}
    assert turn_after_finalize.completed == true
    assert turn_after_finalize.board[{1, 1}] == {:elephant, :up}
    assert turn_after_finalize.board[{1, 2}] == {:rhino, :left}
    assert turn_after_finalize.board[{1, 3}] == {:empty}

    assert next_turn.board[{1, 1}] == {:empty}
    assert next_turn.board[{1, 2}] == {:elephant, :up}
    assert next_turn.board[{1, 3}] == {:rhino, :left}
  end

  test "Elephant pushes mountain" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {2, 2} => {:elephant, :up}}
    turn = %{turn | board: board}

    select_move = {:elephant, :select, {2, 2}}
    target_move = {:elephant, :target, {2, 3}}
    finalize_move = {:elephant, :finalize, :confirm}

    assert {:continue , turn_after_select} = Logic.process_move(turn, select_move)
    assert turn_after_select.selected == {2, 2}

    assert {:continue , turn_after_target} = Logic.process_move(turn_after_select, target_move)
    assert turn_after_target.targeted == {2, 3}

    assert {:next , turn_after_finalize, next_turn} = Logic.process_move(turn_after_target, finalize_move)

    assert turn_after_finalize.action == {:push, :up}
    assert turn_after_finalize.completed == true

    assert turn_after_finalize.board[{2, 2}] == {:elephant, :up}
    assert turn_after_finalize.board[{2, 3}] == {:mountain, :neutral}
    assert turn_after_finalize.board[{2, 4}] == {:empty}

    assert next_turn.board[{2, 2}] == {:empty}
    assert next_turn.board[{2, 3}] == {:elephant, :up}
    assert next_turn.board[{2, 4}] == {:mountain, :neutral}
  end

  test "Elephant withdraws" do
    turn = %{board: board, bullpen: bullpen} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}}
    bullpen = %{bullpen | elephant: 4}
    turn = %{turn | board: board, bullpen: bullpen}

    select_move = {:elephant, :select, {1, 1}}
    target_move = {:elephant, :target, :bullpen}
    finalize_move = {:elephant, :finalize, :confirm}

    assert {:continue , turn_after_select} = Logic.process_move(turn, select_move)
    assert turn_after_select.selected == {1, 1}

    assert {:continue , turn_after_target} = Logic.process_move(turn_after_select, target_move)
    assert turn_after_target.targeted == :bullpen

    assert {:next , turn_after_finalize, next_turn} = Logic.process_move(turn_after_target, finalize_move)

    assert turn_after_finalize.action == {:withdraw}
    assert turn_after_finalize.completed == true
    assert turn_after_finalize.bullpen.elephant == 4
    assert next_turn.bullpen.elephant == 5
    assert next_turn.board[{1, 1}] == {:empty}
  end

  test "Elephant rotates in place" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}}
    turn = %{turn | board: board}

    select_move = {:elephant, :select, {1, 1}}
    target_move = {:elephant, :target, {1, 1}}
    finalize_move = {:elephant, :finalize, :right}

    assert {:continue , turn_after_select} = Logic.process_move(turn, select_move)
    assert turn_after_select.selected == {1, 1}

    assert {:continue , turn_after_target} = Logic.process_move(turn_after_select, target_move)
    assert turn_after_target.targeted == {1, 1}

    assert {:next , turn_after_finalize, next_turn} = Logic.process_move(turn_after_target, finalize_move)

    assert turn_after_finalize.action == {:rotate_in_place, :right}
    assert turn_after_finalize.completed == true
    assert next_turn.board[{1, 1}] == {:elephant, :right}
  end
end
