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


  @type coord :: 1..5
  @type index :: 0..4
  @type xy_coord :: {coord, coord}

  @type move_direction :: :up | :down | :left | :right
  @type direction :: move_direction | :neutral
  @type player :: :elephant | :rhino

  @type piece :: {player, direction} | {:mountain, :neutral} | {:empty}


  @type board :: %{xy_coord => piece}

  @doc """
  Create the default starting board
  __,__,__,__,__
  __,__,__,__,__
  __, ⛰, ⛰, ⛰,__
  __,__,__,__,__
  __,__,__,__,__
  """
  @spec new_board :: board
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
  # This function is long, but mostly for debugging so leaving as is
  # credo:disable-for-next-line
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
  @spec get_player_at(piece) :: player | :mountain | :empty
  def get_player_at({:empty}), do: :empty
  def get_player_at({piece, _}), do: piece

  @doc """
  Pulls out the direction info from a piece
  """
  @spec get_direction_of(piece) :: direction
  def get_direction_of({:empty}), do: :neutral
  def get_direction_of({_, direction}), do: direction

  @doc """
  Checks if coordinate is on the
  edge of the board

  {x,y} -> Bool
  """
  @spec on_edge?(xy_coord) :: boolean
  def on_edge?({1, _y}), do: true
  def on_edge?({5, _y}), do: true
  def on_edge?({_x, 1}), do: true
  def on_edge?({_x, 5}), do: true
  def on_edge?(_), do: false

  @doc """
  Checks if coordinate is on a corner

  {x, y} -> Bool
  """
  @spec on_corner?(xy_coord) :: boolean
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
  @spec is_orthogonal?(xy_coord, xy_coord) :: boolean
  def is_orthogonal?({x1, y1}, {x2, y2}) do
    delta_x = delta(x1, x2)
    delta_y = delta(y1, y2)
    delta_x + delta_y < 2
  end

  @spec delta(integer, integer) :: integer
  defp delta(a, b) when a >= b, do: a - b
  defp delta(a, b) when a < b, do: b - a

  @doc """
  Moves a piece from one location to another
  This assumes the end location is empty

  board, {x,y}, {x,y} -> board
  """
  @spec move_piece(board, xy_coord, xy_coord) :: board
  def move_piece(board, start, target) do
    %{board | target => board[start], start => {:empty}}
  end

  @doc """
  Checks if location is in front of piece

  board, {x, y}, {x, y} -> Bool
  """
  @spec is_in_front?(board, xy_coord, xy_coord) :: boolean
  def is_in_front?(board, selected, target) do
    direction = get_direction_of(board[selected])
    in_front_helper(direction, selected, target)
  end

  @spec in_front_helper(move_direction, xy_coord, xy_coord) :: boolean
  defp in_front_helper(:up, {x1, y1}, {x2, y2}), do: x1 == x2 and y2 - y1 == 1
  defp in_front_helper(:down, {x1, y1}, {x2, y2}), do: x1 == x2 and y1 - y2 == 1
  defp in_front_helper(:left, {x1, y1}, {x2, y2}), do: y1 == y2 and x1 - x2 == 1
  defp in_front_helper(:right, {x1, y1}, {x2, y2}), do: y1 == y2 and x2 - x1 == 1

  @doc """
  Takes a board + pusher info and returns the row or column involved
  """
  # TODO: add list flipping here??
  @spec get_row_or_col(board, xy_coord, move_direction) :: [piece]
  def get_row_or_col(board, {x, _y}, :up), do: get_column(board, x)
  def get_row_or_col(board, {x, _y}, :down), do: get_column(board, x)
  def get_row_or_col(board, {_x, y}, :left), do: get_row(board, y)
  def get_row_or_col(board, {_x, y}, :right), do: get_row(board, y)

  @doc """
  Takes a board and index and returns a row

  Row is left to right
  Index 0 -> x: 1
  [{:empty}, {:mountain, :neutral},...]
  """
  @spec get_row(board, coord) :: [piece]
  def get_row(board, index) do
    board
    |> Map.to_list()
    |> Stream.filter(fn {{_x, y}, _piece} -> y == index end)
    |> Enum.map(fn {_coord, piece} -> piece end)
  end

  @doc """
  Takes a board and index and returns a column

  Column is bottom to top
  Index 0 -> y: 1
  [{:empty}, {:mountain, :neutral},...]
  """
  @spec get_column(board, coord) :: [piece]
  def get_column(board, index) do
    board
    |> Map.to_list()
    |> Stream.filter(fn {{x, _y}, _piece} -> x == index end)
    |> Enum.map(fn {_coord, piece} -> piece end)
  end

  @doc """
  Assign push strength

  Pass in direction and a tuple of modifiers is returned
  Mountains are -0.67 for x and y
  2 mountains = -1.34
  3 mountains = -2.01
  (Rounding errors would be an issue if we needed more mountains,
  but only 3 can exist in this game)
  This is because mountains require one pusher to move
  per mountain, but it doesn't count as a pusher itself
  Using an round number instead would make things tie and not push
  """
  @spec get_push_strength(piece) :: {number, number}
  def get_push_strength({_, :up}), do: {0, 1}
  def get_push_strength({_, :down}), do: {0, -1}
  def get_push_strength({_, :left}), do: {-1, 0}
  def get_push_strength({_, :right}), do: {1, 0}
  def get_push_strength({_, :neutral}), do: {-0.67, -0.67}

  @doc """
  Takes a list that has the pusher str as head
  And the rest of the pieces str as tail

  [1, 0, -0.67, -1] -> False
  1 > 1.67 -> False
  """
  @spec calculate_push([number]) :: boolean
  def calculate_push([pusher_str | rest_str]) do
    sum_of_rest = Enum.sum(rest_str)
    abs(pusher_str) > abs(sum_of_rest)
  end

  @doc """
  Gets all pieces involved in current push
  Takes a list with pusher as head and the rest of the row as tail
  Returns a list with pusher at head and only involved pieces as tail

  [1, 0, -0.67, :empty, -1] -> [1, 0, -0.67]
  """
  @spec get_involved_pieces([number]) :: [number]
  def get_involved_pieces(pieces) do
    List.foldr(pieces, [], fn piece, acc ->
      case piece do
        {:empty} -> []
        _ -> [piece | acc]
      end
    end)
  end

  @doc """
  Changes general push str to specific direction only
  """
  @spec applicable_str([{number, number}]) :: [number]
  def applicable_str(pieces = [pusher | _rest]) do
    case pusher do
      {0, _} ->
        Enum.map(pieces, &elem(&1, 1))

      {_, 0} ->
        Enum.map(pieces, &elem(&1, 0))
    end
  end

  @doc """
  Reverses list if pusher is down or left (opposite of natural row/col direction)
  """
  @spec orientate_list([piece], move_direction) :: [piece]
  def orientate_list(column, :up), do: column
  def orientate_list(row, :right), do: row
  def orientate_list(row_or_col, _), do: Enum.reverse(row_or_col)

  @doc """
  Drops pieces behind the pusher from the list
  """
  @spec remove_pieces_behind([piece], index) :: [piece]
  def remove_pieces_behind(pieces, pusher) do
    Enum.drop(pieces, pusher)
  end

  @doc """
  Return list index of pusher based on direction
  """
  @spec get_pusher_index(xy_coord, move_direction) :: index
  def get_pusher_index({x, _y}, :right), do: x - 1
  def get_pusher_index({x, _y}, :left), do: 4 - (x - 1)
  def get_pusher_index({_x, y}, :up), do: y - 1
  def get_pusher_index({_x, y}, :down), do: 4 - (y - 1)

  @doc """
  Pass in pusher coords and board and it will calculate if
  the push is valid
  """
  @spec is_pushable?(board, xy_coord) :: boolean
  def is_pushable?(board, pusher_coords) do
    {_player, pusher_direction} = board[pusher_coords]
    pusher_index = get_pusher_index(pusher_coords, pusher_direction)

    board
    |> get_row_or_col(pusher_coords, pusher_direction)
    |> orientate_list(pusher_direction)
    |> remove_pieces_behind(pusher_index)
    |> get_involved_pieces()
    |> Enum.map(&get_push_strength(&1))
    |> applicable_str()
    |> calculate_push()
  end
end
