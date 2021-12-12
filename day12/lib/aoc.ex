defmodule AOC do
  
    def read_graph do
       System.argv()
       |> List.last()
       |> File.read!()
       |> String.split("\n", trim: true)
       |> Enum.map(fn line ->

          # make a node to caves pair of tuples
          [cave_a, cave_b] = line |> String.split("-", trim: true)

          [
            {cave_a, cave_b},
            {cave_b, cave_a}
          ]
       end)
       |> List.flatten()
       |> Enum.group_by(fn {a, _b} -> a end, fn {_b, a} -> a end)
       |> Map.new()
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      read_graph()
      |> IO.inspect(label: "caves")
      |> routes()
      |> IO.inspect(label: "routes")
      |> length()
      |> IO.inspect(label: "total routes")
    end

    defp routes(graph) when is_map(graph) do
      traverse_routes(graph, "start", [], MapSet.new())
      |> List.flatten()
      |> route_splitter([], [])
    end

    defp traverse_routes(_graph, "end", route, _visited_map_set), do: route ++ ["end"]
    defp traverse_routes(graph, location, route, visited_map_set) do

      # get the next possible steps
      next_steps = graph |> Map.get(location)

      # check that the steps can be taken
      next_steps
      |> Enum.filter(fn next_step ->
        if small_cave?(next_step) do
          !MapSet.member?(visited_map_set, next_step)
        else
          # big cave, all good
          true
        end
      end)

      # take them
      |> Enum.map(fn next_step ->
        # add our current step to the visited map, and to the tail of the route
        # and move along
        traverse_routes(
          graph,
          next_step,
          route ++ [location],
          visited_map_set |> MapSet.put(location)
        )
      end)

    end

    defp small_cave?(cave), do: String.downcase(cave) == cave

    defp route_splitter([], _partial_route, route_stack), do: route_stack
    defp route_splitter([step | flat_steps], partial_route, route_stack) do
      if step == "end" do
        route_splitter(
          flat_steps,
          [],
          route_stack ++ [(partial_route ++ [step])]
        )
      else
        route_splitter(flat_steps, partial_route ++ [step], route_stack)
      end
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do
      read_graph()
      |> IO.inspect(label: "caves")
      |> extended_routes()
      |> IO.inspect(label: "routes")
      |> length()
      |> IO.inspect(label: "total routes")

    end

    defp extended_routes(graph) when is_map(graph) do
      traverse_extended_routes(graph, "start", [], Map.new())
      |> List.flatten()
      |> route_splitter([], [])
    end

    defp traverse_extended_routes(_graph, "end", route, _visited_map_set), do: route ++ ["end"]
    defp traverse_extended_routes(graph, location, route, visited_map) do

      # get the next possible steps
      next_steps = graph |> Map.get(location)

      # check that the steps can be taken
      next_steps
      |> Enum.filter(fn next_step ->

        cond do
          next_step == "start" -> false
          small_cave?(next_step) ->
            if Map.get(visited_map, next_step, 0) == 0 do
              # haven't visited yet
              true
            else
              # we've visited already, but have we _double_ visisted?
              !already_double_visited?(visited_map)
            end

          true -> true
        end

      end)

        # take them
      |> Enum.map(fn next_step ->
        # add our current step to the visited map, and to the tail of the route
        # and move along
        location_visit_count = visited_map |> Map.get(next_step, 0)
        traverse_extended_routes(
          graph,
          next_step,
          route ++ [location],
          visited_map |> Map.put(next_step, location_visit_count + 1)
        )
      end)

    end

    defp already_double_visited?(visit_map) do
      !(visit_map

      # only small caves
      |> Enum.filter(fn {cave, _v} ->
        String.downcase(cave) == cave
      end)
      |> Enum.filter(fn {_cave, v} -> v == 2 end)
      |> Enum.empty?())
    end

end
