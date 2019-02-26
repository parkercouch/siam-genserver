defmodule Game.Server do
  @moduledoc """
  GameServer for Siam.
  """
  use GenServer

  alias Game.Logic, as: Logic
  alias Game.Board, as: Board

  @doc """
  Start Game Server Process
  """
  def start do
    GenServer.start(Game.Server, nil)
  end

  @doc """
  Send player move to be processed
  """
  def move(pid, move_data) do
    GenServer.call(pid, {:move, move_data})
  end

  @doc """
  Reset actions on current turn
  """
  def undo_move(pid) do
    GenServer.call(pid, {:undo_move})
  end

  @doc """
  Go back to previous turn
  Current turn in progress is removed
  Last turn becomes current
  All actions in previous (now current) turn
  are reset
  """
  def undo_turn(pid) do
    GenServer.call(pid, {:undo_turn})
  end

  @doc """
  Get current turn data
  """
  def get_turn(pid) do
    GenServer.call(pid, {:get_turn})
  end

  @doc """
  Get entire game state (and history)
  """
  def get_state(pid) do
    GenServer.call(pid, {:get_state})
  end

  def init(_) do
    starting_state = %{
      board: Board.new_board(),
      rhino_pool: 5,
      elephant_pool: 5,
      current_player: :elephant,
      turn_number: 0,
      winner: nil,
      actions: [],
    }
    {:ok, [starting_state]}
  end

  def handle_call({:move, move_data}, _, [current_turn | previous_turns] = state) do
    case Logic.process_move(move_data, current_turn) do
      {:continue, updated_turn} = response ->
        {:reply, response, [updated_turn | previous_turns]}

      {:not_valid, _message} = response ->
        {:reply, response, state}

      {:next, next_turn} ->
        current_turn = %{current_turn | actions: [move_data | current_turn.actions]}
        updated_state = [next_turn | [current_turn | previous_turns]]
        {:reply, {:next, current_turn, next_turn}, updated_state}

      {:win, final_turn} ->
        current_turn = %{current_turn | actions: [move_data | current_turn.actions]}
        updated_state = [final_turn | [current_turn | previous_turns]]
        {:reply, {:win, current_turn, final_turn}, updated_state}
    end
  end

  # Return current turn of state
  def handle_call({:get_turn}, _, [current_turn | _previous_turns] = state) do
    {:reply, current_turn, state}
  end

  # Return state
  def handle_call({:get_state}, _, state) do
    {:reply, state, state}
  end

  # Remove actions from current turn
  def handle_call({:undo_move}, _, [current_turn | previous_turns]) do
    updated_turn = %{current_turn | actions: []}
    {:reply, {:ok, updated_turn}, [updated_turn | previous_turns]}
  end

  # Remove current turn and actions from prev turn
  def handle_call({:undo_turn}, _, [_current_turn | [ prev_turn | prev_turns]]) do
    updated_state = [%{prev_turn | actions: []} | prev_turns]
    {:reply, {:ok, updated_state}, updated_state}
  end
end
