defmodule AOC do

    alias ExGrids.Grid2D

    def read_octopodi do
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

      grid = read_octopodi()
      |> Grid2D.Display.display(:integer_cells)

      {final_grid, flashes} = 1..100
      |> Enum.reduce({grid, 0},
           fn _step, {grid_acc, flash_acc} ->
             {stepped_grid, new_flashes} = step(grid_acc)
             {stepped_grid, new_flashes + flash_acc}
           end)

      IO.puts("===")
      IO.puts("Flashes: #{flashes}")
      final_grid |> Grid2D.Display.display(:integer_cells)
    end

    defp step(%Grid2D{}=g) do

      # basic increment
      u_grid = Grid2D.Enum.map(g, fn _u_grid, _coord, v -> v + 1 end)

      # do flashes for this step
      u_grid = u_grid |> process_flashes()

      # count flashes
      flashed_coords = u_grid |> Grid2D.Enum.find_coordinates(fn v -> v < 0 end)

      # update grid
      stepped_grid = u_grid |> Grid2D.Enum.map(fn _g, _c, v ->
        if v >= 0 do
          v
        else
          0
        end
      end)

      {stepped_grid, length(flashed_coords)}
    end

    defp process_flashes(%Grid2D{}=grid) do

      if needs_to_flash?(grid) do
        grid |> flash() |> process_flashes()
      else
        grid
      end
    end

    defp needs_to_flash?(%Grid2D{}=grid) do
      !(grid
      |> Grid2D.Enum.find_coordinates(fn v -> v > 9 end)
      |> Enum.empty?())
    end

    defp flash(%Grid2D{}=grid) do

      # find the coordinates
      coords = grid
      |> Grid2D.Enum.find_coordinates(fn v -> v > 9 end)

      # find all neighbors that need to be increased, and do
      # so
      u_grid = coords
      |> Enum.map(fn flash_coord -> Grid2D.Enum.neighbors(grid, flash_coord) end)
      |> List.flatten()
      |> Enum.reduce(grid, fn flash_coord, grid_acc ->
        n_val = Grid2D.Enum.at!(grid_acc, flash_coord) + 1
        grid_acc |> Grid2D.Enum.put(flash_coord, n_val)
      end)

      # set flashed coords to low number
      coords
      |> Enum.reduce(u_grid, fn flashed_coord, grid_acc ->
        grid_acc |> Grid2D.Enum.put(flashed_coord, -10000)
      end)

    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do
      grid = read_octopodi()
             |> Grid2D.Display.display(:integer_cells)

      {final_grid, sync_step} = step_until_sync(grid, 1)

      IO.puts("===")
      IO.puts("First Sync: #{sync_step}")
      final_grid |> Grid2D.Display.display(:integer_cells)

    end

    defp step_until_sync(%Grid2D{}=g, step_count) do

      # basic increment
      u_grid = Grid2D.Enum.map(g, fn _u_grid, _coord, v -> v + 1 end)

      # do flashes for this step
      u_grid = u_grid |> process_flashes()

      # count flashes
#      flashed_coords = u_grid |> Grid2D.Enum.find_coordinates(fn v -> v < 0 end)

      # update grid
      stepped_grid = u_grid |> Grid2D.Enum.map(fn _g, _c, v ->
        if v >= 0 do
          v
        else
          0
        end
      end)

      # is everyone synced?
      if Grid2D.Enum.all?(stepped_grid, fn v -> v == 0 end) do
        {stepped_grid, step_count}
      else
        step_until_sync(stepped_grid, step_count + 1)
      end

    end

end
