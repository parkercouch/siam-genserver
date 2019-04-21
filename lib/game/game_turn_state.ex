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


end
