defmodule Game.Validation do
  @moduledoc """
  Functions for validating incoming moves before processing
  """

  require Game.Board, as: Board
  alias Game.TurnState, as: TurnState

  @type select_action :: {Board.player, :select, TurnState.selectable}
  @type target_action :: {Board.player, :target, TurnState.selectable}

  @type finalize_confirmation :: Board.move_direction | :confirm
  @type finalize_action :: {Board.player, :finalize, finalize_confirmation}

  @type move_data :: select_action | target_action | finalize_action

  @type turn :: TurnState.t()

  @type validation_response :: {:not_valid, String.t()} | :valid


  @doc """
  Runs move data through validation to make sure it is a move that can
  be performed before processing it

  :valid on valid move
  {:not_valid, reason} on invalid move
  """
  @spec validate_move(turn, move_data) :: validation_response
  def validate_move(%{current_player: current}, {player, _, _}) when player != current do
    {:not_valid, "It's not your turn!"}
  end

  def validate_move(turn, {_player, :select, location}) do
    validate_select(turn, location)
  end

  def validate_move(turn, {_player, :target, target}) do
    validate_target(turn, turn.selected, target)
  end

  def validate_move(turn, {_player, :finalize, location}) do
    validate_finalize(turn, location)
  end

  def validate_move(_, _), do: {:not_valid, "That isn't a valid action"}

  #
  # Selecting
  #
  @spec validate_select(turn, TurnState.selectable) :: validation_response
  defp validate_select(%{selected: s}, _location) when s != nil do
    {:not_valid, "Something is already selected"}
  end

  defp validate_select(_turn = %TurnState{bullpen: bullpen, current_player: player}, :bullpen) do
    if bullpen[player] > 0 do
      :valid
    else
      {:not_valid, "Your bullpen is empty"}
    end
  end

  defp validate_select(_turn = %TurnState{board: board, current_player: player}, location = {_x, _y}) do
    if Board.get_player_at(board[location]) == player do
      :valid
    else
      {:not_valid, "You must select your own piece"}
    end
  end

  defp validate_select(_, _), do: {:not_valid, "Not a valid selection"}


  #
  # Targeting
  #

  @spec validate_target(turn, TurnState.selectable, TurnState.selectable) :: validation_response
  # Trying to target before selecting
  defp validate_target(_turn, _selected = nil, _target) do
    {:not_valid, "You must select something first"}
  end

  # Trying to target again
  defp validate_target(_turn = %TurnState{targeted: targeted}, _selected, _target) when targeted != nil do
    {:not_valid, "Something is already targeted!"}
  end

  # Select bullpen then target square to move piece to
  defp validate_target(turn = %TurnState{board: board}, _selected = :bullpen, target = {_x, _y}) do
    if Board.on_edge?(target) do
      if Board.get_player_at(turn.board[target]) == :empty do
        :valid
      else
        validate_push_from_edge(board, target)
      end
    else
      {:not_valid, "Can only move onto edge of board"}
    end
  end


  # Not valid target after selecting bullpen
  defp validate_target(_turn, _selected = :bullpen, _target), do: {:not_valid, "Not a valid target"}


  # Withdraw
  defp validate_target(_turn, selected = {_x, _y}, _target = :bullpen) do
    if Board.on_edge?(selected) do
      :valid
    else
      {:not_valid, "You must be on the edge to withdraw a piece"}
    end
  end

  # Target self
  defp validate_target(_turn, selected = {_x, _y}, target) when selected == target do
    :valid
  end

  # Target another piece/square
  defp validate_target(turn = %TurnState{board: board}, selected = {_x, _y}, target) do
    if Board.is_orthogonal?(selected, target) do
      target_piece = board[target]
      validate_move_or_push(turn, selected, target, target_piece)
    else
      {:not_valid, "You can't move more than 1 space or diagonal"}
    end
  end

  defp validate_target(_, _, _) do
    {:not_valid, "Not a valid target"}
  end



  @spec validate_move_or_push(turn, TurnState.selectable, TurnState.selectable, Board.piece) :: validation_response
  defp validate_move_or_push(_turn, _selected, _target, {:empty}), do: :valid

  defp validate_move_or_push(_turn = %TurnState{board: board}, selected, target, _target_piece) do
    if Board.is_in_front?(board, selected, target) do
      validate_push(board, selected)
    else
      {:not_valid, "Can't push that direction"}
    end
  end

  defp validate_push(board, pusher_coords) do
    if Board.is_pushable?(board, pusher_coords) do
      :valid
    else
      {:not_valid, "Not enough push strength"}
    end
  end

  @spec validate_finalize(turn, finalize_confirmation) :: validation_response
  def validate_finalize(_turn = %TurnState{action: action}, :confirm) do
    case action do
      {:push, _} -> :valid
      {:withdraw} -> :valid
      _ -> {:not_valid, "That action needs a final direction to complete"}
    end
  end

  def validate_finalize(_turn = %TurnState{action: action, board: board, selected: selected, targeted: target}, direction)
    when Board.is_valid_direction?(direction)
  do
    case action do
      {:move_and_rotate, _} ->
        :valid

      {:rotate_in_place, _} ->
        confirm_rotation(board, selected, direction)

      {:push_from_off_board, _} ->
        confirm_push_direction_and_validate_push(board, target, direction)

      _ ->
        {:not_valid, "That action needs to be confirmed"}
    end
  end

  def validate_finalize(_, _), do: {:not_valid, "That isn't a valid message"}

  @spec confirm_push_direction_and_validate_push(Board.board, Board.xy_coord, Board.move_direction) :: validation_response
  defp confirm_push_direction_and_validate_push(board, target, direction) do
    if is_valid_push_direction?(target, direction) do
      confirm_push_from_edge(board, target, direction)
    else
      {:not_valid, "Can't push that direction"}
    end
  end

  @spec is_valid_push_direction?(Board.xy_coord, Board.move_direction) :: boolean
  defp is_valid_push_direction?(target = {x, y}, direction) when Board.is_on_corner?(target) do
    x_push_direction = Board.x_to_direction(x)
    y_push_direction = Board.y_to_direction(y)

    direction == x_push_direction or direction == y_push_direction
  end

  defp is_valid_push_direction?({x, _y}, direction) when Board.is_on_edge?(x) do
    x_push_direction = Board.x_to_direction(x)

    direction == x_push_direction
  end

  defp is_valid_push_direction?({_x, y}, direction) when Board.is_on_edge?(y) do
    y_push_direction = Board.y_to_direction(y)

    direction == y_push_direction
  end

  defp validate_push_from_edge(board, target = {x, y}) when Board.is_on_corner?(target) do
    x_push = Board.is_pushable_from_edge?(board, target, Board.x_to_direction(x))
    y_push = Board.is_pushable_from_edge?(board, target, Board.y_to_direction(y))
    if x_push or y_push do
      :valid
    else
      {:not_valid, "Can't push that piece"}
    end
  end

  defp validate_push_from_edge(board, target = {x, _y}) when Board.is_on_edge?(x) do
    push_direction = Board.x_to_direction(x)
    confirm_push_from_edge(board, target, push_direction)
  end

  defp validate_push_from_edge(board, target = {_x, y}) when Board.is_on_edge?(y) do
    push_direction = Board.y_to_direction(y)
    confirm_push_from_edge(board, target, push_direction)
  end

  defp confirm_push_from_edge(board, target, direction) do
    if Board.is_pushable_from_edge?(board, target, direction) do
      :valid
    else
      {:not_valid, "Can't push that direction"}
    end
  end

  defp confirm_rotation(board, selected, direction) do
    if Board.get_direction_of(board[selected]) != direction do
      :valid
    else
      {:not_valid, "Can't rotate to the same direction"}
    end
  end

end
