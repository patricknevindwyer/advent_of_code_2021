defmodule AOC do
    
    def read_fish do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split(",", trim: true)
       |> Enum.map(&String.to_integer/1)

    end


    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
        
      # age some fish
      read_fish()
      |> IO.inspect(label: "initial state")
      |> age_fish(80)
      |> IO.inspect(label: "aged fish")
      |> length()
      |> IO.inspect(label: "number of fish")

    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      # setup our initial fish pool
      fish_pool = 0..8
      |> Enum.map(fn age -> {age, 0} end)
      |> Map.new()

      input_fish = read_fish()
      |> Enum.group_by(fn i -> i end)
      |> Enum.map(fn {age, fish} -> {age, length(fish)} end)
      |> Map.new()

      # setup the total fish pool
      fish_pool = fish_pool |> Map.merge(input_fish)

      fish_pool
      |> IO.inspect(label: "pools of fish")
      |> age_fish(256)
      |> IO.inspect(label: "aged fish")
      |> Enum.map(fn {_age, count} -> count end)
      |> Enum.sum()
      |> IO.inspect(label: "number of fish")
    end

    defp age_fish(%{}=fish_pool, 0), do: fish_pool
    defp age_fish(%{}=fish_pool, days) do
      # count any 0 aged fish, these will be our new fish
      new_fish = fish_pool |> Map.get(0)

      # cycle the fish ages
      fish_pool = fish_pool
      |> Enum.map(fn {age, count} -> {age - 1, count} end)
      |> Map.new()

      # update the -1 aged fish
      cycle_fish = fish_pool |> Map.get(-1)
      sixth_fish = fish_pool |> Map.get(6)
      fish_pool = fish_pool |> Map.put(6, cycle_fish + sixth_fish) |> Map.delete(-1)

      # add the newly aged fish
      fish_pool = fish_pool |> Map.put(8, new_fish)

      age_fish(fish_pool, days - 1)
    end

    defp age_fish(fish, 0), do: fish
    defp age_fish(fish, days) do
      # age
      fish = fish
             |> Enum.map(fn age -> age - 1 end)

      # check for new fish condition
      n_fish = fish
               |> Enum.filter(fn age -> age == -1 end)
               |> length()

      new_fish = if n_fish > 0 do
        1..n_fish |> Enum.map(fn _idx -> 8 end)
      else
        []
      end

      # reset any -1s
      fish = fish
             |> Enum.map(fn age ->
        if age == -1 do
          6
        else
          age
        end
      end)

      # recurse
      age_fish(fish ++ new_fish, days - 1)
    end

end
