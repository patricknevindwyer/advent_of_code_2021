defmodule AOC do
    
    def read_bingo do
       [calls | boards] = System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n\n")

       %{
         calls: calls |> parse_calls(),
         boards: boards |> parse_boards()
       }
    end

    defp parse_calls(call_string) do
      call_string
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
    end

    defp parse_boards(boards_list) do
      boards_list
      |> Enum.map(&parse_board/1)
    end

    defp parse_board(board_string) do
      board_string
      |> String.split(~r/\s+/, trim: true)
      |> Enum.map(&String.to_integer/1)
      |> Enum.map(fn i -> {:uncalled, i} end)
    end
    
    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
        
      # read boards and numbers
      %{calls: calls, boards: boards} = read_bingo()

      # start marking boards until one wins
      %{winner: board, number: number} = call_number(calls, boards)

      # calculate winning board
      score_winning_board(board, number)
      |> IO.inspect(label: "winning score")

    end

    defp score_winning_board(board, number) do
      unmarked = board
      |> Enum.filter(fn {mark, _v} -> mark == :uncalled end)
      |> Enum.map(fn {_mark, v} -> v end)
      |> Enum.sum()

      unmarked * number
    end

    defp call_number([number | rest], boards) do

      # update the boards
      boards = boards |> Enum.map(fn board -> mark_board(number, board) end)

      # check for a winner
      case select_winner(boards) do
        nil -> call_number(rest, boards)
        board -> %{winner: board, number: number}
      end
    end

    # we have only a single board left, let's run it until it wins
    defp call_until_last([number | rest], [_board]=boards) do

      # update the boards
      boards = boards |> Enum.map(fn board -> mark_board(number, board) end)

      # check for a winner
      case select_winner(boards) do
        nil -> call_until_last(rest, boards)
        board -> %{winner: board, number: number}
      end

    end

    # we have multiple boards left
    defp call_until_last([number | rest], [_board | _rest]=boards) do

      # update boards and filter out any winners
      boards = boards
               |> Enum.map(fn board -> mark_board(number, board) end)
               |> Enum.filter(fn board -> !winner?(board) end)

      # keep calling
      call_until_last(rest, boards)

    end

    defp mark_board(number, board) do
      board
      |> Enum.map(
           fn {mark, n} ->
             if number == n do
               {:called, n}
             else
               {mark, n}
             end
           end
         )
    end

    defp select_winner(boards) do

      case Enum.find(boards, nil, &winner?/1) do
        nil -> nil
        board -> board
      end
    end

    defp winner?(board) do

      # check rows and columns
      win_by_rows?(board) || win_by_columns?(board)

    end

    defp win_by_rows?(board) do
      board
      |> Enum.chunk_every(5)
      |> Enum.map(
           fn board_row ->

             # convert the row to true/false add see if the whole row
             # is marked
             board_row
             |> Enum.map(fn {mark, _v} -> mark == :called end)
             |> Enum.all?()

           end
         )
      |> Enum.any?()
    end

    defp win_by_columns?(board) do

      0..4
      |> Enum.map(
           fn col_idx ->
             board
             |> select_column(col_idx)
             |> Enum.map(fn {mark, _v} -> mark == :called end)
             |> Enum.all?()
           end
         )
      |> Enum.any?()
    end

    defp select_column(board, col) do
      0..4
      |> Enum.map(
           fn row_idx ->
             Enum.at(board, row_idx * 5 + col)
           end
         )
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      # read boards and numbers
      %{calls: calls, boards: boards} = read_bingo()

      # start marking boards until one wins
      %{winner: board, number: number} = call_until_last(calls, boards)

      # calculate winning board
      score_winning_board(board, number)
      |> IO.inspect(label: "winning score")


    end

end
