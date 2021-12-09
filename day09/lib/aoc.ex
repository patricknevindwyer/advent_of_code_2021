defmodule AOC do
    
    def read_height_map do
       heights = System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n", trim: true)
       |> Enum.map(fn row ->
        row |> String.split("", trim: true) |> Enum.map(&String.to_integer/1)
       end)

       height = heights |> length()
       width = heights |> List.first() |> length()

       %{width: width, height: height, elevation: heights}
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      # read the height map
      height_map = read_height_map()
      |> IO.inspect(label: "height map")

      # walk coordinates
      coordinates(height_map)
      |> Enum.filter(fn {x, y} ->

        # what's my height?
        me = at(height_map, {x, y})

        # are all my neighbors taller?
        neighbors({x, y}, height_map)
        |> Enum.map(fn n -> at(height_map, n) end)
        |> Enum.map(fn h -> h > me end)
        |> Enum.all?()

      end)
      |> IO.inspect(label: "low points")
      |> Enum.map(fn low -> at(height_map, low) + 1 end)
      |> IO.inspect(label: "low values")
      |> Enum.sum()
      |> IO.inspect(label: "risk ")


    end

    defp at(%{elevation: el}, {x, y}) do
      el |> Enum.at(y) |> Enum.at(x)
    end

    defp coordinates(%{width: width, height: height}) do
      0..(height - 1)
      |> Enum.map(fn y_idx ->
        0..(width - 1)
        |> Enum.map(fn x_idx ->
          {x_idx, y_idx}
        end)
      end)
      |> List.flatten()
    end

    defp neighbors({x_idx, y_idx}, %{width: width, height: height}) do
      [
        {x_idx - 1, y_idx},
        {x_idx + 1, y_idx},
        {x_idx, y_idx - 1},
        {x_idx, y_idx + 1}
      ]
      |> Enum.filter(fn {x, y} ->
        x >= 0 && y >= 0
      end)
      |> Enum.filter(fn {x, y} ->
        x < width && y < height
      end)
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      # read the height map
      height_map = read_height_map()

      # walk coordinates
      coordinates(height_map)
      |> Enum.filter(fn {x, y} ->

        me = at(height_map, {x, y})

        neighbors({x, y}, height_map)
               |> Enum.map(fn n -> at(height_map, n) end)
               |> Enum.map(fn h -> h > me end)
               |> Enum.all?()

      end)
      |> Enum.map(fn low -> find_basin(height_map, low) end)
      |> Enum.map(&length/1)
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.take(3)
      |> IO.inspect(label: "largest")
      |> Enum.reduce(1, fn x, acc -> x * acc end)
      |> IO.inspect(label: "basin score")

    end

    def find_basin(height_map, start) do

      nebs = neighbors(start, height_map)
      |> Enum.filter(fn neb ->
        at(height_map, neb) != 9
      end)
      find_basin(height_map, nebs, [start])
    end

    def find_basin(_height_map, [], points), do: points
    def find_basin(height_map, [from | search], points) do

      # how tall am I?
      me = at(height_map, from)

      # find neighbor points
      nebs = neighbors(from, height_map)

      # filter out from search and points
      |> Enum.filter(fn neb ->
        !Enum.member?(search, neb) && !Enum.member?(points, neb)
      end)

      # are they higher than me? also skip 9s
      |> Enum.filter(fn neb ->
        neb_h =at(height_map, neb)
        (neb_h > me) && (neb_h != 9)
      end)

      find_basin(height_map, search ++ nebs, points ++ [from])
    end


end
