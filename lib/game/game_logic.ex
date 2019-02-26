defmodule Game.Logic do
  @moduledoc """
  Game logic for Siam
  Use process_move to interface with this

  Game flow looks like this:
  Turns: Elephants and Rhinos get one complete action per turn
  Actions: 
    Select - select piece or square
    Target - Select target of push/move/rotate
    Finalize(Rotate) - Select rotation (or confirm push)
  """

  alias Game.Board, as: Board

  @doc """
  Send a move and current turn and get back:
  {:not_valid, message} - not a valid move (not enough push strength, etc)
  {:continue, updated_turn} - valid move, still on current turn
  {:next, next_turn} - valid move, this action finishes turn
  {:win, final_turn} - valid move, this action finishes turn and game
  """
  def process_move({player, _, _}, %{current_player: current}) when player != current do
    {:error, "It's not your turn!"}
  end
  def process_move({_, :select, _}, %{actions: [_]} = current_turn) do
    {:error, "Something is already selected"}
  end
  def process_move({player, :select, location} = move, %{board: board} = state) do
    # Valid move if:
    # Select own bullpen and it has pieces
    # state.bullpen[player] > 0
    # Select own piece
    # player == Board.get_player(board[location])
    # Select square on edge of board
  end
  def process_move({player, :target, location} = move_data, current_turn) do
  end
  def process_move({player, :rotate, direction} = move_data, current_turn) do
    case auto_add(move_data, current_turn) do
      {:continue, _updated_turn} = response ->
        response
      {:not_valid, _message} = response ->
        response
      {:next, _next_turn}  = response ->
        response
      {:win, _final_turn}  = response ->
        response
    end
  end

  @doc """
  Automatically returns a valid move
  for testing purposes
  """
  def auto_no(_move, _turn) do
    {:not_valid, "You can't move that piece there"}
  end

  @doc """
  Moves a elephant to the board
  To test initial moves
  """
  def auto_add(_move, turn) do
    next_turn = %{turn | elephant_pool: turn.elephant_pool - 1,
      board: %{turn.board | {1,1} => {:elephant, :up}},
      current_player: :rhino,
      turn_number: turn.turn_number + 1,
      actions: []
    }
    {:next, next_turn}
  end
end