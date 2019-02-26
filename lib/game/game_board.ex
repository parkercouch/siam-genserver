defmodule Game.Board do
  @moduledoc """
  Game board creation and manipulation
  A board is just a normal map:
  %{{x,y} => {player, direction}}
  example:
  %{{1,1} => {:elephant, :up}} Is an elephant piece at 1,1 facing up

  Possible Pieces:
  :elephant, :rhino, :mountain, :empty

  Possible Directions:
  :up, :down, :left, :right, :neutral
  """

  @doc """
  Create the default starting board
  __,__,__,__,__
  __,__,__,__,__
  __, ⛰, ⛰, ⛰,__
  __,__,__,__,__
  __,__,__,__,__
  """
  def new_board() do
    # Generate empty board
    starting_board =
      for x <- Enum.to_list(1..5), y <- Enum.to_list(1..5), into: %{}, do: {{x, y}, {:empty}}

    # Add starting mountains in middle
    %{
      starting_board
      | {2, 3} => {:mountain, :neutral},
        {3, 3} => {:mountain, :neutral},
        {4, 3} => {:mountain, :neutral}
    }
  end

  @doc """
  Prints board to console. Useful for debugging
  """
  def pretty_print(b) do
    IO.puts("""
    --------------------------
    | #{f(b[{1, 5}])} | #{f(b[{2, 5}])} | #{f(b[{3, 5}])} | #{f(b[{4, 5}])} | #{f(b[{5, 5}])} |
    --------------------------
    | #{f(b[{1, 4}])} | #{f(b[{2, 4}])} | #{f(b[{3, 4}])} | #{f(b[{4, 4}])} | #{f(b[{5, 4}])} |
    --------------------------
    | #{f(b[{1, 3}])} | #{f(b[{2, 3}])} | #{f(b[{3, 3}])} | #{f(b[{4, 3}])} | #{f(b[{5, 3}])} |
    --------------------------
    | #{f(b[{1, 2}])} | #{f(b[{2, 2}])} | #{f(b[{3, 2}])} | #{f(b[{4, 2}])} | #{f(b[{5, 2}])} |
    --------------------------
    | #{f(b[{1, 1}])} | #{f(b[{2, 1}])} | #{f(b[{3, 1}])} | #{f(b[{4, 1}])} | #{f(b[{5, 1}])} |
    --------------------------
    """)
  end

  # Pick emoji for print... just for fun!
  defp f({:empty}), do: "  "

  defp f({player, direction}) do
    direction_symbol =
      case direction do
        :up ->
          "⬆️"

        :down ->
          "⬇️"

        :left ->
          "⬅️"

        :right ->
          "➡️"

        _ ->
          ""
      end

    player_symbol =
      case player do
        :elephant ->
          "🐘"

        :rhino ->
          "🦏"

        :mountain ->
          "⛰️ "

        _ ->
          ""
      end

    "#{player_symbol}#{direction_symbol}"
  end

  def get_player_at({:empty}), do: :empty
  def get_player_at({piece, _}), do: piece

  @doc """
  Checks if coordinate is on the
  edge of the board

  {x,y} -> Bool
  """
  def on_edge?({1, _y}), do: true 
  def on_edge?({5, _y}), do: true 
  def on_edge?({_x, 1}), do: true 
  def on_edge?({_x, 5}), do: true 
  def on_edge?(_), do: false

  @doc """
  Checks if coordinate is on a corner
  
  {x, y} -> Bool
  """
  def on_corner?({1, 1}), do: true
  def on_corner?({1, 5}), do: true
  def on_corner?({5, 1}), do: true
  def on_corner?({5, 5}), do: true
  def on_corner?(_), do: false
end
