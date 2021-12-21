defmodule AOC do
  def read_game do
    # read players
    players =
      System.argv()
      |> List.last()
      |> File.read!()
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(fn ps ->
        bits = ps |> String.split(" ")

        player =
          bits
          |> Enum.take(2)
          |> Enum.map(&String.downcase/1)
          |> Enum.join("_")
          |> String.to_atom()

        {player, %{position: (bits |> List.last() |> String.to_integer()) - 1, score: 0}}
      end)

    %{
      players: players |> Map.new(),
      order: players |> Enum.map(fn {p, _p} -> p end)
    }
  end

  @doc """
  Part 01

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_01 do
    read_game()
    |> IO.inspect(label: "board")
    |> play_to_win(0, long_cycle(10))
    |> IO.inspect(label: "winning board")
    |> score()
    |> IO.inspect(label: "board score")
  end

  defp score({chunked_rolls, board}) do
    losing_scores =
      board.players
      |> Map.values()
      |> Enum.filter(fn %{score: s} -> s < 1000 end)
      |> Enum.map(fn %{score: s} -> s end)
      |> Enum.sum()

    losing_scores * (3 * chunked_rolls)
  end

  defp long_cycle(count) do
    1..count
    |> Enum.map(fn _c -> 1..100 |> Enum.to_list() end)
    |> List.flatten()
    |> Enum.chunk_every(3, 3, :discard)
  end

  def play_to_win(board, turn, [move | moves]) do
    if win?(board) do
      {turn, board}
    else
      # who moves
      next = Enum.at(board.order, rem(turn, board.order |> length()))

      # setup the move and the score
      player = board.players |> Map.get(next)
      movement = move |> Enum.sum()
      new_position = (player.position + movement) |> rem(10)

      IO.puts("=== Turn #{turn}")
      IO.puts("  p: #{next}")
      IO.puts("  r: #{move |> Enum.join(", ")}")
      IO.inspect(board, label: "board")

      # inject the updated player and recurse
      play_to_win(
        update_in(
          board,
          [:players, next],
          fn old ->
            old |> Map.merge(%{score: player.score + new_position + 1, position: new_position})
          end
        ),
        turn + 1,
        moves
      )
    end
  end

  def win?(board) do
    board.players
    |> Map.values()
    |> Enum.any?(fn %{score: s} -> s >= 1000 end)
  end

  defmodule DiracPlay do
    @dirac_dice [
      {1, 1, 1},
      {1, 1, 2},
      {1, 1, 3},
      {1, 2, 1},
      {1, 2, 2},
      {1, 2, 3},
      {1, 3, 1},
      {1, 3, 2},
      {1, 3, 3},
      {2, 1, 1},
      {2, 1, 2},
      {2, 1, 3},
      {2, 2, 1},
      {2, 2, 2},
      {2, 2, 3},
      {2, 3, 1},
      {2, 3, 2},
      {2, 3, 3},
      {3, 1, 1},
      {3, 1, 2},
      {3, 1, 3},
      {3, 2, 1},
      {3, 2, 2},
      {3, 2, 3},
      {3, 3, 1},
      {3, 3, 2},
      {3, 3, 3}
    ]

    use Memoize

    defmemo hyper_play_to_win({score_a, pos_a}, {score_b, pos_b}) do
      cond do
        score_a >= 21 ->
          {1, 0}

        score_b >= 21 ->
          {0, 1}

        true ->
          # continue play
          {pb_wins, pa_wins} =
            @dirac_dice
            |> Enum.map(fn {d1, d2, d3} ->
              # move the current player
              new_pos_a = (pos_a + d1 + d2 + d3) |> rem(10)

              # update score
              new_score_a = score_a + new_pos_a + 1

              # recurse!
              hyper_play_to_win({score_b, pos_b}, {new_score_a, new_pos_a})
            end)
            |> Enum.reduce({0, 0}, fn {pb_win, pa_win}, {pb_acc, pa_acc} ->
              {pb_win + pb_acc, pa_win + pa_acc}
            end)

          {pa_wins, pb_wins}
      end
    end
  end

  @doc """
  Part 02

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_02 do
    %{players: players} = read_game()
    |> IO.inspect(label: "board")

    [p_a, p_b] = players
    |> Map.values()
    |> Enum.map(fn %{position: p} -> {0, p} end)

    AOC.DiracPlay.hyper_play_to_win(p_a, p_b)
    |> IO.inspect(label: "(a, b)")
  end
end
