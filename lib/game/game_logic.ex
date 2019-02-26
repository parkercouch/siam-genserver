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

  @doc """
  Send a move and current turn and get back:
  {:continue, updated_turn} - valid move, still on current turn
  {:not_valid, message} - not a valid move (not enough push strength, etc)
  {:next, next_turn} - valid move, this action finishes turn
  {:win, final_turn} - valid move, this action finishes turn and game
  """
  def process_move(move_data, current_turn) do
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