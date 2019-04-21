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
  alias Game.TurnState, as: TurnState

  @type select_action :: {Board.player, :select, TurnState.selectable}
  @type target_action :: {Board.player, :target, TurnState.selectable}

  @type finalize_confirmation :: Board.move_direction | :confirm
  @type finalize_action :: {Board.player, :finalize, finalize_confirmation}

  @type move_data :: select_action | target_action | finalize_action

  @type turn :: TurnState.t()

  @type move_response :: {:continue, turn} |
                         {:next, turn, turn} |
                         {:not_valid, String.t()} |
                         {:win, turn, turn}

  @doc """
  Send a move and current turn and get back:
  {:not_valid, message} - not a valid move (not enough push strength, etc)
  {:continue, updated_turn} - valid move, still on current turn
  {:next, current_turn, next_turn} - valid move, this action finishes turn
  {:win, current_turn, final_turn} - valid move, this action finishes turn and game
  """
  @spec process_move(move_data, turn) :: move_response
  def process_move({player, _, _}, %{current_player: current}) when player != current do
    {:not_valid, "It's not your turn!"}
  end

  def process_move({_player, :select, location}, turn) do
    handle_select(turn, location)
  end

  def process_move({_player, :target, target}, turn) do
    handle_target(turn, turn.selected, target)
  end

  def process_move({_player, :finalize, location}, turn) do
    handle_finalize(turn, location)
  end

  def process_move(_, _), do: {:not_valid, "That isn't a valid action"}

  #
  # Selecting
  #
  @spec handle_select(turn, TurnState.selectable) :: move_response
  defp handle_select(%{selected: s}, _location) when s != nil do
    {:not_valid, "Something is already selected"}
  end

  defp handle_select(turn = %TurnState{bullpen: bullpen, current_player: player}, :bullpen) do
    if bullpen[player] > 0 do
      {:continue, %{turn | selected: :bullpen}}
    else
      {:not_valid, "Your bullpen is empty"}
    end
  end

  defp handle_select(turn = %TurnState{board: board, current_player: player}, location = {_x, _y}) do
    if Board.get_player_at(board[location]) == player do
      {:continue, %{turn | selected: location}}
    else
      {:not_valid, "You must select your own piece"}
    end
  end

  defp handle_select(_, _), do: {:not_valid, "Not a valid selection"}

  #
  # Targeting
  #

  # Tryint to target before selecting
  @spec handle_target(turn, TurnState.selectable, TurnState.selectable) :: move_response
  defp handle_target(_turn, _selected = nil, _target) do
    # defp handle_target(_move, _turn, _selected = nil) do
    {:not_valid, "You must select something first"}
  end

  # Select bullpen then target square to move piece to
  defp handle_target(turn, _selected = :bullpen, target = {_x, _y}) do
    # defp handle_target({_x, _y} = location, turn, _selected = :bullpen) do
    # TODO: get rid of nested if
    if Board.on_edge?(target) do
      # Move if empty
      if Board.get_player_at(turn.board[target]) == :empty do
        {:continue, %{turn | targeted: target}}
      else
        # Check if pushable if occupied
        # TODO: update this once pushing logic is completed
        {:not_valid, "** Push from side not ready yet! **"}
      end
    else
      {:not_valid, "Can only move onto edge of board"}
    end
  end

  # Not valid target after selecting bullpen
  defp handle_target(_turn, _selected = :bullpen, _target), do: {:not_valid, "Not a valid target"}


  # Withdraw
  defp handle_target(turn, selected = {_x, _y}, _target = :bullpen) do
    # defp handle_target(_target = :bullpen, turn, {_x, _y} = selected) do
    %{board: board, current_player: player, bullpen: bullpen} = turn

    if Board.on_edge?(selected) do
      # TODO: Might offload to finalize function once it is done
      current_turn = %{turn | targeted: :bullpen, action: {:withdraw}}

      next_turn = %{
        turn
        | selected: nil,
          board: %{board | selected => {:empty}},
          bullpen: %{bullpen | player => bullpen[player] + 1}
      }

      {:next, current_turn, next_turn}
    else
      {:not_valid, "You must be on the edge to withdraw a piece"}
    end
  end

  # Target self
  defp handle_target(turn, selected = {_x, _y}, target) when selected == target do
    {:continue, %{turn | targeted: target}}
  end

  # Target another piece/square
  defp handle_target(turn = %TurnState{board: board}, selected = {_x, _y}, target) do
    if Board.is_orthogonal?(selected, target) do
      target_piece = board[target]
      move_or_push(turn, selected, target, target_piece)
    else
      {:not_valid, "You can't move more than 1 space or diagonal"}
    end
  end

  defp handle_target(_, _, _) do
    {:not_valid, "Not a valid target"}
  end

  @spec move_or_push(turn, TurnState.selectable, TurnState.selectable, Board.piece) :: move_response
  defp move_or_push(turn = %TurnState{board: board}, selected, target, {:empty}) do
    {:continue, %{turn | targeted: target, board: Board.move_piece(board, selected, target)}}
  end

  defp move_or_push(_turn = %TurnState{board: board}, selected, target, _target_piece) do
    if Board.is_in_front?(board, selected, target) do
      {:not_valid, "NOT READY YET"}
    else
      {:not_valid, "Can't push that direction"}
    end
  end



  #
  # Finalizing
  #
  @spec handle_finalize(turn, Board.move_direction) :: move_response
  defp handle_finalize(turn = %TurnState{winner: winner}, _location) when winner != nil do
    # TODO: Just putting this here to return a :win type to satisfy dialyzer
    {:win, turn, turn}
  end

  defp handle_finalize(_turn, _location) do
    {:not_valid, "** Finalize is not ready yet! **"}
  end
end
