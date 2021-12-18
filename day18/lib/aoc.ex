defmodule AOC do

    def read_snail_sums do

      # Parse the hex string
      System.argv()
      |> List.last()
      |> File.read!()
      |> String.trim()
      |> String.split("\n", trim: true)
      |> Enum.map(&parse_snail_sum/1)
    end

    def parse_snail_sum(s) do
      s
      |> String.split("", trim: true)
      |> Enum.map(fn c ->
        case c do
          "[" -> :L
          "]" -> :R
          "," -> :skip
          d -> String.to_integer(d)
        end
      end)
      |> Enum.filter(fn t -> t != :skip end)
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      [first | others] = read_snail_sums()
      |> IO.inspect(label: "homework")
      Enum.reduce(others, first, fn addend, acc ->
        snail_sum([acc, addend])
        |> List.flatten()
        |> snail_reduce()
        |> List.flatten()
      end)
      |> IO.inspect(label: "reduced")
      |> magnitude()
      |> IO.inspect(label: "magnitude")

    end

    defp magnitude(snail_number) do

      # find the next available pair number
      case pair_offset(snail_number, 0) do
        nil -> snail_number
        idx ->
#          IO.puts("  + pair offset (#{idx})")
          # we have a pair
          l_val = snail_number |> Enum.at(idx)
          r_val = snail_number |> Enum.at(idx + 1)
          m = (l_val * 3) + (r_val * 2)

          # do the insert
          snail_number
          |> List.delete_at(idx + 2)
          |> List.delete_at(idx + 1)
          |> List.delete_at(idx)
          |> List.replace_at(idx - 1, m)
#          |> IO.inspect(label: "applied")
          |> magnitude()
      end

    end

    defp pair_offset([], _c), do: nil
    defp pair_offset([a, b | _rest], carry) when is_integer(a) and is_integer(b), do: carry
    defp pair_offset([_a | rest], carry), do: pair_offset(rest, carry + 1)
    defp pair_offset(_l, _c), do: nil

    defp snail_sum([a, b]) do
      [:L, a, b, :R]
    end

    defp snail_sum([a, b | rest]) do
      snail_sum([[:L, a, b, :R]] ++  rest)
    end

    defp snail_reduce(snail_number) do

      cond do
        explode?(snail_number) ->
          explode(snail_number)
          |> IO.inspect(label: "exploded")
          |> snail_reduce()


        split?(snail_number) ->
          split(snail_number)
          |> IO.inspect(label: "split  ")
          |> snail_reduce()

        true ->
          snail_number

      end

    end

    defp explode?(snail_number) do
      # a pair nested inside four pairs (fifth paren)
      explode_offsets(snail_number) != nil
    end

    defp explode(snail_number) do

      # find the offsets
      {eo_s, eo_e} = explode_offsets(snail_number)
#                     |> IO.inspect(label: "explode range")

      # select the values
      [_bracket_l, left, right, _bracket_r] = snail_number
                                              |> Enum.slice(eo_s, eo_e - eo_s)
#                                              |> IO.inspect(label: "exploding")

      # find left most explode. this is looking through a reversed
      # list of the head of the snail number, we then turn that
      # result into a normal index, if it exists
      left_carry_index = snail_number
                         |> Enum.slice(0..eo_s)
                         |> Enum.reverse()
                         |> Enum.find_index(fn hv -> is_integer(hv) end)

      snail_number = if left_carry_index == nil do
        snail_number
      else
        # convert the index
        left_index = eo_s - left_carry_index

        # get the value
        v = snail_number |> Enum.at(left_index)
        snail_number |> List.replace_at(left_index, v + left)
      end
#      |> IO.inspect(label: "l carry")

      # find right most explode
      right_carry_index = snail_number
                          |> Enum.slice(eo_e, length(snail_number))
                          |> Enum.find_index(fn hv -> is_integer(hv) end)

      snail_number = if right_carry_index == nil do
        snail_number
      else

        right_index = eo_e + right_carry_index

        # get the value
        v = snail_number |> Enum.at(right_index)
        snail_number |> List.replace_at(right_index, v + right)
      end
#      |> IO.inspect(label: "r carry")

      # insert 0
      Enum.slice(snail_number, 0..(eo_s - 1)) ++ [0] ++ Enum.slice(snail_number, (eo_e..length(snail_number)))
#      |> IO.inspect(label: "replace")
    end

    defp split?(snail_number) do
      split_offset(snail_number) != nil
    end

    def split(snail_number) do
      s_at = split_offset(snail_number)
      v_at = snail_number |> Enum.at(s_at)

      l_val = (v_at / 2) |> Kernel.floor()
      r_val = (v_at / 2) |> Kernel.ceil()

      snail_number |> List.replace_at(s_at, [:L, l_val, r_val, :R]) |> List.flatten()
    end

    def split_offset(snail_number) do
      snail_number |> Enum.find_index(fn v -> is_integer(v) and v > 9 end)
    end

    defp explode_offsets(snail_number) do
      case brace_open_offset(snail_number, 0, 4, 0) do
        nil -> nil
        v ->
          # find the next index for ]
          match = snail_number |> Enum.drop(v + 1) |> Enum.find_index(fn b -> !is_integer(b) end)
          {v, v + match + 2}
      end
    end

    defp brace_open_offset([], _offset, _target, _current), do: nil
    defp brace_open_offset([next | snail_number], offset_carry, target_count, current_count) do

      cond do
        (next == :L) and (target_count <= current_count) ->

          # check the next two values - if integers, we're good
          [peek_a, peek_b | _rest] = snail_number

          # is our lookahead an integer
          if is_integer(peek_a) and is_integer(peek_b) do
            # found it
            offset_carry
          else
            # we're not in a pair
            brace_open_offset(snail_number, offset_carry + 1, target_count, current_count + 1)
          end

        (next == :L) ->
          # opening brace, keep going
          brace_open_offset(snail_number, offset_carry + 1, target_count, current_count + 1)

        (next == :R) ->
          # closing bracket
          brace_open_offset(snail_number, offset_carry + 1, target_count, current_count - 1)

        true ->
          # value
          brace_open_offset(snail_number, offset_carry + 1, target_count, current_count)

      end
    end


    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      read_snail_sums()
      |> combinations_calc(2)
      |> extend_combination()
      |> Enum.map(fn [a, b] ->
        IO.puts("====")
        IO.inspect(a, label: "a  ")
        IO.inspect(b, label: "b  ")
        snail_sum([a, b])
        |> List.flatten()
        |> snail_reduce()
        |> List.flatten()
        |> IO.inspect(label: "sum")
        |> magnitude()
        |> IO.inspect(label: "reduce result")
        |> List.first()
      end)
      |> Enum.max()
      |> IO.inspect(label: "max magnitude")

    end

    defp extend_combination([]), do: []
    defp extend_combination([[a, b] | rest]) do
      [[a, b], [b, a]] ++ extend_combination(rest)
    end

    defp combinations_calc(_, 0), do: [[]]
    defp combinations_calc([], k) when is_integer(k), do: []

    defp combinations_calc([head | tail], k) when is_integer(k) do
      Enum.map(
        combinations_calc(tail, k - 1),
        fn r_comb ->
          [head | r_comb]
        end
      ) ++ combinations_calc(tail, k)
    end
end
