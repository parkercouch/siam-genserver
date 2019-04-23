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

  defguard is_valid_direction?(direction)
           when direction == :up or
                  direction == :down or
                  direction == :left or
                  direction == :right

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
  @spec on_edge?(xy_coord | coord) :: boolean
  def on_edge?({1, _y}), do: true
  def on_edge?({5, _y}), do: true
  def on_edge?({_x, 1}), do: true
  def on_edge?({_x, 5}), do: true
  def on_edge?(1), do: true
  def on_edge?(5), do: true
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

  @spec x_to_direction(coord) :: direction
  def x_to_direction(1), do: :right
  def x_to_direction(5), do: :left
  def x_to_direction(_), do: :neutral

  @spec y_to_direction(coord) :: direction
  def y_to_direction(1), do: :up
  def y_to_direction(5), do: :down
  def y_to_direction(_), do: :neutral

  @spec xy_to_push_from_edge_direction(xy_coord) :: direction
  def xy_to_push_from_edge_direction({x, y}) do
    case {on_edge?(x), on_edge?(y)} do
      {true, _} -> x_to_direction(x)
      {_, true} -> y_to_direction(y)
      _ -> :neutral
    end
  end

  defguard is_on_corner?(xy)
           when xy == {1, 1} or
                  xy == {1, 5} or
                  xy == {5, 1} or
                  xy == {5, 5}

  defguard is_on_edge?(x_or_y) when x_or_y == 1 or x_or_y == 5

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
  Takes a list of pushed row and updates all the coords
  to their new positions
  """
  def update_coords_of_pushed(row_or_col, direction) do
    Enum.map(row_or_col, &update_coords(&1, direction))
  end

  def update_coords({{x, y}, piece}, :up) do
    new_coords = if y == 5, do: :off, else: {x, y + 1}
    {new_coords, piece}
  end

  def update_coords({{x, y}, piece}, :down) do
    new_coords = if y == 1, do: :off, else: {x, y - 1}
    {new_coords, piece}
  end

  def update_coords({{x, y}, piece}, :left) do
    new_coords = if x == 1, do: :off, else: {x - 1, y}
    {new_coords, piece}
  end

  def update_coords({{x, y}, piece}, :right) do
    new_coords = if x == 5, do: :off, else: {x + 1, y}
    {new_coords, piece}
  end

  @doc """
  Takes list of pieces with pusher at the end
  Updates coords of all pieces
  """
  def move_pieces_in_row(row, :up) do
    Enum.map(row, fn {{x, y}, piece} -> {{x, y + 1}, piece} end)
  end

  def move_pieces_in_row(row, :down) do
    Enum.map(row, fn {{x, y}, piece} -> {{x, y - 1}, piece} end)
  end

  def move_pieces_in_row(row, :left) do
    Enum.map(row, fn {{x, y}, piece} -> {{x - 1, y}, piece} end)
  end

  def move_pieces_in_row(row, :right) do
    Enum.map(row, fn {{x, y}, piece} -> {{x + 1, y}, piece} end)
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
    |> Enum.filter(fn {{_x, y}, _piece} -> y == index end)

    # |> Stream.filter(fn {{_x, y}, _piece} -> y == index end)
    # |> Enum.map(fn {_coord, piece} -> piece end)
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
    |> Enum.filter(fn {{x, _y}, _piece} -> x == index end)

    # |> Stream.filter(fn {{x, _y}, _piece} -> x == index end)
    # |> Enum.map(fn {_coord, piece} -> piece end)
  end

  @doc """
  Extracts piece info out of row/col to do push calcs with
  """
  @spec extract_pieces([{xy_coord, piece}]) :: [piece]
  def extract_pieces(row_or_col) do
    Enum.map(row_or_col, fn {_coord, piece} -> piece end)
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
  Using a round number instead would make things tie and not push
  """
  @spec get_push_strength(piece, move_direction) :: {number, number}
  def get_push_strength({_, :up}, _), do: {0, 1}
  def get_push_strength({_, :down}, _), do: {0, -1}
  def get_push_strength({_, :left}, _), do: {-1, 0}
  def get_push_strength({_, :right}, _), do: {1, 0}
  def get_push_strength({_, :neutral}, direction) when direction == :right or direction == :up do
    {-0.67, -0.67}
  end
  def get_push_strength({_, :neutral}, direction) when direction == :left or direction == :down do
    {0.67, 0.67}
  end

  @doc """
  Takes a list that has the pusher str as head
  And the rest of the pieces str as tail

  Mountains should always be opposite str of pusher

  Sums all strengths and checks if still above 0
  (or less than 0 for pusher of -1 str)
  """
  @spec calculate_push([number]) :: boolean
  def calculate_push(involved_pieces = [-1 | _rest]) do
    Enum.sum(involved_pieces) < 0
  end

  def calculate_push(involved_pieces = [1 | _rest]) do
    Enum.sum(involved_pieces) > 0
  end

  @doc """
  Gets all pieces involved in current push
  Takes a list with pusher as head and the rest of the row as tail
  Returns a list with pusher at head and only involved pieces as tail

  [{:rhino, :right}, {:elephant, :up}, {:mountain, :neutral}, {:empty}, {:rhino, :right}]
  -> [{:rhino, :right}, {:elephant, :up}, {:mountain, :neutral}]
  """
  @spec get_involved_pieces([{xy_coord, piece}] | [piece]) :: [piece]
  def get_involved_pieces(pieces = [{{_x, _y}, _} | _]) do
    List.foldr(pieces, [], fn {coord, piece}, acc ->
      case piece do
        {:empty} -> []
        _ -> [{coord, piece} | acc]
      end
    end)
  end

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
  @spec get_applicable_strength([piece], move_direction) :: [number]
  def get_applicable_strength(pieces = [pusher | _rest], direction) do
    index =
      case get_push_strength(pusher, direction) do
        {0, _} -> 1
        {_, 0} -> 0
      end

    pieces
    |> Stream.map(&(get_push_strength(&1, direction)))
    |> Enum.map(&elem(&1, index))
  end

  @doc """
  Reverses list if pusher is down or left (opposite of natural row/col direction)
  """
  @spec orientate_pusher_to_head([piece], move_direction) :: [piece]
  def orientate_pusher_to_head(column, :up), do: column
  def orientate_pusher_to_head(row, :right), do: row
  def orientate_pusher_to_head(row_or_col, _), do: Enum.reverse(row_or_col)

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
  Add pusher to list to calculate push
  Used when moving from off board

  :elephant is used to satisfy types
  will be removed in pipeline since only direction matters
  in the push calculation
  """
  @spec add_pusher_placeholder_to_list([piece], move_direction) :: [piece]
  def add_pusher_placeholder_to_list(list, direction) do
    [{:elephant, direction} | list]
  end


  @spec add_pusher_to_list([{xy_coord, piece}], xy_coord, player, move_direction) :: [{xy_coord, piece}]
  def add_pusher_to_list(list, target, player, direction) do
    [{target, {player, direction}} | list]
  end

  @doc """
  Adds an empty piece behind the pusher
  This will make merging the pushed row with the board cleaner
  """
  @spec add_empty_behind_pusher([{xy_coord, piece}], xy_coord) :: [{xy_coord, piece}]
  def add_empty_behind_pusher(pieces, pusher_starting_coords) do
    [{pusher_starting_coords, {:empty}} | pieces]
  end

  @doc """
  Pass in pusher coords and board and it will calculate if
  the push is valid
  """
  @spec is_pushable?(board, xy_coord) :: boolean
  def is_pushable?(board, pusher_coords) do
    {_player, push_direction} = board[pusher_coords]
    pusher_index = get_pusher_index(pusher_coords, push_direction)

    board
    |> get_row_or_col(pusher_coords, push_direction)
    |> extract_pieces()
    |> orientate_pusher_to_head(push_direction)
    |> remove_pieces_behind(pusher_index)
    |> get_involved_pieces()
    |> get_applicable_strength(push_direction)
    |> calculate_push()
  end

  @doc """
  Calculates if push is valid from edge of board
  """
  @spec is_pushable_from_edge?(board, xy_coord, move_direction) :: boolean
  def is_pushable_from_edge?(board, target, push_direction) do
    board
    |> get_row_or_col(target, push_direction)
    |> extract_pieces()
    |> orientate_pusher_to_head(push_direction)
    |> get_involved_pieces()
    |> add_pusher_placeholder_to_list(push_direction)
    |> get_applicable_strength(push_direction)
    |> calculate_push()
  end

  # {:off, :elephant, [{{x, y}, {...}}, ...]}

  @spec push_row(board, xy_coord, move_direction) :: [{xy_coord | :off, piece}]
  def push_row(board, pusher_coords, pusher_direction) do
    pusher_index = get_pusher_index(pusher_coords, pusher_direction)

    board
    |> get_row_or_col(pusher_coords, pusher_direction)
    |> orientate_pusher_to_head(pusher_direction)
    |> remove_pieces_behind(pusher_index)
    |> get_involved_pieces()
    |> update_coords_of_pushed(pusher_direction)
    |> add_empty_behind_pusher(pusher_coords)
    |> Enum.reverse()
  end

  @spec push_row_from_edge(board, xy_coord, player, move_direction) :: [{xy_coord | :off, piece}]
  def push_row_from_edge(board, target, player, push_direction) do
    board
    |> get_row_or_col(target, push_direction)
    |> orientate_pusher_to_head(push_direction)
    |> get_involved_pieces()
    |> update_coords_of_pushed(push_direction)
    |> add_pusher_to_list(target, player, push_direction)
    |> Enum.reverse()
  end

  @spec get_closest_pusher([{xy_coord, piece}], move_direction) :: player
  def get_closest_pusher(pushed_row, push_direction) do
    {_xy, {player, _direction}} =
      Enum.find(
        pushed_row,
        fn {_xy, {_player, piece_direction}} ->
          piece_direction == push_direction
        end
      )

    player
  end
end
