defmodule AOC do

  @rooms ["A", "B", "C", "D"]

  def read_amphipods do
    # read instructions
    System.argv()
    |> List.last()
    |> File.read!()
    |> String.trim()
    |> String.split("\n")
    |> Enum.drop(2)
    |> Enum.take(2)
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, row_idx} ->
      line
      |> String.split("", trim: true)
      |> Enum.filter(fn c -> !Enum.member?([" ", "#", "."], c) end)
      |> Enum.with_index()
      |> Enum.map(fn {amphi, room_idx} ->
        room = Enum.at(@rooms, room_idx)
        %{type: amphi, position: 1 - row_idx, room: room, state: amphi_state(amphi, room), name: "#{amphi}.#{row_idx}.#{room_idx}"}
      end)
    end)
    |> update_amphipod_states()
  end

  defp amphi_state(amphi, room) do
    if amphi == room do
      :home
    else
      :not_home
    end
  end

  defp update_amphipod_states(amphis) do

    # mark home vs not home
    room_map = amphis
    |> Enum.filter(fn %{state: s} -> s != :hallway end)
    |> Enum.map(fn %{room: r, position: p, type: t} -> {{r, p}, t} end)
    |> Map.new()

    # update amphipods
    amphis |> Enum.map(fn %{state: s, position: p, room: r, type: t}=a ->

      if (s != :hallway) && (t == r) do
        case p do
          0 ->
            # home in the bottom of the room
            a |> Map.put(:state, :home)
          1 ->
            # who is in position 1?
            if Map.get(room_map, {r, 0}, ".") == t do
              a |> Map.put(:state, :home)
            else
              a |> Map.put(:state, :not_home)
            end
        end
      else
        # no change
        a
      end
    end)

  end

  defp print_amphipods(states) do

    # header
    IO.puts("┏━━━━━━━━━━━┓")

    # hallway amphipods
    IO.write("┃")
    hallway_map = states
    |> Enum.filter(fn %{state: s} -> s == :hallway end)
    |> Enum.map(fn %{type: t, position: p} -> {p, t} end)
    |> Map.new()

    0..10
    |> Enum.map(fn idx ->
      hallway_map |> Map.get(idx, ".") |> IO.write()
    end)

    IO.puts("┃")

    # rooms
    IO.write("┗━┓")

    room_map = states
    |> Enum.filter(fn %{state: s, position: p} -> Enum.member?([:home, :not_home], s) && (p == 1) end)
    |> Enum.map(fn %{type: t, room: r} -> {Enum.find_index(@rooms, fn rs -> rs == r end), t} end)
    |> Map.new()

    0..3
    |> Enum.map(fn idx ->
      room_map |> Map.get(idx, ".") |> IO.write()
      if idx < 3 do
        IO.write("┃")
      else
        IO.write("┏")
      end
    end)

    IO.puts("━┛")

    IO.write("  ┃")

    room_map = states
    |> Enum.filter(fn %{state: s, position: p} -> Enum.member?([:home, :not_home], s) && (p == 0) end)
    |> Enum.map(fn %{type: t, room: r} -> {Enum.find_index(@rooms, fn rs -> rs == r end), t} end)
    |> Map.new()

    0..3
    |> Enum.map(fn idx ->
      room_map |> Map.get(idx, ".") |> IO.write()
      IO.write("┃")
    end)

    IO.puts("")

    # Tail
    IO.puts("  ┗━┻━┻━┻━┛  ")

    states
  end

  @doc """
  Part 01

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_01 do
    read_amphipods()
    |> IO.inspect(label: "amphipods")
    |> print_amphipods()
    |> find_solutions([])
    |> report_and_filter()
    |> find_winner()
    |> IO.inspect(label: "winner")
  end

  defp find_winner(solutions) do
    solutions
    |> score()
    |> Enum.sort_by(fn {score, _steps} -> score end)
    |> List.first()
  end

  defp report_and_filter(solutions) do
    total = length(solutions)
    actuals = solutions |> Enum.filter(fn {k, _steps} -> k == :solution end)

    IO.puts("[#{total} total move sets, #{length(actuals)} total solutions]")
    actuals
  end

  defp score(solutions) when is_list(solutions) do
    solutions |> Enum.map(&score/1)
  end

  defp score({:solution, steps}) do
    score_key = %{"A" => 1, "B" => 10, "C" => 100, "D" => 1000}

    # add up all the steps
    step_score = steps
    |> Enum.group_by(fn {k, _c} -> k end, fn {_k, c} -> c end)
    |> Enum.map(fn {k, step_list} ->
      sc = step_list
      |> Enum.sum()

      sc * Map.get(score_key, k)
    end)
    |> Enum.sum()

    # return
    {step_score, steps}
  end

  @doc """
  The `moves_to_now` records steps in a tuple of `{piece type, steps}`
  so we can later calculate the score.

  """
  def find_solutions(amphi_state, moves_to_now) do


    if done?(amphi_state) do
      {:solution, moves_to_now}
    else
      # what are our next possible moves
      nm = amphi_state
      |> next_moves()

      if Enum.empty?(nm) do
        {:deadend, []}

      else
        nm
        |> Enum.map(fn {piece, steps, target} ->

          # recurse
          find_solutions(
            apply_movement(amphi_state, piece, target),
            moves_to_now ++ [{target.type, steps}]
          )

        end)
        |> List.flatten()

      end

    end

  end

  def done?(amphi_state) do
    amphi_state |> Enum.map(fn %{state: s} -> s == :home end) |> Enum.all?()
  end

  def apply_movement(amphi_state, piece_name, %{state: s, position: p, room: r}) do

    # remove the piece from amphi state
    amphi_map = amphi_state |> Enum.map(fn %{name: n}=amphi -> {n, amphi} end) |> Map.new()
    update_amphi = amphi_map |> Map.get(piece_name) |> Map.merge(%{state: s, position: p, room: r})

    amphi_map |> Map.drop([piece_name]) |> Map.put(piece_name, update_amphi) |> Map.values()
  end

  @doc """
  Next moves is a list of pieces that can be moved, with each entry looking
  like:

    {piece_name, steps, %{type:t, room: r, position: p, state: s}}
  """
  def next_moves(amphi_state) do

    cond do
      hallway_empty?(amphi_state) ->
        # no one in hallways, all pieces that are not
        # yet home can move to all possible spaces
        # in the hallway
        unblocked_pieces(amphi_state)
        |> Enum.flat_map(fn amphi ->

          hallway_positions()
          |> Enum.map(fn hallway_idx ->

            # what does the movement look like for this piece?
            target = %{type: amphi.type, room: amphi.room, position: hallway_idx, state: :hallway}
            {amphi.name, movement_cost({:room, amphi.room, amphi.position}, {:hallway, hallway_idx}), target}

          end)
        end)

      moves_home?(amphi_state) ->

        moves_home(amphi_state)

      true ->

        # find all other possible moves from a room into the hallway
        unblocked_pieces(amphi_state)

        |> Enum.filter(fn %{state: s} -> s != :home end)

        # find all the hallway positions
        |> Enum.flat_map(fn amphi ->

          hallway_positions()
          |> Enum.map(fn hallway_idx ->
            {amphi, hallway_idx}
          end)
        end)

        # make sure the path is unblocked
        |> Enum.filter(fn {amphi, hallway_idx} ->

          hallway_unblocked(amphi_state, {:room, amphi.room}, {:hallway, hallway_idx})

        end)

        # now turn it into a movement
        |> Enum.map(fn {amphi, hallway_idx} ->

          target = %{type: amphi.type, room: amphi.room, position: hallway_idx, state: :hallway}
          {amphi.name, movement_cost({:room, amphi.room, amphi.position}, {:hallway, hallway_idx}), target}

        end)

    end

  end

  defp hallway_positions do
    [0, 1, 3, 5, 7, 9, 10]
  end

  defp moves_home?(amphi_state) do
    !(moves_home(amphi_state) |> Enum.empty?())
  end

  # can a piece in a hallway move home?
  defp moves_home(amphi_state) do

    room_map = amphi_state
               |> Enum.filter(fn %{state: s} -> s != :hallway end)
               |> Enum.map(fn %{room: r, position: p, type: t} -> {{r, p}, t} end)
               |> Map.new()

    # find pieces that can direct move from room to
    # target
    direct_moves = amphi_state

    # in a room but not home
    |> Enum.filter(fn %{state: s, room: r, type: t} ->
      (s == :not_home) && (t != r)
    end)

    # not blocked
    |> Enum.filter(fn %{position: p, room: r} ->
      if p == 1 do
        true
      else
        if Map.has_key?(room_map, {r, 1}) do
          false
        else
          true
        end
      end
    end)

    # find the path
    |> Enum.filter(fn %{type: t, position: _p, room: r} ->

      room_equiv = ((@rooms |> Enum.find_index(fn rs -> rs == r end)) * 2) + 2

      # is my path unblocked?
      hallway_unblocked(amphi_state, {:hallway, room_equiv}, {:room, t})

        # is my room empty?
      && (
        room_empty?(amphi_state, t)
        || room_partially_home?(amphi_state, t)
        )

    end)
    |> Enum.map(fn %{type: t, position: p, name: n, room: r} ->

      # we know the hallway is clear, let's figure out how
      # to get home

      # what is the hallway equiv position of our room
      target_room_equiv = ((@rooms |> Enum.find_index(fn rs -> rs == t end)) * 2) + 2
      source_room_equiv = ((@rooms |> Enum.find_index(fn rs -> rs == r end)) * 2) + 2

      base_move = abs(source_room_equiv - target_room_equiv) + (2 - p)

      {cost, pos} = if room_empty?(amphi_state, t) do
        {base_move + 2, 0}
      else
        {base_move + 1, 1}
      end

      {n, cost, %{type: t, room: t, position: pos, state: :home}}

    end)

    # find pieces in hallways
    hallway_moves = amphi_state
    |> Enum.filter(fn %{state: s} -> s == :hallway end)
    |> Enum.filter(fn %{type: t, position: p} ->

      # is my path unblocked?
      hallway_unblocked(amphi_state, {:hallway, p}, {:room, t})

      # is my room empty?
      && (room_empty?(amphi_state, t) || room_partially_home?(amphi_state, t))

    end)
    |> Enum.map(fn %{type: t, position: p, name: n} ->

      # we know the hallway is clear, let's figure out how
      # to get home

      # what is the hallway equiv position of our room
      room_equiv = ((@rooms |> Enum.find_index(fn r -> r == t end)) * 2) + 2
      base_move = abs(room_equiv - p)

      {cost, pos} = if room_empty?(amphi_state, t) do
        {base_move + 2, 0}
      else
        {base_move + 1, 1}
      end

      {n, cost, %{type: t, room: t, position: pos, state: :home}}

    end)

    direct_moves ++ hallway_moves
  end

  # is the path from a hallway position to a room entry unblocked?
  defp hallway_unblocked(amphi_state, {:hallway, hall_pos}, {:room, r}) do
    # what is the room hallway equiv
    room_equiv = ((@rooms |> Enum.find_index(fn rs -> rs == r end)) * 2) + 2

    # setup the path
    walking_path = hall_pos..room_equiv

    # now see if _more than one_ amphi is in the way of that path
    blockers = (amphi_state
    |> Enum.filter(fn %{state: s, position: p} ->
      (s == :hallway) && (Enum.member?(walking_path, p))
    end)
    |> length())

    if blockers == 1 do
#      IO.puts("  | hallway (u) (h: #{hall_pos}, r: #{r})")
      true
    else
#      IO.puts("  | hallway (B) (h: #{hall_pos}, r: #{r})")
      false
    end
  end

  defp hallway_unblocked(amphi_state, {:room, r}, {:hallway, hall_pos}) do
    # what is the room hallway equiv
    room_equiv = ((@rooms |> Enum.find_index(fn rs -> rs == r end)) * 2) + 2

    # setup the path
    walking_path = hall_pos..room_equiv

    # now see if _more than one_ amphi is in the way of that path
    amphi_state
    |> Enum.filter(fn %{state: s, position: p} ->
      (s == :hallway) && (Enum.member?(walking_path, p))
    end)
    |> Enum.empty?()
  end

  # is the given room totally empty?
  defp room_empty?(amphi_state, room) do
    amphi_state
    |> Enum.filter(fn %{room: r, state: s} -> Enum.member?([:not_home, :home], s) && (r == room) end)
    |> Enum.empty?()
  end

  # is the given room partially full with someone
  # who is already home?
  defp room_partially_home?(amphi_state, room) do

    room_contents = amphi_state
    |> Enum.filter(fn %{room: r, state: s} -> Enum.member?([:not_home, :home], s) && (r == room) end)
#    |> IO.inspect(label: "room[#{room}] contents")

    # make sure the contents are correct
    number_home = room_contents |> Enum.filter(fn %{state: s} -> s == :home end) |> length()

    number_home == length(room_contents)
  end

  defp hallway_empty?(amphi_state) do
    amphi_state |> Enum.filter(fn %{state: s} -> s == :hallway end) |> Enum.empty?()
  end

  # pieces in rooms that are not currently blocked into rooms
  defp unblocked_pieces(amphi_state) do

    # pieces not currently blocked into a room
    room_map = amphi_state
               |> Enum.filter(fn %{state: s} -> s != :hallway end)
               |> Enum.map(fn %{room: r, position: p, type: t} -> {{r, p}, t} end)
               |> Map.new()

    amphi_state
    |> Enum.filter(fn %{state: s} -> s != :hallway end)
    |> Enum.filter(fn %{room: r, position: p} ->
      if p == 1 do
        true
      else
        if Map.has_key?(room_map, {r, 1}) do
          false
        else
          true
        end
      end
    end)
  end

  defp movement_cost({:room, room, room_pos}, {:hallway, hall_pos}) when is_integer(room_pos) and is_integer(hall_pos) do

    # what is the hallway equiv of our room
    room_equiv = ((@rooms |> Enum.find_index(fn r -> r == room end)) * 2) + 2

    # now calculate the steps
    abs(hall_pos - room_equiv) + (2 - room_pos)
  end

  @doc """
  Part 02

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_02 do

  end

end
