defmodule AOC do
    
    def read_instructions do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n")
       |> Enum.map(
           fn line -> 
               [dir, amt] = String.split(line, " ")

               dir
               |> encode_direction()
               |> decode_amount(amt)
           end
           ) 
    end
    
    defp encode_direction("forward"), do: :forward
    defp encode_direction("down"), do: :down
    defp encode_direction("up"), do: :up
    
    defp decode_amount(:forward, amt) do
        {:forward, String.to_integer(amt)}
    end
    
    defp decode_amount(:down, amt) do
        {:down, String.to_integer(amt)}
    end
    
    defp decode_amount(:up, amt) do
        {:up, String.to_integer(amt) * -1}
    end
    

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
       read_instructions()
       |> Enum.reduce(%{horizontal: 0, depth: 0}, &navigate_with/2)
       |> IO.inspect(label: "location")
       |> final()
       |> IO.inspect(label: "final")
    end

    defp navigate_with({:forward, amt}, %{horizontal: h, depth: d}) do
        %{horizontal: h + amt, depth: d}
    end
    
    defp navigate_with({_, amt}, %{horizontal: h, depth: d}) do
        %{horizontal: h, depth: d + amt}
    end
    
    defp final(%{horizontal: h, depth: d}), do: h * d
        
    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do
        read_instructions()
        |> Enum.reduce(%{horizontal: 0, depth: 0, aim: 0}, &navigate_with_aim/2)
        |> IO.inspect(label: "location")
        |> final()
        |> IO.inspect(label: "final")
        
    end
    
    defp navigate_with_aim({:forward, amt}, %{horizontal: h, depth: d, aim: a}) do
        %{horizontal: h + amt, depth: d + (a * amt), aim: a}
    end
    
    defp navigate_with_aim({_, amt}, %{horizontal: h, depth: d, aim: a}) do
        %{horizontal: h, depth: d, aim: a + amt}
    end

end
