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
  end

end
