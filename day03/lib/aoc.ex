defmodule AOC do
    
    def read_bits do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n")
       |> Enum.map(
           fn line -> 
               
               line
               |> String.split("", trim: true)
               |> Enum.map(&String.to_integer/1)

           end
           ) 
    end
    
    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
        
       # read in the bits and gather some meta data
       bits = read_bits()
       size = input_bit_size(bits)
       rows = length(bits)
       
       # quick sum at each position
       calculated_bits = 0..(size - 1)
       |> Enum.map(
           fn column -> 
               
               # select the column
               c_sum = select_column(bits, column)
               |> Enum.sum()
               
               if c_sum > (rows - c_sum) do
                   # 1 is the most popular bit
                   %{gamma: 1, epsilon: 0}
               else
                   # 0 is the most popular bit
                   %{gamma: 0, epsilon: 1}
               end
           end
       )
       
       # now use the calculated bits to find our gamma and epsilon
       gamma = calculated_bits
       |> Enum.map(fn %{gamma: g} -> g end)
       |> Enum.map(fn g -> "#{g}" end)
       |> Enum.join("")
       |> String.to_integer(2)

       epsilon = calculated_bits
       |> Enum.map(fn %{epsilon: e} -> e end)
       |> Enum.map(fn e -> "#{e}" end)
       |> Enum.join("")
       |> String.to_integer(2)
       
       IO.inspect(gamma, label: "gamma")
       IO.inspect(epsilon, label: "epsilon")
       IO.inspect(gamma * epsilon, label: "Power Consumption")
       
    end

    defp input_bit_size([head | _rest]), do: length(head)
    
    defp select_column(bits, col) do
       bits
       |> Enum.map(fn bit_set -> Enum.at(bit_set, col) end) 
    end
        
    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do
        
        bits = read_bits()
        
        oxy_rating = filter_bits(bits, 0, :most) |> bits_to_integer()
        coo_rating = filter_bits(bits, 0, :least) |> bits_to_integer()
        
        IO.inspect(oxy_rating, label: "Oxygen Rating")
        IO.inspect(coo_rating, label: "CO2 Rating")
        IO.inspect(oxy_rating * coo_rating, label: "Life Support Rating")
        
    end
    
    defp bits_to_integer(bit_value) do
        bit_value
        |> Enum.map(fn g -> "#{g}" end)
        |> Enum.join("")
        |> String.to_integer(2)
    end
    
    defp filter_bits([head], _col, _filter_for), do: head
    defp filter_bits(list, col, filter_for) do
       common_bit = most_common_bit(list, col)       
       
       case filter_for do
          :most -> 
              list
              |> Enum.filter(
                  fn bit_value -> 
                      (bit_value |> Enum.at(col)) == common_bit
                  end
              )
          :least -> 
              list
              |> Enum.filter(
                  fn bit_value -> 
                      (bit_value |> Enum.at(col)) != common_bit
                  end
              )
       end 
       
       |> filter_bits(col + 1, filter_for)
    end
    
    defp most_common_bit(bits, column) do
        
       rows = length(bits)
           
       col_sum = bits
       |> Enum.map(fn bit_value -> Enum.at(bit_value, column) end)
       |> Enum.sum()
       
       if col_sum >= (rows - col_sum) do
           1
       else
           0
       end
    end
    
end
