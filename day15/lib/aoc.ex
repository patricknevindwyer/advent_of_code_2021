defmodule AOC do

    alias ExGrids.Grid2D
    alias Astar
    def read_cave do

      System.argv()
      |> List.last()
      |> File.read!()
      |> Grid2D.Create.from_string(:integer_cells)

    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      grid = read_cave()
      |> Grid2D.Display.display(:integer_cells)

      {w, h} = Grid2D.Enum.dimensions(grid)

      Astar.astar(
        {
          fn {x, y} -> neighbors(grid, {x, y}, :cardinal) end,
          fn _from, to -> Grid2D.Enum.at!(grid, to) end,
          fn {s_x, s_y}, {e_x, e_y} -> abs(s_x - e_x) + abs(s_y - e_y) end
        },
        {0, 0},
        {w - 1, h - 1}
      )
      |> IO.inspect(label: "astart path")
      |> Enum.map(fn coord -> Grid2D.Enum.at!(grid, coord) end)
      |> Enum.sum()
      |> IO.inspect(label: "path cost")

    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      # read the base grid grid
      og_grid = read_cave()

      # grid our new test grid horizontally
      horz_strip = increase_grid([og_grid], 5)
      |> append_grids(:horizontal)
      full_grid = increase_grid([horz_strip], 5)
      |> append_grids(:vertical)
      |> Grid2D.Display.display(:integer_cells)
      {w, h} = Grid2D.Enum.dimensions(full_grid)

      # now solve
      Astar.astar(
        {
          fn {x, y} -> neighbors(full_grid, {x, y}, :cardinal) end,
          fn _from, to -> Grid2D.Enum.at!(full_grid, to) end,
          fn {s_x, s_y}, {e_x, e_y} -> abs(s_x - e_x) + abs(s_y - e_y) end
        },
        {0, 0},
        {w - 1, h - 1}
      )
      |> IO.inspect(label: "astart path")
      |> Enum.map(fn coord -> Grid2D.Enum.at!(full_grid, coord) end)
      |> Enum.sum()
      |> IO.inspect(label: "path cost")

    end

    defp increase_grid(grid_list, total_grids) do
      if length(grid_list) == total_grids do
        grid_list
      else

        # take the last grid in the list, and modify it
        dupe_grid = grid_list
        |> List.last()
        |> Grid2D.Enum.map(fn v ->
          if v == 9 do
            1
          else
            v + 1
          end
        end)

        # recurse
        increase_grid(grid_list ++ [dupe_grid], total_grids)
      end
    end

    @doc """
    Retrieve just the cardinal neighbors
    """
    def neighbors(%Grid2D{}=g, {x, y} = coord, :cardinal) do
      [
        {x, y - 1},
        {x + 1, y},
        {x, y + 1},
        {x - 1, y}
      ]
      |> Enum.filter(fn n_coord ->
        # must be in the grid and must not be ourself
        (n_coord != coord) && Grid2D.Enum.contains_point?(g, n_coord)
      end)
    end

    def append_grids(grid_list, :horizontal) do

      # setup our target grid
      {w, h} = grid_list |> List.first() |> Grid2D.Enum.dimensions()
      new_grid = Grid2D.Create.new(width: w * length(grid_list), height: h)

      # insert the grid data
      grid_list
      |> Enum.with_index()
      |> Enum.reduce(new_grid, fn {insert_grid, grid_idx}, new_grid_acc ->

        # insert our coordinates, but shifted
        w_offset = w * grid_idx

        Grid2D.Enum.coordinates_and_values(insert_grid)
        |> Enum.reduce(new_grid_acc, fn {{x, y}, v}, inner_acc ->
          inner_acc |> Grid2D.Enum.put({x + w_offset, y}, v)
        end)
      end)
    end

    def append_grids(grid_list, :vertical) do

      # setup our target grid
      {w, h} = grid_list |> List.first() |> Grid2D.Enum.dimensions()
      new_grid = Grid2D.Create.new(width: w, height: h * length(grid_list))

      # insert the grid data
      grid_list
      |> Enum.with_index()
      |> Enum.reduce(new_grid, fn {insert_grid, grid_idx}, new_grid_acc ->

        # insert our coordinates, but shifted
        h_offset = h * grid_idx

        Grid2D.Enum.coordinates_and_values(insert_grid)
        |> Enum.reduce(new_grid_acc, fn {{x, y}, v}, inner_acc ->
          inner_acc |> Grid2D.Enum.put({x, y + h_offset}, v)
        end)
      end)
    end

end
