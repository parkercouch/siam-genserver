defmodule Game.TurnState do
  @moduledoc """
  Defines game state and helper functions
  """
  alias Game.Board, as: Board

  @type bullpen :: %{elephant: 0..5, rhino: 0..5}
  @type selectable :: Board.xy_coord | :bullpen
  @type action :: {:move_and_rotate, Board.move_direction} |
                  {:push_from_off_board, Board.move_direction} |
                  {:push, Board.move_direction} |
                  {:rotate_in_place, Board.move_direction} |
                  {:withdraw}

  @type t :: %__MODULE__{
    board: Board.board,
    bullpen: bullpen,
    current_player: Board.player,
    turn_number: integer,
    winner: Board.player | nil,
    selected: selectable | nil,
    targeted: selectable | nil,
    action: action | nil,
    completed: boolean
  }
  defstruct(
    board: Board.new_board(),
    bullpen: %{elephant: 5, rhino: 5},
    current_player: :elephant,
    turn_number: 0,
    winner: nil,
    selected: nil,
    targeted: nil,
    action: nil,
    completed: false
  )

  @spec next_turn(t, Board.board) :: t
  def next_turn(turn, updated_board) do
    %{turn |
      board: updated_board,
      turn_number: turn.turn_number + 1,
      selected: nil,
      targeted: nil,
      action: nil,
      completed: completed_if_winner(turn.winner),
      current_player: next_player(turn.current_player)
    }
  end

  @spec next_turn(t, Board.board, bullpen) :: t
  def next_turn(turn, updated_board, updated_bullpen) do
    %{turn |
      bullpen: updated_bullpen,
      board: updated_board,
      turn_number: turn.turn_number + 1,
      selected: nil,
      targeted: nil,
      action: nil,
      completed: completed_if_winner(turn.winner),
      current_player: next_player(turn.current_player)
    }
  end

  @spec next_player(Board.player) :: Board.player
  defp next_player(_current_player = :elephant), do: :rhino
  defp next_player(_current_player = :rhino), do: :elephant

  @spec completed_if_winner(nil | Board.player) :: boolean
  defp completed_if_winner(nil), do: false
  defp completed_if_winner(_), do: true
end
