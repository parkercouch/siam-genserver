defmodule Game.TurnStateTest do
  @moduledoc false

  use ExUnit.Case
  doctest Game.TurnState

  alias Game.TurnState, as: TurnState

  test "Can construct a new TurnState" do
    turn = %TurnState{}

    assert turn.current_player == :elephant
  end
end
