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
  {:next, current_turn, next_turn} - valid move, this action finishes turn
  {:win, current_turn, final_turn} - valid move, this action finishes turn and game
  """
  def process_move({player, _, _}, %{current_player: current}) when player != current do
    {:not_valid, "It's not your turn!"}
  end

  def process_move({_player, :select, location}, turn) do
    select(location, turn)
  end

  def process_move({_player, :target, location}, turn) do
    target(location, turn, turn.selected)
  end

  def process_move({_player, :finalize, location}, turn) do
    finalize(location, turn)
  end

  def process_move(_, _), do: {:not_valid, "That isn't a valid action"}

  defp select(_location, %{selected: s}) when s != nil do
    {:not_valid, "Something is already selected"}
  end

  defp select(:bullpen, %{bullpen: bullpen, current_player: player} = turn) do
    if bullpen[player] > 0 do 
      {:continue, %{turn | selected: :bullpen}}
    else
      {:not_valid, "Your bullpen is empty"}
    end
  end

  defp select({_x, _y} = location, %{board: board, current_player: player} = turn) do
    if Board.get_player_at(board[location]) == player do
      {:continue, %{turn | selected: location}}
    else
      {:not_valid, "You must select your own piece"}
    end
  end

  defp select(_, _), do: {:not_valid, "Not a valid selection"}

  defp target(_move, _turn, _selected = nil) do
    {:not_valid, "You must select something first"}
  end

  defp target(location, turn, :bullpen) do
    {:not_valid, "** bullpen -> board is not ready yet **"}
  end

  defp target(_, _, _) do
    {:not_valid, "Not a valid target"}
  end

  defp finalize(location, turn) do
    {:not_valid, "** Finalize is not ready yet! **"}
  end
end
