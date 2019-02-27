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

  @doc """
  Pulls out player info from piece tuple
  """
  def get_player_at({:empty}), do: :empty
  def get_player_at({piece, _}), do: piece

  @doc """
  Pulls out the direction info from a piece
  """
  def get_direction_of({:empty}), do: :neutral
  def get_direction_of({_, direction}), do: direction

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

  @doc """
  Checks if two coordinates are within 1 space
  and not diagonal

  {x, y}, {x, y} -> Bool
  """
  def is_orthogonal?({x1, y1}, {x2, y2}) do
    delta_x = delta(x1, x2)
    delta_y = delta(y1, y2)
    delta_x + delta_y < 2
  end

  defp delta(a, b) when a >= b, do: a - b
  defp delta(a, b) when a < b, do: b - a

  @doc """
  Moves a piece from one location to another
  This assumes the end location is empty

  board, {x,y}, {x,y} -> board
  """
  def move_piece(board, start, target) do
    %{board | target => board[start], start => {:empty}}
  end

  @doc """
  Checks if location is in from of piece

  board, {x, y}, {x, y} -> Bool 
  """
  def is_in_front?(board, selected, target) do
    direction = get_direction_of(board[selected])
    in_front_helper(direction, selected, target)
  end

  defp in_front_helper(:up, {x1, y1}, {x2, y2}), do: x1 == x2 and y2 - y1 == 1
  defp in_front_helper(:down, {x1, y1}, {x2, y2}), do: x1 == x2 and y1 - y2 == 1
  defp in_front_helper(:left, {x1, y1}, {x2, y2}), do: y1 == y2 and x1 - x2 == 1
  defp in_front_helper(:right, {x1, y1}, {x2, y2}), do: y1 == y2 and x2 - x1 == 1

  @doc """
  Takes a board and index and returns a row

  Row is left to right
  Index 0 -> x: 1
  [{:empty}, {:mountain, :neutral},...]
  """
  def get_row(board, index) do
    board
    |> Map.to_list()
    |> Stream.filter(fn {{_x, y}, _piece} -> y == index end)
    |> Enum.map(fn {_, piece} -> piece end)
  end

  @doc """
  Takes a board and index and returns a column

  Column is bottom to top
  Index 0 -> y: 1
  [{:empty}, {:mountain, :neutral},...]
  """
  def get_column(board, index) do
    board
    |> Map.to_list()
    |> Stream.filter(fn {{x, _y}, _piece} -> x == index end)
    |> Enum.map(fn {_coord, piece} -> piece end)
  end
end

Enum.filter([1, 2, 3], fn x -> rem(x, 2) == 0 end)
