defmodule AOC do
    
    def read_segments do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n")
       |> Enum.map(&parse_segment/1)

    end

    defp parse_segment(s) do
      [l, r] = s |> String.split(" -> ")
      { parse_point(l), parse_point(r) }
    end

    defp parse_point(p) do
      [x, y] = p |> String.split(",")
      {String.to_integer(x), String.to_integer(y)}
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
        
      # gather all the segments
      read_segments()
      |> Enum.filter(&cardinal_segment?/1)
      |> Enum.map(&points_from_segment/1)
      |> List.flatten()
      |> Enum.reduce(
           %{},
           fn point, point_map ->
             if point_map |> Map.has_key?(point) do
               u = point_map |> Map.get(point)
               point_map |> Map.put(point, u + 1)
             else
              point_map |> Map.put(point, 1)
             end
           end
         )
       |> Enum.filter(fn {_point, count} -> count > 1 end)
       |> length()
       |> IO.inspect(label: "intersection count")
    end

    defp cardinal_segment?(s) do
      vertical_segment?(s) || horizontal_segment?(s)
    end

    defp vertical_segment?({{x1, _y1}, {x2, _y2}}) when x1 == x2, do: true
    defp vertical_segment?(_), do: false

    defp horizontal_segment?({{_x1, y1}, {_x2, y2}}) when y1 == y2, do: true
    defp horizontal_segment?(_), do: false

    defp points_from_segment({{x1, y1}, {x2, y2}}=s) do

      if vertical_segment?(s) || horizontal_segment?(s) do
        # line walk
        x1..x2
        |> Enum.map(fn x_idx ->
          y1..y2
          |> Enum.map(fn y_idx ->
            {x_idx, y_idx}
          end)
        end)
        |> List.flatten()
      else
        # diagonal (always 45 degrees)
        Enum.zip(x1..x2, y1..y2)
      end
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      read_segments()
      |> Enum.map(&points_from_segment/1)
      |> List.flatten()
      |> Enum.reduce(
           %{},
           fn point, point_map ->
             if point_map |> Map.has_key?(point) do
               u = point_map |> Map.get(point)
               point_map |> Map.put(point, u + 1)
             else
               point_map |> Map.put(point, 1)
             end
           end
         )
      |> Enum.filter(fn {_point, count} -> count > 1 end)
      |> length()
      |> IO.inspect(label: "intersection count")


    end

end
