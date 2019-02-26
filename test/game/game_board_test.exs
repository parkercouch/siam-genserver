defmodule Game.BoardTest do
  use ExUnit.Case
  doctest Game.Board

  alias Game.Board, as: Board

  test "On edge of board" do
    assert Board.on_edge?({1, 1}) == true
    assert Board.on_edge?({1, 2}) == true
    assert Board.on_edge?({1, 3}) == true
    assert Board.on_edge?({1, 4}) == true
    assert Board.on_edge?({1, 5}) == true
    assert Board.on_edge?({2, 1}) == true
    assert Board.on_edge?({2, 2}) == false
    assert Board.on_edge?({2, 3}) == false
    assert Board.on_edge?({2, 4}) == false
    assert Board.on_edge?({2, 5}) == true
    assert Board.on_edge?({3, 1}) == true
    assert Board.on_edge?({3, 2}) == false
    assert Board.on_edge?({3, 3}) == false
    assert Board.on_edge?({3, 4}) == false
    assert Board.on_edge?({4, 5}) == true
    assert Board.on_edge?({4, 1}) == true
    assert Board.on_edge?({4, 2}) == false
    assert Board.on_edge?({4, 3}) == false
    assert Board.on_edge?({4, 4}) == false
    assert Board.on_edge?({4, 5}) == true
    assert Board.on_edge?({5, 1}) == true
    assert Board.on_edge?({5, 2}) == true
    assert Board.on_edge?({5, 3}) == true
    assert Board.on_edge?({5, 4}) == true
    assert Board.on_edge?({5, 5}) == true
  end

  test "Get player from piece tuple" do
    board = Board.new_board()
    board = %{board | {1,1} => {:elephant, :up}, {1, 2} => {:rhino, :down}}
    elephant = Board.get_player_at(board[{1,1}])
    rhino = Board.get_player_at(board[{1,2}])
    mountain = Board.get_player_at(board[{3,3}])
    empty = Board.get_player_at(board[{5,5}])

    assert elephant == :elephant
    assert rhino == :rhino
    assert mountain == :mountain
    assert empty == :empty
  end
end
