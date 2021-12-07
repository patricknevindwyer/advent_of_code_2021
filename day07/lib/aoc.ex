defmodule AOC do
    
    def read_crabs do
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
        
      # load the crabs
      crabs = read_crabs()
      |> IO.inspect(label: "initial positions")

      # possible positions
      possible_alignments(crabs)
      |> IO.inspect(label: "possible alignments")
      |> Enum.map(fn alignment -> alignment |> fuel_for_alignment(crabs) end)
      |> Enum.min()
      |> IO.inspect(label: "minimum fuel")

    end

    defp possible_alignments(crabs) do
      Enum.min(crabs)..Enum.max(crabs) |> Enum.to_list()
    end

    defp fuel_for_alignment(alignment, crabs) do
      crabs
      |> Enum.map(fn crab -> abs(alignment - crab) end)
      |> Enum.sum()
    end

    defp growing_fuel_for_alignment(alignment, crabs, fuel_cache) do

      crabs
      |> Enum.map(fn crab ->
        Map.get(fuel_cache, abs(alignment - crab))
      end)
      |> Enum.sum()
    end

    defp build_fuel_cache(n) do
      0..n
      |> Enum.reduce(%{}, fn fuel, fuel_map ->
        case fuel do
          0 -> fuel_map |> Map.put(0, 0)
          1 -> fuel_map |> Map.put(1, 1)
          n ->
            last = Map.get(fuel_map, n - 1)
            fuel_map |> Map.put(n, last + n)
        end
      end)
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      # load the crabs
      crabs = read_crabs()
              |> IO.inspect(label: "initial positions")

      # build a fuel cache
      fuel_cache = build_fuel_cache(Enum.max(crabs))

      # possible positions
      possible_alignments(crabs)
      |> IO.inspect(label: "possible alignments")
      |> Enum.map(fn alignment -> alignment |> growing_fuel_for_alignment(crabs, fuel_cache) end)
      |> Enum.min()
      |> IO.inspect(label: "minimum fuel")


    end

end
