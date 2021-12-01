defmodule AOC do
    
    def read_depths do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split()
       |> Enum.map(
           fn line -> 
               {i, _r} = Integer.parse(line)
               i
           end
           ) 
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
       read_depths()
       |> count_increasing()
       |> IO.inspect(label: "increasing")
    end
    
    def count_increasing([head | rest]) do
        count_increasing(head, rest)
    end
    
    defp count_increasing(lead, [head]) do
        if head > lead do
            1
        else
            0
        end
    end
    
    defp count_increasing(lead, [head | rest]) do
        carry = if head > lead do
            1
        else
            0
        end
        carry + count_increasing(head, rest)
    end
    
    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do
       read_depths() 
       |> Enum.chunk_every(3, 1, :discard)
       |> Enum.map(fn window -> Enum.sum(window) end)
       |> count_increasing()
       |> IO.inspect(label: "increasing")
    end
    

end
