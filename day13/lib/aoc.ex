defmodule AOC do

    alias ExGrids.Grid2D

    def read_transparency do
       [dots, folds] = System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n\n")

       # convert the dots to a graph, first by parsing, then by
       # finding the max dimensions
       coords = dots
       |> String.split("\n")
       |> Enum.map(fn dot ->
         [x, y] = String.split(dot, ",", trim: true)
         {{String.to_integer(x), String.to_integer(y)}, "#"}
       end)

       width = (coords |> Enum.map(fn {{x, _y}, _v} -> x end) |> Enum.max()) + 1
       height = (coords |> Enum.map(fn {{_x, y}, _v} -> y end) |> Enum.max()) + 1

       # now parse the fold info
       fold_instructins = folds
       |> String.split("\n")
       |> Enum.map(fn fold ->
        [dir, point] = fold |> String.replace("fold along ", "") |> String.split("=")
        {parse_direction(dir), String.to_integer(point)}
       end)

       grid = Grid2D.Create.new(width: width, height: height, default_value: ".") |> Grid2D.Mutate.inject_values(coords)
       %{folds: fold_instructins, grid: grid}
    end

    def parse_direction("y"), do: :vertical
    def parse_direction("x"), do: :horizontal

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      %{grid: grid, folds: folds} = read_transparency()

      # starting setup
      grid
      |> Grid2D.Enum.dimensions()
      |> IO.inspect(label: "input dimensions")

      # let's do some folds
      folds
      |> Enum.take(1)
      |> IO.inspect(label: "folds")
      |> Enum.reduce(grid, fn {fold_direction, fold_point}, grid_acc ->
        # apply the fold to the grid
        case fold_direction do
          :vertical -> grid_acc |> Grid2D.Mutate.fold(:vertical_up, fold_point, fn t, b -> Enum.min([t, b]) end)
          :horizontal -> grid_acc |> Grid2D.Mutate.fold(:horizontal_left, fold_point, fn l, r -> Enum.min([l, r]) end)
        end
      end)
      |> Grid2D.Enum.coordinates_and_values()
      |> Enum.filter(fn {_coord, v} -> v == "#" end)
      |> length()
      |> IO.inspect(label: "dot count")



    end



    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      %{grid: grid, folds: folds} = read_transparency()

      # starting setup
      grid
      |> Grid2D.Enum.dimensions()
      |> IO.inspect(label: "input dimensions")

      # let's do some folds
      folds
      |> IO.inspect(label: "folds")
      |> Enum.reduce(grid, fn {fold_direction, fold_point}, grid_acc ->
        # apply the fold to the grid
        case fold_direction do
          :vertical -> grid_acc |> Grid2D.Mutate.fold(:vertical_up, fold_point, fn t, b -> Enum.min([t, b]) end)
          :horizontal -> grid_acc |> Grid2D.Mutate.fold(:horizontal_left, fold_point, fn l, r -> Enum.min([l, r]) end)
        end
      end)
      |> Grid2D.Display.display(:character_cells)


    end



end
