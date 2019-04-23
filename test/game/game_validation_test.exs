defmodule Game.ValidationTest do
  @moduledoc false

  use ExUnit.Case
  doctest Game.Validation

  alias Game.Validation, as: Validation
  alias Game.TurnState, as: TurnState

  #
  # SELECTING
  #
  test "Trying to issue a move as the wrong player" do
    turn = %TurnState{}
    move = {:rhino, :select, :bullpen}
    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not valid to select when already selected" do
    turn = %TurnState{}
    turn = %{turn | selected: :bullpen}
    move = {:elephant, :select, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not valid to select your own empty Bullpen" do
    turn = %{bullpen: bullpen} = %TurnState{}
    bullpen = %{bullpen | elephant: 0}
    turn = %{turn | bullpen: bullpen}
    move = {:elephant, :select, :bullpen}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to select your own full Bullpen" do
    turn = %TurnState{}
    move = {:elephant, :select, :bullpen}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Valid to select your own piece" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}}
    turn = %{turn | board: board}
    move = {:elephant, :select, {1, 1}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to select a mountain" do
    turn = %TurnState{}
    move = {:elephant, :select, {2, 3}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to select opponents piece" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :up}}
    turn = %{turn | board: board}
    move = {:elephant, :select, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to select empty space" do
    turn = %TurnState{}
    move = {:elephant, :select, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  #
  # TARGETING
  #
  test "Not Valid to target before selecting" do
    turn = %TurnState{}
    move = {:elephant, :target, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to target empty edge piece after selecting bullpen" do
    turn = %TurnState{}
    turn = %{turn | selected: :bullpen}
    move = {:elephant, :target, {1, 1}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to target empty square NOT on edge after selecting bullpen" do
    turn = %TurnState{}
    turn = %{turn | selected: :bullpen}
    move = {:elephant, :target, {2, 2}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to target bullpen after selecting bullpen" do
    turn = %TurnState{}
    turn = %{turn | selected: :bullpen}
    move = {:elephant, :target, :bullpen}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to target edge piece after bullpen if push strength is not enough" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:rhino, :left}}
    turn = %{turn | board: board, selected: :bullpen}
    move = {:elephant, :target, {1, 2}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to target edge piece after bullpen if push strength is enough" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:rhino, :up}}
    turn = %{turn | board: board, selected: :bullpen}
    move = {:elephant, :target, {1, 2}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Valid to target edge piece after bullpen if pushing same direction" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {2, 5} => {:rhino, :down}}
    turn = %{turn | board: board, selected: :bullpen}
    move = {:elephant, :target, {2, 5}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to target corner piece after bullpen if push strength is not enough" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :left}, {1, 2} => {:rhino, :down}}
    turn = %{turn | board: board, selected: :bullpen}
    move = {:elephant, :target, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to target corner piece after bullpen if push strength is enough in either direction" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :down}, {1, 2} => {:rhino, :down}}
    turn = %{turn | board: board, selected: :bullpen}
    move = {:elephant, :target, {1, 1}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Valid to target bullpen after selecting piece on edge" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, :bullpen}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to target bullpen after selecting piece in middle" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {2, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {2, 2}}
    move = {:elephant, :target, :bullpen}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to target selected piece" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {1, 2}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Valid to target empty square next to selected" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {2, 2}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to target empty square diagonal to selected" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {2, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to target empty square more than 1 space away from selected" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {5, 2}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to target piece Not in front of selected" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}, {2, 2} => {:rhino, :up}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {2, 2}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to target piece in front of selected if enough push strength" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}, {1, 1} => {:rhino, :left}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {1, 1}}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to target piece in front of selected if Not enough push strength" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}, {1, 1} => {:rhino, :up}}
    turn = %{turn | board: board, selected: {1, 2}}
    move = {:elephant, :target, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to send target when already targeting something" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :down}, {1, 2} => {:rhino, :down}}

    turn = %{
      turn
      | board: board,
        selected: :bullpen,
        targeted: {1, 2},
        action: {:push_from_off_board, :down}
    }

    move = {:elephant, :target, {1, 1}}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  #
  # FINALIZING
  #
  test "Valid to :confirm push (from on board)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}, {1, 1} => {:rhino, :left}}
    turn = %{turn | board: board, selected: {1, 2}, targeted: {1, 1}, action: {:push, :down}}
    move = {:elephant, :finalize, :confirm}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Valid to :confirm withdraw (select edge, target bullpen)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}
    turn = %{turn | board: board, selected: {1, 2}, targeted: :bullpen, action: {:withdraw}}
    move = {:elephant, :finalize, :confirm}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to :confirm move (needs direction)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: {1, 2},
        targeted: {1, 1},
        action: {:move_and_rotate, :down}
    }

    move = {:elephant, :finalize, :confirm}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to :confirm rotate (needs direction)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: {1, 2},
        targeted: {1, 2},
        action: {:rotate_in_place, :down}
    }

    move = {:elephant, :finalize, :confirm}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to :confirm push from edge (needs direction)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: :bullpen,
        targeted: {1, 1},
        action: {:push_from_off_board, :right}
    }

    move = {:elephant, :finalize, :confirm}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to finalize with non-direction :not_valid_direction" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: {1, 1},
        targeted: {1, 2},
        action: {:move_and_rotate, :down}
    }

    move = {:elephant, :finalize, :not_valid_direction}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to confirm push with direction (:up...)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}, {1, 2} => {:rhino, :right}}
    turn = %{turn | board: board, selected: {1, 1}, targeted: {1, 2}, action: {:push, :up}}
    move = {:elephant, :finalize, :up}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to confirm withdraw with direction (:up...)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:elephant, :up}, {1, 2} => {:rhino, :right}}
    turn = %{turn | board: board, selected: {1, 1}, targeted: :bullpen, action: {:withdraw}}
    move = {:elephant, :finalize, :up}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to finalize move with direction (:up...)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: {1, 2},
        targeted: {1, 1},
        action: {:move_and_rotate, :down}
    }

    move = {:elephant, :finalize, :right}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to finalize rotate in place with same direction as the piece started with" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: {1, 2},
        targeted: {1, 2},
        action: {:rotate_in_place, :down}
    }

    move = {:elephant, :finalize, :down}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to finalize rotate in place with different direction than the piece started with" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 2} => {:elephant, :down}}

    turn = %{
      turn
      | board: board,
        selected: {1, 2},
        targeted: {1, 2},
        action: {:rotate_in_place, :down}
    }

    move = {:elephant, :finalize, :up}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to finalize push_from_off_board into corner, when direction can't be pushed (not enough str)" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :down}, {1, 2} => {:rhino, :down}}

    turn = %{
      turn
      | board: board,
        selected: :bullpen,
        targeted: {1, 1},
        action: {:push_from_off_board, :down}
    }

    move = {:elephant, :finalize, :up}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Valid to finalize push_from_off_board into corner, when that direction can be pushed" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :down}, {1, 2} => {:rhino, :down}}

    turn = %{
      turn
      | board: board,
        selected: :bullpen,
        targeted: {1, 1},
        action: {:push_from_off_board, :down}
    }

    move = {:elephant, :finalize, :right}

    assert :valid = Validation.validate_move(turn, move)
  end

  test "Not Valid to finalize push_from_off_board into corner with incorrect direction" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :down}, {1, 2} => {:rhino, :down}}

    turn = %{
      turn
      | board: board,
        selected: :bullpen,
        targeted: {1, 1},
        action: {:push_from_off_board, :down}
    }

    move = {:elephant, :finalize, :down}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end

  test "Not Valid to finalize push_from_off_board into edge with incorrect direction" do
    turn = %{board: board} = %TurnState{}
    board = %{board | {1, 1} => {:rhino, :down}, {1, 2} => {:rhino, :down}}

    turn = %{
      turn
      | board: board,
        selected: :bullpen,
        targeted: {1, 2},
        action: {:push_from_off_board, :down}
    }

    move = {:elephant, :finalize, :up}

    assert {:not_valid, _message} = Validation.validate_move(turn, move)
  end
end
