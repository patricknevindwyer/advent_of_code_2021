defmodule AOC do

    def read_polymer_template do
       [template, rules] = System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n\n")

       %{
        template: template |> String.split("", trim: true),
        rules: parse_rules(rules)
       }
    end

    defp parse_rules(rule_str) do
      rule_str
      |> String.split("\n", trim: true)
      |> Enum.map(fn rule ->
        [pair, ins] = rule
        |> String.split(" -> ")



        {pair |> String.split("", trim: true), ins}
      end)
      |> Map.new()
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      read_polymer_template()
      |> IO.inspect(label: "template")
      |> polymerize(10)
      |> polymer_score()
      |> IO.inspect(label: "polymer score")

    end

    defp polymer_score(final_polymer) when is_list(final_polymer) do
      {min_p, max_p} = final_polymer
      |> Enum.frequencies()
      |> Enum.map(fn {_k, v} -> v end)
      |> Enum.min_max()

      max_p - min_p
    end

    defp polymerize(%{template: template, rules: rules}, steps) do

      polymer_run(template, rules, steps)
    end

    defp polymer_run(template, _rules, 0), do: template
    defp polymer_run(template, rules, step) do

      tail = template |> List.last()

      # break out the chunks
      template
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [pair_a, _pair_b]=pair ->
        [pair_a, Map.get(rules, pair)]
      end)
      |> Kernel.++([tail])
      |> List.flatten()
      |> polymer_run(rules, step - 1)
    end



    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do

      read_polymer_template()
                      |> IO.inspect(label: "template")
                      |> group_polymerize(40)
                      |> group_polymer_score()
                      |> IO.inspect(label: "polymer score")


    end

    defp group_polymer_score(t_freqs) do

      # split the letter pairs into separate letter counts
      {min_p, max_p} = t_freqs
      |> IO.inspect(label: "group frequencies")
      |> Enum.map(fn {[pair_a, _pair_b], count} -> [{pair_a, count}] end)
      |> List.flatten()

      # gather them all together
      |> Enum.reduce(%{}, fn {letter, count}, count_acc ->
        existing = count_acc |> Map.get(letter, 0)
        count_acc |> Map.put(letter, existing + count)
      end)

      # Now run the score
      |> Enum.map(fn {_k, v} -> v end)
      |> Enum.min_max()
      max_p - min_p + 1
    end

    defp group_polymerize(%{template: template, rules: rules}, steps) do

      # bake the template into a pair map
      template
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.frequencies()
      |> group_polymer_run(rules, steps)

    end

    defp group_polymer_run(t_freqs, _rules, 0), do: t_freqs
    defp group_polymer_run(t_freqs, rules, step) do

      t_freqs

      # determine all the insertions
      |> Enum.map(fn {[pair_a, pair_b]=pair, pair_count} ->

        # what are we inserting
        insert = rules |> Map.get(pair)

        # counts of what we're adding
        [{[pair_a, insert], pair_count}, {[insert, pair_b], pair_count}]
      end)
      |> List.flatten()

      # now reduce those insertions into our existing frequencies
      |> Enum.reduce(%{}, fn {pair, count}, freq_acc ->
        existing = freq_acc |> Map.get(pair, 0)
        freq_acc |> Map.put(pair, existing + count)
      end)

      # and continue
      |> group_polymer_run(rules, step - 1)
    end



end
