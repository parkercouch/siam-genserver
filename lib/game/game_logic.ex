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

  #
  # Selecting
  #
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

  #
  # Targeting
  #
  defp target(_move, _turn, _selected = nil) do
    {:not_valid, "You must select something first"}
  end

  defp target({_x, _y} = location, turn, _selected = :bullpen) do
    # TODO: get rid of nested if
    if Board.on_edge?(location) do
      # Move if empty
      if Board.get_player_at(turn.board[location]) == :empty do
        {:continue, %{turn | targeted: location}}
      else
      # Check if pushable if occupied
        # TODO: update this once pushing logic is completed
        {:not_valid, "** Push from side not ready yet! **"}
      end
    else
      {:not_valid, "Can only move onto edge of board"}
    end
  end

  defp target(_location, turn, _selected = :bullpen), do: {:not_valid, "Not a valid target"}

  defp target(:bullpen, turn, {_x, _y} = selected) do
    %{board: board, current_player: player, bullpen: bullpen} = turn

    if Board.on_edge?(selected) do
      # TODO: Might offload to finalize function once it is done
      current_turn = %{turn | targeted: :bullpen, action: {:withdraw}}
      next_turn = %{turn |
        selected: nil,
        board: %{board | selected => {:empty}},
        bullpen: %{bullpen | bullpen[player] => bullpen[player] + 1}
      }
      {:next, current_turn, next_turn}
    else
      {:not_valid, "You must be on the edge to withdraw a piece"}
    end
  end

  defp target(location, turn, {_x, _y} = selected) when location == selected do
    {:continue, %{turn | targeted: location}}
  end

  defp target(_, _, _) do
    {:not_valid, "Not a valid target"}
  end

  #
  # Finalizing
  #
  defp finalize(location, turn) do
    {:not_valid, "** Finalize is not ready yet! **"}
  end
end
