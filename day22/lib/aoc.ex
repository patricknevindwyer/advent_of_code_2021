defmodule AOC do

  def read_instructions do
    # read instructions
    System.argv()
    |> List.last()
    |> File.read!()
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&parse_cuboid_instruction/1)
  end

  defp parse_cuboid_instruction(s) do

    [toggle, cuboid] = s |> String.split(" ", trim: true)

    # parse the toggle instruction
    toggle = if toggle == "on" do
      :on
    else
      :off
    end

    # parse the cuboid
    [x, y, z] = cuboid |> String.split(",", trim: true) |> Enum.map(&parse_range/1)

    {toggle, {x, y, z}}
  end

  defp parse_range(r) do
    [l, h] = r
    |> String.split("=")
    |> List.last()
    |> String.split("..")
    |> Enum.map(&String.to_integer/1)
    {l, h}
  end

  @doc """
  Part 01

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_01 do
    read_instructions()
    |> IO.inspect(label: "instructions")
    |> build_cuboid()
    |> map_size()
    |> IO.inspect(label: "on cubes")
  end

  def build_cuboid(instructions) do

    # we're using a simple map setup, and clamping ranges
    instructions
    |> Enum.reduce(%{}, fn {toggle, {x_range, y_range, z_range}}, cuboid ->

      if in_clamped_range?({x_range, y_range, z_range}, -50, 50) do
        IO.puts("processing [#{toggle}] of {#{p(x_range)}, #{p(y_range)}, #{p(z_range)}}")
        # build clamped ranges
        for x <- clamped_range(x_range, -50, 50), y <- clamped_range(y_range, -50, 50), z <- clamped_range(z_range, -50, 50) do
          {x, y, z}
        end
        |> Enum.reduce(cuboid, fn {x, y, z}, inner_cuboid ->
          case toggle do
            :on -> inner_cuboid |> Map.put({x, y, z}, :on)
            :off -> inner_cuboid |> Map.delete({x, y, z})
          end
        end)
      else
        IO.puts("skipping [#{toggle}] of {#{p(x_range)}, #{p(y_range)}, #{p(z_range)}}")
        cuboid
      end
    end)

  end

  defp p({l, h}), do: "#{l}..#{h}"

  defp in_clamped_range?({x_range, y_range, z_range}, min_clamp, max_clamp) do
    in_clamped_range?(x_range, min_clamp, max_clamp)
    && in_clamped_range?(y_range, min_clamp, max_clamp)
    && in_clamped_range?(z_range, min_clamp, max_clamp)
  end

  defp in_clamped_range?({l, h}, min_clamp, max_clamp) do
    if (l > max_clamp) || (h < min_clamp) do
      false
    else
      true
    end
  end

  defp clamped_range({low_range, high_range}, min_clamp, max_clamp) do
    l = max(low_range, min_clamp)
    h = min(high_range, max_clamp)
    l..h
  end

  @doc """
  Part 02

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_02 do

    instructions = read_instructions()

    instructions
    |> inst_min_max()
    |> IO.inspect(label: "ranges")

    instructions
    |> AOC.Cuboids.perform()
    |> IO.inspect(label: "mod-cuboids")

    instructions
    |> combine_cuboids()
    |> IO.inspect(label: "merged")
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> combine_cuboids()
    |> qi()
    |> cell_count()
    |> IO.inspect(label: "cells")
  end

  defp qi(cuboids) do
    cuboids |> cell_count() |> IO.inspect(label: "qi")
    cuboids
  end

  defp combine_cuboids([seed_cuboid | cuboids]) do
    cuboids
    |> Enum.reduce([seed_cuboid], fn cuboid, cuboids_acc ->

#      IO.puts("== Cuboids(#{length(cuboids_acc)})")
#      print_cuboid(cuboid)

      # walk all the cuboids and make a new cuboid list
      cuboids_acc
      |> Enum.map(fn inner_cuboid ->
        merge_cuboids(inner_cuboid, cuboid)
      end)
      |> List.flatten()
      |> Enum.filter(fn {tog, _cube} -> tog == :on end)
      |> Enum.uniq()
    end)
  end

  defp cell_count({:on, {{x_min, x_max}, {y_min, y_max}, {z_min, z_max}}}) do
    r_size(x_min, x_max) * r_size(y_min, y_max) * r_size(z_min, z_max)
  end

  defp cell_count(cuboids) do

    cuboids
    |> Enum.map(&cell_count/1)
    |> Enum.sum()

  end

  defp r_size(l, h), do: Range.new(l, h) |> Enum.count()

  defp print_cuboid({toggle, {x_range, y_range, z_range}}) do
    IO.puts("  processing [#{toggle}] of {#{p(x_range)}, #{p(y_range)}, #{p(z_range)}}")
  end

  @doc """
  Merge two cuboids into a list of new cuboids. We want any merged shape to be
  some N number of new cuboids without overlaps.

  Our cuboid B could overlap as:

    - entirely covering cuboid A (3 axis) (1 new cuboid)
    - entirely covering part of A (2 axis) (2 new cuboid)
    - entirely covering part of a (1 axis) (3 new cuboid)
    - partially covering a (0 axis) (8 new cuboid)
    - entirely disjoint from a (2 new cuboids)

  """
  def merge_cuboids({state_a, {x_range_a, y_range_a, z_range_a}}=cuboid_a, {state_b, {x_range_b, y_range_b, z_range_b}}=cuboid_b) do

    case {ra(x_range_a, x_range_b), ra(y_range_a, y_range_b), ra(z_range_a, z_range_b)} do
      {:all, :all, :all} ->
        # B entirely subsumes A
        [cuboid_b]

      {:none, :none, :none} ->
        # A and B entirely disjoint
        [cuboid_a, cuboid_b]

      {_, _, :none} ->
        # A and B entirely disjoint
        [cuboid_a, cuboid_b]

      {_, :none, _} ->
        # A and B entirely disjoint
        [cuboid_a, cuboid_b]

      {:none, _, _} ->
        # A and B entirely disjoint
        [cuboid_a, cuboid_b]

      {:all, :all, :partial} ->
        # hemisphere cover (2 cuboids)
        # trim A, original b
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:all, :partial, :all} ->
        # hemisphere cover (2 cuboids)
        # trim A, original b
        [
          {state_a, {x_range_a, trim_range(y_range_a, y_range_b), z_range_a}},
          cuboid_b
        ]

      {:partial, :all, :all} ->
        # hemisphere cover (2 cuboids)
        # trim A, original b
        [
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          cuboid_b
        ]

      {:inner, :all, :all} ->
        # slicing in half through the x-axis
        # lower slice
        # upper slice
        # original
        [
          {state_a, {lower_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {upper_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          cuboid_b
        ]

      {:all, :inner, :all} ->
        # slicing in half through the y-axis
        # lower slice
        # upper slice
        # original
        [
          {state_a, {x_range_a, lower_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {x_range_a, upper_range(y_range_a, y_range_b), z_range_a}},
          cuboid_b
        ]

      {:all, :all, :inner} ->
        # slicing in half through the z-axis
        # lower slice
        # upper slice
        # original
        [
          {state_a, {x_range_a, y_range_a, lower_range(z_range_a, z_range_b)}},
          {state_a, {x_range_a, y_range_a, upper_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:inner, :partial, :all} ->
        # channel through the x/z plane
        # trim y
        # lower x
        # upper x
        # original
        [
          {state_a, {x_range_a, trim_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {lower_range(x_range_a, x_range_b), intersect_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {upper_range(x_range_a, x_range_b), intersect_range(y_range_a, y_range_b), z_range_a}},
          cuboid_b
        ]

      {:inner, :all, :partial} ->
        # channel through the x/y plane
        # trim z
        # lower x
        # upper x
        # original
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          {state_a, {lower_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          {state_a, {upper_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :all, :inner} ->
        # channel through the y/z plane
        # trim x
        # lower z
        # upper z
        # original
        [
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), y_range_a, lower_range(z_range_a, z_range_b)}},
          {state_a, {intersect_range(x_range_a, x_range_b), y_range_a, upper_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :inner, :all} ->
        # channel through the y/z plane
        # trim x
        # lower y
        # upper y
        # original
        [
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), lower_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), upper_range(y_range_a, y_range_b), z_range_a}},
          cuboid_b
        ]

      {:all, :partial, :inner} ->
        # channel through the x/z plane
        # trim y
        # upper z
        # lower z
        # original
        [
          {state_a, {x_range_a, trim_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {x_range_a, intersect_range(y_range_a, y_range_b), lower_range(z_range_a, z_range_b)}},
          {state_a, {x_range_a, intersect_range(y_range_a, y_range_b), upper_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:all, :inner, :partial} ->
        # channel through x/y plane
        # trim z
        # lower y
        # upper y
        # original
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          {state_a, {x_range_a, lower_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          {state_a, {x_range_a, upper_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:all, :partial, :partial} ->
        # quadrant cover (3 cuboids)
        # trim a, segment a, original b
        [
          {state_a, {x_range_a, trim_range(y_range_a, y_range_b), z_range_a}},
          # quadrant (x_range_a, overlap_y, trim_z)
          {state_a, {x_range_a, intersect_range(y_range_a, y_range_b), trim_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :all, :partial} ->
        # quadrant cover
        # trim a, segment a, original b
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          # quadrant (x_range_a, trim_y, overlap_z)
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :partial, :all} ->
        # quadrant cover
        # trim a, segment a, original b
        [
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          # quadrant (overlap_x, y_range_a, trim_z)
          {state_a, {intersect_range(x_range_a, x_range_b), trim_range(y_range_a, y_range_b), z_range_a}},
          cuboid_b
        ]

      {:partial, :partial, :partial} ->
        # corner cover
        # trim_a in all three directions
        # trim_a (x, y) overlap z
        # trim_a (x, z) overlap y
        # trim_a (y, z) overlap x
        # overlap (x, y), trim z
        # overlap (x, z), trim y
        # overlap (y, z), trim x
        # original b
        [
          {state_a, {trim_range(x_range_a, x_range_b), trim_range(y_range_a, y_range_b), trim_range(z_range_a, z_range_b)}},

          {state_a, {trim_range(x_range_a, x_range_b), trim_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          {state_a, {trim_range(x_range_a, x_range_b), intersect_range(y_range_a, y_range_b), trim_range(z_range_a, z_range_b)}},
          {state_a, {intersect_range(x_range_a, x_range_b), trim_range(y_range_a, y_range_b), trim_range(z_range_a, z_range_b)}},

          {state_a, {intersect_range(x_range_a, x_range_b), intersect_range(y_range_a, y_range_b), trim_range(z_range_a, z_range_b)}},
          {state_a, {intersect_range(x_range_a, x_range_b), trim_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          {state_a, {trim_range(x_range_a, x_range_b), intersect_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},

          cuboid_b
        ]

      {:inner, :partial, :partial} ->
        # notch in x-axis
        # trim in z, all x, all y
        # left partial
        # middle intersect
        # right partial
        # original b
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          {state_a, {lower_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          {state_a,
            {
              intersect_range(x_range_a, x_range_b),
              trim_range(y_range_a, y_range_b),
              intersect_range(z_range_a, z_range_b)
            }},
          {state_a, {upper_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :inner, :partial} ->
        # notch in y-axis
        # trim in z, all x, all y
        # left partial
        # middle intersect
        # right partial
        # original b
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          {state_a, {x_range_a, lower_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          {state_a,
            {
              trim_range(x_range_a, x_range_b),
              intersect_range(y_range_a, y_range_b),
              intersect_range(z_range_a, z_range_b)
            }},
          {state_a, {x_range_a, upper_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :partial, :inner} ->
        # notch in z-axis
        # trim in z, all x, all y
        # left partial
        # middle intersect
        # right partial
        # original b
        [
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), y_range_a, lower_range(z_range_a, z_range_b)}},
          {state_a,
            {
              intersect_range(x_range_a, x_range_b),
              trim_range(y_range_a, y_range_b),
              intersect_range(z_range_a, z_range_b)
            }},
          {state_a, {intersect_range(x_range_a, x_range_b), y_range_a, upper_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:partial, :inner, :inner} ->
        # hole punched in x face
        # trim x
        # upper z
        # lower z
        # segment lower y
        # segment upper y
        [
          {state_a, {trim_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), y_range_a, upper_range(z_range_a, z_range_b)}},
          {state_a, {intersect_range(x_range_a, x_range_b), y_range_a, lower_range(z_range_a, z_range_b)}},
          {state_a,
            {
              intersect_range(x_range_a, x_range_b),
              lower_range(y_range_a, y_range_b),
              intersect_range(z_range_a, z_range_b)
            }},
          {state_a,
            {
              intersect_range(x_range_a, x_range_b),
              upper_range(y_range_a, y_range_b),
              intersect_range(z_range_a, z_range_b)
            }},
          cuboid_b
        ]

      {:inner, :inner, :partial} ->
        # hole punched in the y face
        # trim z
        # lower x
        # upper x
        # segment lower y
        # segment upper y
        [
          {state_a, {x_range_a, y_range_a, trim_range(z_range_a, z_range_b)}},
          {state_a, {lower_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          {state_a, {upper_range(x_range_a, x_range_b), y_range_a, intersect_range(z_range_a, z_range_b)}},
          {state_a, {intersect_range(x_range_a, x_range_b), lower_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          {state_a, {intersect_range(x_range_a, x_range_b), upper_range(y_range_a, y_range_b), intersect_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

      {:inner, :inner, :all} ->
        # donut
        # lower x
        # upper x
        # intersect lower y
        # intersect upper y
        # original
        [
          {state_a, {lower_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {upper_range(x_range_a, x_range_b), y_range_a, z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), lower_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {intersect_range(x_range_a, x_range_b), upper_range(y_range_a, y_range_b), z_range_a}},
          cuboid_b
        ]

      {:all, :inner, :inner} ->
        # donut
        # lower y
        # upper y
        # intersect lower z
        # intersect upper z
        # original
        [
          {state_a, {x_range_a, lower_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {x_range_a, upper_range(y_range_a, y_range_b), z_range_a}},
          {state_a, {x_range_a, intersect_range(y_range_a, y_range_b), lower_range(z_range_a, z_range_b)}},
          {state_a, {x_range_a, intersect_range(y_range_a, y_range_b), upper_range(z_range_a, z_range_b)}},
          cuboid_b
        ]

    end
  end

  @doc """
  What range of A is covered by B.

    - all
    - partial
    - none
  """
  def ra({min_a, max_a}, {min_b, max_b}) do
    cond do
      (min_b <= min_a) && (max_b >= max_a) -> :all
      Range.disjoint?(Range.new(min_a, max_a), Range.new(min_b, max_b)) -> :none
      (min_b > min_a) && (max_b < max_a) -> :inner
      true -> :partial
    end
  end

  @doc """
  B is inside A, what part of A is lower?
  """
  def lower_range({min_a, max_a}, {min_b, max_b}) do
    {min_a, min_b - 1}
  end

  @doc """
  B is inside A, what part of A is higher?
  """
  def upper_range({min_a, max_a}, {min_b, max_b}) do
    {max_b + 1, max_a}
  end

  @doc """
  Trim range A so it does not overlap with range B
  """
  def trim_range({min_a, max_a}, {min_b, max_b}) do
    if (min_a > min_b) do
      # A is above B
      {max(min_a, max_b + 1), max(max_a, max_b)}
    else
      # A is below B
      {min(min_a, min_b), min(max_a, min_b - 1)}
    end
  end

  @doc """
  Find only the intersection of A with B
  """
  def intersect_range({min_a, max_a}, {min_b, max_b}) do
    if (min_a < min_b) do
      {min_b, min(max_a, max_b)}
    else
      {min(min_a, max_b), max_a}
    end
  end

  defp inst_min_max(instructions) do
    x_min = instructions |> Enum.map(fn {_t, {{v, _}, _, _}} -> v end) |> Enum.min()
    x_max = instructions |> Enum.map(fn {_t, {{_, v}, _, _}} -> v end) |> Enum.max()
    y_min = instructions |> Enum.map(fn {_t, {_, {v, _}, _}} -> v end) |> Enum.min()
    y_max = instructions |> Enum.map(fn {_t, {_, {_, v}, _}} -> v end) |> Enum.max()
    z_min = instructions |> Enum.map(fn {_t, {_, _, {v, _}}} -> v end) |> Enum.min()
    z_max = instructions |> Enum.map(fn {_t, {_, _, {_, v}}} -> v end) |> Enum.max()

    {instructions |> length(), {{x_min, x_max}, {y_min, y_max}, {z_min, z_max}}}
  end

  defmodule Cuboids do
    def perform(instructions) do
      insts = instructions_to_ranges(instructions, [])
      for [a, b, c] <- do_perform(insts, []), reduce: 0 do
        acc -> acc + Enum.count(a) * Enum.count(b) * Enum.count(c)
      end
    end

    defp instructions_to_ranges([], t), do: t
    defp instructions_to_ranges([{state, {{x_l, x_h}, {y_l, y_h}, {z_l, z_h}}} | rest], translated) do
      instructions_to_ranges(rest, translated ++ [{state, [Range.new(x_l, x_h), Range.new(y_l, y_h), Range.new(z_l, z_h)]}])
    end

    defp do_perform([], state), do: state
    defp do_perform([{:off, q} | rest], state), do: do_perform(rest, carve_all(state, q))
    defp do_perform([{:on, q} | rest], state), do: do_perform(rest, [q | carve_all(state, q)])

    defp carve_all(cuboids, other) do
      Enum.flat_map(cuboids, fn qu -> if disjoint?(qu, other), do: [qu], else: carve(qu, other) end)
    end

    defp disjoint?([r1], [r2]), do: Range.disjoint?(r1, r2)
    defp disjoint?([r1 | rest1], [r2 | rest2]), do: disjoint?([r1], [r2]) || disjoint?(rest1, rest2)

    defp carve([], []), do: []

    defp carve([range | rest], [other | rest2]) do
      split(range, other)
      |> Enum.flat_map(fn chunk_x ->
        if Range.disjoint?(chunk_x, other) do
          [[chunk_x | rest]]
        else
          for proj <- carve(rest, rest2), do: [chunk_x | proj]
        end
      end)
    end

    defp split(a..b, x.._) when x > b, do: [a..b]
    defp split(a..b, x..y) when x > a and y >= b, do: [a..(x - 1), x..b]
    defp split(a..b, x..y) when x > a, do: [a..(x - 1), x..y, (y + 1)..b]
    defp split(a..b, _..y) when y >= a and y < b, do: [a..y, (y + 1)..b]
    defp split(a..b, _), do: [a..b]
  end
end
