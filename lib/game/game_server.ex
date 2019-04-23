defmodule Game.Server do
  @moduledoc """
  GameServer for Siam.
  """
  use GenServer

  alias Game.Logic, as: Logic
  alias Game.Validation, as: Validation
  alias Game.TurnState, as: TurnState

  @type turn :: TurnState.t()
  @type game_state :: [turn]

  @type move_response :: Logic.move_response

  @type meta_response :: {:ok, game_state} | {:error, String.t()}

  @doc """
  Start Game Server Process
  """
  @spec start :: {:ok, pid}
  def start do
    GenServer.start(Game.Server, nil)
  end

  @doc """
  Send player move to be processed
  In the form of:
  {player, action, location/direction}
  {:elephant, :select, {1,2}} -- Select the piece at 1,2

  Returns {:ok, new_state} or {:error, message}
  """
  @spec move(pid, Logic.move_data) :: move_response
  def move(pid, move_data) do
    GenServer.call(pid, {:move, move_data})
  end

  @doc """
  Reset actions on current turn
  """
  @spec undo_move(pid) :: meta_response
  def undo_move(pid) do
    GenServer.call(pid, {:undo_move})
  end

  @doc """
  Go back to previous turn
  Current turn in progress is removed
  Last turn becomes current
  All actions in previous (now current) turn
  are reset

  Error is returned on first turn
  """
  @spec undo_turn(pid) :: meta_response
  def undo_turn(pid) do
    GenServer.call(pid, {:undo_turn})
  end

  @doc """
  Get current turn data
  """
  @spec get_turn(pid) :: turn
  def get_turn(pid) do
    GenServer.call(pid, {:get_turn})
  end

  @doc """
  Get entire game state (and history)
  """
  @spec get_state(pid) :: game_state
  def get_state(pid) do
    GenServer.call(pid, {:get_state})
  end

  @spec init(any()) :: {:ok, game_state}
  def init(_) do
    {:ok, [%TurnState{}]}
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
    updated_turn = %{current_turn | selected: nil, targeted: nil, action: nil}
    updated_state = [updated_turn | previous_turns]
    {:reply, {:ok, updated_state}, updated_state}
  end

  # Remove current turn and actions from prev turn
  def handle_call({:undo_turn}, _, [_first_turn | []] = state) do
    {:reply, {:error, "Can't undo on first turn!"}, state}
  end

  def handle_call({:undo_turn}, _, [_current_turn, prev_turn | tail]) do
    prev_turn = %{prev_turn | selected: nil, targeted: nil, action: nil}
    updated_state = [prev_turn | tail]
    {:reply, {:ok, updated_state}, updated_state}
  end

  def handle_call({:move, move_data}, _, [current_turn | _previous_turn] = state) do
    case Validation.validate_move(current_turn, move_data) do
      :valid ->
        update_state_and_respond(move_data, state)

      not_valid_response ->
        {:reply, not_valid_response, state}
    end
  end

  @spec update_state_and_respond(Logic.move_data, game_state) :: {:reply, Logic.move_response, game_state}
  defp update_state_and_respond(move_data, [current_turn | previous_turns] = state) do
    case Logic.process_move(current_turn, move_data) do
      {:continue, updated_turn} = response ->
        {:reply, response, [updated_turn | previous_turns]}

      {:next, updated_turn, next_turn} ->
        updated_state = [next_turn, updated_turn | previous_turns]
        {:reply, {:next, updated_turn, next_turn}, updated_state}

      {:win, updated_turn, final_turn} ->
        updated_state = [final_turn, updated_turn | previous_turns]
        {:reply, {:win, updated_turn, final_turn}, updated_state}

      _ ->
        {:reply, {:not_valid, "That's not valid"}, state}
    end
  end
end
