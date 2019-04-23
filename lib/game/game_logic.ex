defmodule Game.Logic do
  @moduledoc """
  Game logic for Siam
  Use process_move to interface with this

  Game flow looks like this:
  Turns: Elephants and Rhinos get one complete action per turn
  Action:
    Select - select piece or square
    Target - Select target of push/move/rotate
    Finalize - Select rotation or confirm push/withdraw
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
  Send a validated move and current turn and get back:

  {:not_valid, message} - not a valid move (catch all in case validation failed)
  {:continue, updated_turn} - processed action, still on current turn
  {:next, updated_turn, next_turn} - processed action, this action finishes turn
  {:win, updated_turn, final_turn} - processed action, this action finishes turn and game
  """
  @spec process_move(turn, move_data) :: move_response
  def process_move(turn, {_player, :select, location}) do
    handle_select(turn, location)
  end

  def process_move(turn, {_player, :target, target}) do
    handle_target(turn, turn.selected, target)
  end

  def process_move(turn, {_player, :finalize, direction_or_confirm}) do
    handle_finalize(turn, direction_or_confirm)
  end

  def process_move(_, _), do: {:not_valid, "That isn't a valid action"}

  #
  # Selecting
  #
  @spec handle_select(turn, TurnState.selectable) :: move_response
  defp handle_select(turn, location) do
    {:continue, %{turn | selected: location}}
  end

  #
  # Targeting
  #
  @spec handle_target(turn, TurnState.selectable, TurnState.selectable) :: move_response
  defp handle_target(turn, selected, target) when selected == target do
    {:continue, %{turn | targeted: target, action: {:rotate_in_place, :down}}}
  end

  defp handle_target(turn, _selected, target) when target == :bullpen do
    {:continue, %{turn | targeted: target, action: {:withdraw}}}
  end

  defp handle_target(turn = %TurnState{board: board}, selected, target) do
    updated_turn = case board[target] do
      {:empty} ->
        handle_move_to_target(turn, target)

      _ ->
        handle_push_target(turn, selected, target)
    end

    {:continue, updated_turn}
  end

  @spec handle_move_to_target(turn, TurnState.selectable) :: turn
  defp handle_move_to_target(turn, target) do
    %{turn | targeted: target, action: {:move_and_rotate, :down}}
  end

  @spec handle_push_target(turn, TurnState.selectable, TurnState.selectable) :: turn
  defp handle_push_target(turn, :bullpen, target) do
    %{turn | targeted: target, action: {:push_from_off_board, Board.xy_to_push_from_edge_direction(target)}}
  end

  defp handle_push_target(turn = %TurnState{board: board}, selected, target) do
    %{turn | targeted: target, action: {:push, Board.get_direction_of(board[selected])}}
  end


  #
  # Finalizing
  #
  @spec handle_finalize(turn, Board.move_direction) :: move_response

  # Move to board
  defp handle_finalize(turn = %TurnState{action: {:move_and_rotate, _}, selected: :bullpen, bullpen: bullpen, current_player: player}, direction) do
    updated_turn = %{turn | action: {:move_and_rotate, direction}, completed: true}
    updated_bullpen = %{bullpen | player => bullpen[player] - 1}
    updated_board = move_piece_to_board(turn, direction)

    next_turn = TurnState.next_turn(updated_turn, updated_board, updated_bullpen)

    {:next, updated_turn, next_turn}
  end

  # Move or Rotate
  defp handle_finalize(turn = %TurnState{action: {action, _}}, direction)
    when action == :move_and_rotate or action == :rotate_in_place
  do
    updated_turn = %{turn | action: {action, direction}, completed: true}
    updated_board = move_or_rotate_piece(turn, direction)

    next_turn = TurnState.next_turn(updated_turn, updated_board)

    {:next, updated_turn, next_turn}
  end

  # Withdraw
  defp handle_finalize(turn = %TurnState{action: {:withdraw}, board: board, bullpen: bullpen, current_player: player, selected: selected}, _confirm) do
    updated_turn = %{turn | completed: true}
    updated_board = %{board | selected => {:empty}}
    updated_bullpen = %{bullpen | player => bullpen[player] + 1}
    next_turn = TurnState.next_turn(updated_turn, updated_board, updated_bullpen)

    {:next, updated_turn, next_turn}
  end

  # Push from on board
  defp handle_finalize(turn = %TurnState{action: {:push, direction}, board: board, selected: pusher}, _confirm) do
    pushed_row = [last_piece | rest_of_pieces] = Board.push_row(board, pusher, direction)

    case last_piece do
      {:off, {:mountain, _}} ->
        check_winner_and_respond(turn, rest_of_pieces)
      {:off, {pushed_off_piece, _}} ->
        add_to_bullpen_and_respond(turn, pushed_off_piece, rest_of_pieces)
      {_, _} ->
        update_board_and_respond(turn, pushed_row)
    end
  end

  # TODO: IMPLEMENT THIS!!!
  # Push from off board
  defp handle_finalize(turn = %TurnState{action: {:push_from_off_board, _}, board: board, targeted: target, current_player: player}, direction) do
    pushed_row = [last_piece | rest_of_pieces] = Board.push_row_from_edge(board, target, player, direction)

    case last_piece do
      {:off, {:mountain, _}} ->
        check_winner_and_respond(turn, rest_of_pieces)
      {:off, {pushed_off_piece, _}} ->
        add_to_bullpen_and_respond(turn, pushed_off_piece, rest_of_pieces)
      {_, _} ->
        update_board_and_respond(turn, pushed_row)
    end
  end


  @spec check_winner_and_respond(turn, [{Board.xy_coord, Board.piece}]) :: move_response
  defp check_winner_and_respond(turn = %TurnState{action: {_, direction}, board: board, selected: :bullpen, current_player: player, bullpen: bullpen}, pushed_row) do
    winner = Board.get_closest_pusher(pushed_row, direction)

    updated_turn = %{turn | completed: true, winner: winner}
    updated_board = Map.merge(board, Map.new(pushed_row))
    updated_bullpen = %{bullpen | player => bullpen[player] - 1}
    final_turn = TurnState.next_turn(updated_turn, updated_board, updated_bullpen)

    {:win, updated_turn, final_turn}
  end
  defp check_winner_and_respond(turn = %TurnState{action: {_, direction}, board: board}, pushed_row) do
    winner = Board.get_closest_pusher(pushed_row, direction)

    updated_turn = %{turn | completed: true, winner: winner}
    updated_board = Map.merge(board, Map.new(pushed_row))
    final_turn = TurnState.next_turn(updated_turn, updated_board)

    {:win, updated_turn, final_turn}
  end

  @spec add_to_bullpen_and_respond(turn, Board.player, [{Board.xy_coord, Board.piece}]) :: move_response
  defp add_to_bullpen_and_respond(turn = %TurnState{board: board, bullpen: bullpen, selected: :bullpen, current_player: player}, owner_of_pushed_off_piece, pushed_row) do
    updated_turn = %{turn | completed: true}
    updated_bullpen = %{bullpen | owner_of_pushed_off_piece => bullpen[owner_of_pushed_off_piece] + 1}
    updated_bullpen = %{updated_bullpen | player => updated_bullpen[player] - 1}
    updated_board = Map.merge(board, Map.new(pushed_row))
    next_turn = TurnState.next_turn(updated_turn, updated_board, updated_bullpen)

    {:next, updated_turn, next_turn}
  end

  defp add_to_bullpen_and_respond(turn = %TurnState{board: board, bullpen: bullpen}, owner_of_pushed_off_piece, pushed_row) do
    updated_turn = %{turn | completed: true}
    updated_bullpen = %{bullpen | owner_of_pushed_off_piece => bullpen[owner_of_pushed_off_piece] + 1}
    updated_board = Map.merge(board, Map.new(pushed_row))
    next_turn = TurnState.next_turn(updated_turn, updated_board, updated_bullpen)

    {:next, updated_turn, next_turn}
  end

  @spec update_board_and_respond(turn, [{Board.xy_coord, Board.piece}]) :: move_response
  defp update_board_and_respond(turn = %TurnState{board: board, selected: :bullpen, current_player: player, bullpen: bullpen}, pushed_row) do
    updated_turn = %{turn | completed: true}
    updated_board = Map.merge(board, Map.new(pushed_row))
    updated_bullpen = %{bullpen | player => bullpen[player] - 1}

    next_turn = TurnState.next_turn(updated_turn, updated_board, updated_bullpen)

    {:next, updated_turn, next_turn}
  end

  defp update_board_and_respond(turn = %TurnState{board: board}, pushed_row) do
    updated_turn = %{turn | completed: true}
    updated_board = Map.merge(board, Map.new(pushed_row))
    next_turn = TurnState.next_turn(updated_turn, updated_board)

    {:next, updated_turn, next_turn}
  end


  @spec move_or_rotate_piece(turn, Board.direction) :: Board.board
  defp move_or_rotate_piece(%TurnState{board: board, current_player: player, selected: from, targeted: to}, facing_direction) do
    updated_piece = {player, facing_direction}
    # Processed in order so this handles both moving to a new square or rotating in place
    %{board | from => {:empty}, to => updated_piece}
  end

  @spec move_piece_to_board(turn, Board.direction) :: Board.board
  defp move_piece_to_board(%TurnState{board: board, current_player: player, targeted: to}, facing_direction) do
    updated_piece = {player, facing_direction}
    %{board | to => updated_piece}
  end
end
