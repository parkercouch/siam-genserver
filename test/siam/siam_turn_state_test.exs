defmodule Siam.TurnStateTest do
  @moduledoc false

  use ExUnit.Case
  doctest Siam.TurnState

  alias Siam.TurnState, as: TurnState

  test "Can construct a new TurnState" do
    turn = %TurnState{}

    assert turn.current_player == :elephant
  end
end
