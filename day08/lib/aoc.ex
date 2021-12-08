defmodule AOC do
    
    def read_segment_diagnostics do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n", trim: true)
       |> Enum.map(&parse_diagnostic_line/1)

    end

    defp parse_diagnostic_line(line) do
      [tests, output] = line |> String.split(" | ")
      %{
        tests: tests |> String.split(" ") |> Enum.map(fn test -> test |> String.split("", trim: true) end),
        outputs: output |> String.split(" ") |> Enum.map(fn out -> out |> String.split("", trim: true) end)
      }
    end


    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do
        
      # load the diagnostic data
      read_segment_diagnostics()

      |> Enum.map(&estimate_output/1)
      |> List.flatten()
      |> Enum.filter(fn v -> v != :unknown end)
      |> length()
      |> IO.inspect(label: "1, 4, 7, 8 count")


    end

    # Map the outputs to estimated digits, or :unknown
    defp estimate_output(%{outputs: outputs}) do

      outputs
      |> Enum.map(&estimate_digit/1)

    end

    defp estimate_digit([_a, _b]), do: 1
    defp estimate_digit([_a, _b, _c]), do: 7
    defp estimate_digit([_a, _b, _c, _d]), do: 4
    defp estimate_digit([_a, _b, _c, _d, _e, _f, _g]), do: 8
    defp estimate_digit(_), do: :unknown


    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      read_segment_diagnostics()
      |> Enum.map(fn diagnostic ->

        # build the wiring
        est_wiring = find_wiring(diagnostic) |> List.first()

        # find the number
        diagnostic.outputs
        |> Enum.map(fn output -> project_value_into_segments(est_wiring, output) |> Enum.sort() |> digit_for_segments() end)
        |> Integer.undigits()
        |> IO.inspect(label: "output(#{diagnostic.outputs})")
      end)
      |> Enum.sum()
      |> IO.inspect(label: "segment sum")
    end

    defp find_wiring(%{tests: _tests}=segment_diagnostic) do

      # setup options for the segments
      estimated_wiring = default_segment()
      |> Enum.map(fn c -> {c, MapSet.new(default_segment())} end)
      |> Map.new()

      # now find our easy segments to seed the reduction
      estimated_wiring
                         |> update_segments(segment_diagnostic, 1)
                         |> update_segments(segment_diagnostic, 4)
                         |> update_segments(segment_diagnostic, 7)
                         |> update_segments(segment_diagnostic, 8)
                         |> eliminate_candidates(:pairs)
                         |> eliminate_candidates(:singles)
                         |> eliminate_candidates(:pairs)
                         |> eliminate_candidates(:singles)
                         |> eliminate_candidates(:pairs)
                         |> eliminate_candidates(:singles)
                         |> eliminate_candidates(:projection, segment_diagnostic)


    end

    defp project_value_into_segments(estimated_wiring, value) do

      value
      |> Enum.map(fn value_segment ->

        # find possible segments to light up
        estimated_wiring
        |> Enum.filter(fn {_real_segment, seg_map} -> seg_map |> MapSet.member?(value_segment) end)
        |> Enum.map(fn {real_segment, _seg_map} -> real_segment end)

      end)
      |> List.flatten()
      |> Enum.uniq()
    end


    defp update_segments(estimated_wiring, segment_diagnostic, digit) do
      case find_display(segment_diagnostic, digit) do
        nil -> estimated_wiring
        segs ->
          # union the values for these segments in the estimated wiring
          Enum.reduce(
            segments_for(digit),
            estimated_wiring,
            fn seg, est_wir ->

              # generate the segment intersection
              updated_segments = est_wir
                                 |> Map.get(seg)
                                 |> MapSet.intersection(MapSet.new(segs))

              # store
              est_wir |> Map.put(seg, updated_segments)
            end
          )
      end
    end

    defp eliminate_candidates(estimated_wiring, :pairs) do

      # find a pair of entries that have exactly two entries, which are shared
      # as this is a pair wise elimination step we can take
      estimated_wiring
      |> Enum.filter(fn {_seg, ms} -> MapSet.size(ms) == 2 end)
      |> Map.new()
      |> Enum.group_by(fn {_seg, ms} -> ms |> MapSet.to_list() |> Enum.join("") end)
      |> Enum.filter(fn {_seg_string, seg_tuples} -> length(seg_tuples) == 2 end)
      |> Enum.map(fn {_seg_string, [{_seg, seg_map} | _rest]} -> seg_map end)

      # now iterate and reduce out each of the pairs
      |> Enum.reduce(
          estimated_wiring,
          fn pair, est_wir ->

            # now walk all the segments in the wiring
            default_segment()
            |> Enum.reduce(est_wir,
               fn seg, inner_wiring ->

                 if inner_wiring |> Map.get(seg) |> MapSet.equal?(pair) do
                  # don't remove the original pairings
                  inner_wiring
                 else
                  u_segs = inner_wiring |> Map.get(seg) |> MapSet.difference(pair)
                  inner_wiring |> Map.put(seg, u_segs)
                 end
               end
            )
          end
         )

    end

    defp eliminate_candidates(estimated_wiring, :singles) do

      # find any single candidates
      estimated_wiring
      |> Enum.filter(fn {_seg, ms} -> MapSet.size(ms) == 1 end)
      |> Enum.map(fn {_seg, ms} -> ms end)

      # now remove from the wiring
      |> Enum.reduce(
           estimated_wiring,
           fn single, est_wir ->
              default_segment()
              |> Enum.reduce(
                  est_wir, fn seg, inner_wir ->
                    if inner_wir |> Map.get(seg) |> MapSet.equal?(single) do
                      inner_wir
                    else
                      u_segs = inner_wir |> Map.get(seg) |> MapSet.difference(single)
                      inner_wir |> Map.put(seg, u_segs)
                    end
                  end
                 )
           end
         )
    end

    defp eliminate_candidates(estimated_wiring, :projection, %{tests: test_values}) do

      # build out all the candidate permutations, and see if they
      # make any sense as projected values for our test values
      permuted_wirings = permutations(estimated_wiring)

      # now run the test candidates through the projections
      permuted_wirings
      |> Enum.filter(
           fn permuted_wiring ->

              # we have a wiring permutation, now project all the test values through
              test_values
              |> Enum.map(fn test_value ->
                project_value_into_segments(permuted_wiring, test_value)
                |> valid_display?()
              end)
              |> Enum.all?()
           end
         )

    end

    defp permutations(estimated_wiring) do

      # are there any candidates left?
      if has_pairs?(estimated_wiring) do

        # find the first pair we want to work with
        {[seg_a, seg_b], [est_a, est_b]} = estimated_wiring
        |> Enum.filter(fn {_seg, ms} -> MapSet.size(ms) == 2 end)
        |> Map.new()
        |> Enum.group_by(fn {_seg, ms} -> ms |> MapSet.to_list() |> Enum.join("") end)
        |> Enum.filter(fn {_seg_string, seg_tuples} -> length(seg_tuples) == 2 end)
        |> Enum.map(fn {_seg_string, mapping} ->
          segments = mapping |> Enum.map(fn {seg, _m} -> seg end)
          estimates = mapping |> List.first() |> elem(1)
          {segments, estimates |> MapSet.to_list()}
        end)
        |> List.first()

        # insert the estimates and iterate
        permutations(estimated_wiring |> Map.merge(%{seg_a => MapSet.new([est_a]), seg_b => MapSet.new([est_b])}))
        ++ permutations(estimated_wiring |> Map.merge(%{seg_a => MapSet.new([est_b]), seg_b => MapSet.new([est_a])}))


      else
        [estimated_wiring]
      end
    end

    defp has_pairs?(estimated_wiring) do
      (estimated_wiring
      |> Enum.filter(fn {_seg, ms} -> MapSet.size(ms) == 2 end)
      |> length()) > 0
    end

    defp find_display(%{tests: tests}, 1) do
      tests
      |> Enum.filter(fn test -> length(test) == 2 end)
      |> List.first()
    end

    defp find_display(%{tests: tests}, 4) do
      tests
      |> Enum.filter(fn test -> length(test) == 4 end)
      |> List.first()
    end

    defp find_display(%{tests: tests}, 7) do
      tests
      |> Enum.filter(fn test -> length(test) == 3 end)
      |> List.first()
    end

    defp find_display(%{tests: tests}, 8) do
      tests
      |> Enum.filter(fn test -> length(test) == 7 end)
      |> List.first()
    end

    defp segments_for(1), do: ["c", "f"]
    defp segments_for(2), do: ["a", "c", "d", "e", "g"]
    defp segments_for(3), do: ["a", "c", "d", "f", "g"]
    defp segments_for(4), do: ["b", "c", "d", "f"]
    defp segments_for(5), do: ["a", "b", "d", "f", "g"]
    defp segments_for(6), do: ["a", "b", "d", "e", "f", "g"]
    defp segments_for(7), do: ["a", "c", "f"]
    defp segments_for(8), do: ["a", "b", "c", "d", "e", "f", "g"]
    defp segments_for(9), do: ["a", "b", "c", "d", "f", "g"]
    defp segments_for(0), do: ["a", "b", "c", "e", "f", "g"]

    defp digit_for_segments(["c", "f"]), do: 1
    defp digit_for_segments(["a", "c", "d", "e", "g"]), do: 2
    defp digit_for_segments(["a", "c", "d", "f", "g"]), do: 3
    defp digit_for_segments(["b", "c", "d", "f"]), do: 4
    defp digit_for_segments(["a", "b", "d", "f", "g"]), do: 5
    defp digit_for_segments(["a", "b", "d", "e", "f", "g"]), do: 6
    defp digit_for_segments(["a", "c", "f"]), do: 7
    defp digit_for_segments(["a", "b", "c", "d", "e", "f", "g"]), do: 8
    defp digit_for_segments(["a", "b", "c", "d", "f", "g"]), do: 9
    defp digit_for_segments(["a", "b", "c", "e", "f", "g"]), do: 0

    defp default_segment do
      "abcdefg" |> String.split("", trim: true)
    end

    defp valid_display?(lit_segments) do

      sorted_segments = Enum.sort(lit_segments)
      cond do
        sorted_segments == segments_for(1) -> true
        sorted_segments == segments_for(2) -> true
        sorted_segments == segments_for(3) -> true
        sorted_segments == segments_for(4) -> true
        sorted_segments == segments_for(5) -> true
        sorted_segments == segments_for(6) -> true
        sorted_segments == segments_for(7) -> true
        sorted_segments == segments_for(8) -> true
        sorted_segments == segments_for(9) -> true
        sorted_segments == segments_for(0) -> true
        true -> false
      end
    end

end
