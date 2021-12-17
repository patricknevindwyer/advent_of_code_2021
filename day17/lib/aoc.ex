defmodule AOC do

    def read_target do

      # Parse the hex string
      System.argv()
      |> List.last()
      |> File.read!()
      |> String.trim()

      # target area: x=20..30, y=-10..-5
      |> String.split(":", trim: true)
      |> List.last()
      |> String.split(",")
      |> Enum.map(&parse_range/1)
      |> Map.new()
    end

    defp parse_range(range_str) when is_binary(range_str) do
      [axis, r] = range_str
      |> String.split("=")

      {axis |> String.trim() |> String.to_atom(), r |> String.split("..") |> Enum.map(&String.to_integer/1) |> list_to_range()}
    end

    defp list_to_range([a, b]), do: Range.new(a, b)

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      # setup our positions
      target = read_target()
      |> IO.inspect(label: "target range")


      # probe location. Steps are in reverse order
      %{start: {0, 0}, steps: [{0, 0}]}
      |> launch_probe_stream(target, :max_y)
      |> IO.inspect(label: "max_y")

    end

    defp launch_probe_stream(p, target_area, mode) do

      # let's scan velocities
      hits = velocity_range()
      |> Stream.map(fn vel ->
        IO.inspect(vel, label: "testing velocity")
        p
        |> Map.put(:velocity, vel)
        |> step_probe(target_area)
      end)
      |> Stream.filter(fn {res, _probe_result} -> res == :hit end)

      case mode do

        :max_y ->
          hits
          |> Enum.map(fn {_res, %{steps: steps}} ->
            steps
            |> Enum.map(fn {_x, y} -> y end)
            |> Enum.max()
          end)
          |> Enum.max()

        :count ->
          hits |> Enum.to_list() |> length()
      end

    end

    defp velocity_range do
      -200..200
      |> Enum.map(fn vy ->
        -200..200
        |> Enum.map(fn vx ->
          {vx, vy}
        end)
      end)
      |> List.flatten()
    end

    defp step_probe(%{steps: [{lx, ly} | _rest]=steps, velocity: {vx, vy}}=probe, %{x: x_range, y: y_range}=target_area) do

      # determine the next step
      nx = lx + vx
      ny = ly + vy

      # is this next step within the target?
      if Enum.member?(x_range, nx) and Enum.member?(y_range, ny) do
        {:hit, probe |> Map.put(:steps, [{nx, ny}] ++ steps)}
      else

        cond do
          overshoot?(target_area, {nx, ny}, {lx, ly}) ->
            {:overshoot, probe |> Map.put(:steps, [{nx, ny}] ++ steps)}

          vertical_miss?(target_area, {nx, ny}, {vx, vy}) ->
            {:overshoot, probe |> Map.put(:steps, [{nx, ny}] ++ steps)}

          true ->
            # adjust velocity
            vx_new = cond do
              vx > 0 -> vx - 1
              vx < 0 -> vx + 1
              true -> 0
            end
            vy_new = vy - 1

            step_probe(probe |> Map.merge(%{steps: [{nx, ny}] ++ steps, velocity: {vx_new, vy_new}}), target_area)

        end

      end
    end

    defp overshoot?(%{x: x_range, y: y_range}, {old_x, old_y}, {new_x, new_y}) do

      # decompose our ranges
      {x_low, x_hi} = decompose_range(x_range)
      {y_low, y_hi} = decompose_range(y_range)

      # check transits
      (old_x < x_low && new_x > x_hi) || (old_y < y_low && new_y > y_hi) || (new_x < x_low && old_x > x_hi) || (new_y < y_low && old_y > y_hi)

    end

    defp vertical_miss?(%{x: x_range, y: y_range}, {x, y}, {vx, vy}) do

      cond do
        # zero velocity horizontally, and we're not in range
        vx == 0 and !Enum.member?(x_range, x) -> true

        # zero velocity horizontally, we're in range, but y is moving away
        vx == 0 and Enum.member?(x_range, x) and vy < 0 and moving_away?(y_range, y, vy)-> true

        true -> false
      end
    end

    defp moving_away?(range, coord, vel) do
      {r_low, r_high} = decompose_range(range)

      # -10 .. -5    y = -12 vel = -3
      cond do
        (coord < r_low) && ((vel + coord) < coord) ->
          # moving below
          true

        (coord > r_high) && ((vel + coord) > coord) ->
          # moving above
          true
        true -> false
      end
    end

    defp decompose_range(r) do
      low..high = r
      Enum.min_max([low, high])
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      # setup our positions
      target = read_target()
               |> IO.inspect(label: "target range")


      # probe location. Steps are in reverse order
      %{start: {0, 0}, steps: [{0, 0}]}
      |> launch_probe_stream(target, :count)
      |> IO.inspect(label: "initial positions")

    end


end
