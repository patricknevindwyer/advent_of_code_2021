defmodule AOC do
    
    def read_syntax do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n", trim: true)
       |> Enum.map(fn l -> l |> String.split("", trim: true) end)
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      read_syntax()
      |> Enum.map(fn code -> parse_brackets(code, []) end)
      |> Enum.filter(fn v ->
        case v do
          {:corrupt, _v} -> true
          _ -> false
        end
      end)
      |> Enum.map(fn {:corrupt, bracket} ->
        %{"}" => 1197, ")" => 3, "]" => 57, ">" => 25137}
        |> Map.get(bracket)
      end)
      |> Enum.sum()
      |> IO.inspect(label: "syntax score")
    end

    defp parse_brackets([], []), do: :complete
    defp parse_brackets([], [_stack_top | _stack_rest]=stack) do
      pairing = %{"{" => "}", "(" => ")", "[" => "]", "<" => ">"}
      {
        :incomplete,
        stack |> Enum.map(fn b -> pairing |> Map.get(b) end)
      }
    end
    defp parse_brackets([next | rest], []), do: parse_brackets(rest, [next])
    defp parse_brackets([next | rest], [stack_top | stack_rest]=stack) do

      if Enum.member?(["(", "{", "[", "<"], next) do

        # push onto the front of the stack and continue
        parse_brackets(rest, [next] ++ stack)

      else

        pairing = %{"{" => "}", "(" => ")", "[" => "]", "<" => ">"}
        # we need to pop a bracket
        if next == Map.get(pairing, stack_top) do
          # continue parsing
          parse_brackets(rest, stack_rest)
        else
          {:corrupt, next}
        end
      end
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      read_syntax()
      |> Enum.map(fn code -> parse_brackets(code, []) end)
      |> Enum.filter(fn v ->
        case v do
          {:incomplete, _v} -> true
          _ -> false
        end
      end)
      |> Enum.map(&score_completion/1)
      |> Enum.sort()
      |> middle()
      |> IO.inspect(label: "completion score")
    end

    def score_completion({:incomplete, brackets}) do
      brackets
      |> Enum.reduce(0, fn b, acc ->
        score = %{")" => 1, "]" => 2, "}" => 3, ">" => 4}
        acc * 5 + Map.get(score, b)
      end)
    end

    def middle(list) do
      Enum.at(list, div(length(list), 2))
    end
end
