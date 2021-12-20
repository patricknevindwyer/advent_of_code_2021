defmodule AOC do


  defmodule Aoc2021.Day19 do
    def parse(l), do: Enum.map(tl(l), fn x -> String.split(x, ",") |> Enum.map(&String.to_integer/1) end)
    def prep(args), do: Enum.chunk_by(args, &(&1=="")) |> Enum.reject(&(&1==[""])) |> Enum.map(&parse(&1))

    def rots(), do: [[-3, -2, -1], [-3, -1, 2], [-3, 1, -2], [-3, 2, 1],
                  [-2, -3, 1], [-2, -1, -3], [-2, 1, 3], [-2, 3, -1],
                  [-1, -3, -2], [-1, -2, 3], [-1, 2, -3], [-1, 3, 2],
                  [1, -3, 2], [1, -2, -3], [1, 2, 3], [1, 3, -2],
                  [2, -3, -1], [2, -1, 3], [2, 1, -3], [2, 3, 1],
                  [3, -2, 1], [3, -1, -2], [3, 1, 2], [3, 2, -1]]

    def delta([x1,y1,z1],[x2,y2,z2]), do: abs(x2-x1)+abs(y2-y1)+abs(z2-z1)
    def shift([x1,y1,z1],[x2,y2,z2]), do: [x2-x1,y2-y1,z2-z1]
    def shiftv(l, d), do: Enum.map(l, &shift(d, &1))

    def alignxyz( l, r ) do
      shifts = for a <- l, b <- r, do: shift(a,b)
      {best, freq} = Enum.frequencies(shifts) |> Enum.max_by(&(elem(&1,1)))
      if freq >= 12, do: best, else: nil
    end

    def pick(l, rot), do: Enum.at(l, abs(rot)-1)*div(rot, abs(rot))
    def rotate([], _), do: []
    def rotate([ h | t ], r=[r0,r1,r2]), do: [[pick(h,r0), pick(h,r1), pick(h,r2)] | rotate(t,r)]

    def alignrot(l, r), do: for rot <- rots(), into: %{}, do: {rot, alignxyz(l, rotate(r, rot))}

    def alignnext(_, [], good, bad, pos), do: { good, bad, pos }
    def alignnext(next, [ h | t ], good, bad, pos ) do
      rd = alignrot(next, h) |> Enum.find(&(not is_nil(elem(&1,1))))
      case rd do
        { rot, diff } -> alignnext(next, t, [ shiftv(rotate(h,rot),diff) | good], bad, [ diff | pos ])
        nil -> alignnext(next, t, good, [ h | bad ], pos)
      end
    end

    def alignall(done, aligned, []), do: Enum.concat(done,aligned)
    def alignall(done, [ next | t ], rest) do
      {new, rest, _} = alignnext(next, rest, [], [], [])
      alignall([ next | done ], Enum.concat(new, t), rest)
    end

    def part1(args) do
      scans = prep(args)
      beacons = Enum.concat(alignall([], [ hd(scans) ], tl(scans)))
      beacons |> Enum.frequencies() |> Map.keys() |> Enum.count()
    end

    def alignall2(pos, _, []), do: pos
    def alignall2(pos, [ next | t ], rest) do
      {new, rest, npos} = alignnext(next, rest, [], [], [])
      alignall2(Enum.concat(pos, npos), Enum.concat(new, t), rest)
    end

    def part2(args) do
      scans = prep(args)
      pos = alignall2([[0,0,0]], [ hd(scans) ], tl(scans))
      distances = for a <- pos, b <- pos, into: [], do: delta(a,b)
      Enum.max(distances)
    end
  end


#    def read_sensors_and_probes do
#
#      # Parse the hex string
#      System.argv()
#      |> List.last()
#      |> File.read!()
#      |> String.trim()
#      |> String.split("\n\n")
#      |> Enum.map(&parse_scanner/1)
#    end
#
#    defp parse_scanner(scan_string) do
#      [scanner | probe_data] = scan_string |> String.split("\n", trim: true)
#
#      %{
#        scanner: scanner |> String.trim("-") |> String.trim(" "),
#        probes: probe_data |> Enum.map(fn probe -> probe |> String.split(",") |> Enum.map(&String.to_integer/1) |> List.to_tuple() end),
#        kinematic: []
#      }
#    end
#
#    @doc """
#    Part 01
#
#    Files: data/test_01.dat, data/input_01.dat
#    """
#    def part_01 do
#
#      # get the original probe data
#      [scanner_0 | scanner_rest] = read_sensors_and_probes()
#
#      align_probes([scanner_0], scanner_rest)
#      |> IO.inspect(label: "aligned probes")
#      |> Enum.map(&apply_kinematics/1)
#      |> IO.inspect(label: "arranged probes")
#      |> Enum.map(fn %{probes: probes} -> probes end)
#      |> List.flatten()
#      |> Enum.uniq()
#      |> length()
#      |> IO.inspect(label: "unique probes")
#
##      # find the overlaps
##      overlaps = probe_data
##      |> IO.inspect(label: "sensors and probes")
##      |> compare_all_probes()
##      |> IO.inspect(label: "overlaps")
##
##      # what is the chain of resolutions needed
##      # to map into a continuous space. We keep
##      # this as a map starting from scanner #0,
##      # and tracing through all the resolutions
##
##      # resolution map tells us how to figure
##      # out the dependencies
##      resolution_map = overlaps
##      |> Enum.map(fn {scanner_a, scanner_b, _intersection} -> {scanner_a, scanner_b} end)
##      |> Enum.group_by(fn {a, _b} -> a end, fn {_a, b} -> b end)
##      |> IO.inspect(label: "resolution map")
##
##      # make the probe map more sane for later
##      # lookup
##      scanner_to_probe = probe_data |> Enum.map(fn %{probes: probes, scanner: scanner} -> {scanner, probes} end) |> Map.new()
##
##      # seed the initial "resolved" data
##      scanner_root_data = scanner_to_probe |> Map.get("scanner 0")
##      resolved_probe_data = %{
##        "scanner 0" => %{
##          raw: scanner_root_data,
##          resolved: scanner_root_data,
##          location: {0, 0, 0},
##          translation: {:x, :y, :z}
##        }
##      }
##
##      # make the overlap data into something a bit more sane
##      suffix_resolver = overlaps |> Enum.map(fn {root, leaf, {_translation, {offset, _map}}} -> {leaf, %{root: root, offset: offset}} end) |> Map.new()
##
##      simple_alignment(resolved_probe_data, scanner_to_probe |> Map.drop(["scanner 0"]), suffix_resolver)
#
##      # seed the mapped probes, and iterate through the probe stack
##      align_all_probes(resolution_map, overlaps, ["scanner 0"], scanner_to_probe, resolved_probe_data)
##      |> Enum.map(fn {_scanner, %{resolved: resolved_points}} -> resolved_points end)
##      |> List.flatten()
##      |> Enum.uniq()
##      |> IO.inspect(label: "fully aligned")
##      |> length()
##      |> IO.inspect(label: "total probes")
#    end
#
#    def align_probes(aligned, []), do: aligned
#    def align_probes(aligned, unaligned) do
#
#      # walk through unaligned and try to match to anything
#      # in aligned
#      realignments = unaligned
#      |> Enum.map(fn unaligned_scanner ->
#        case find_alignment(aligned, unaligned_scanner) do
#          nil -> {:unaligned, unaligned_scanner}
#          new_aligned_scanner -> {:aligned, new_aligned_scanner}
#        end
#      end)
#
#      # now add any aligned scanners to our alignment pool, unaligned
#      # keep going
#      split = realignments |> Enum.group_by(fn {state, _} -> state end, fn {_, s} -> s end)
##      |> IO.inspect(label: "realignments")
#      align_probes(aligned ++ Map.get(split, :aligned, []), Map.get(split, :unaligned, []))
#
#    end
#
#    def find_alignment(probe_list, probe_b) do
#      IO.inspect(probe_b.scanner, label: "aligning")
#      probe_list |> Enum.map(fn %{scanner: s} -> s end) |> IO.inspect(label: "with")
#      alignment = probe_list
#      |> Enum.map(fn probe_a ->
#        IO.puts(" <#{probe_a.scanner} / #{probe_b.scanner}>")
#        compare_probe_data([probe_a, probe_b])
#      end)
#      |> Enum.filter(fn {_r, _a, v} -> v != nil end)
#
#      case alignment do
#        [] ->
#          IO.puts("--- no alignment")
#          nil
#
#        [{scanner_root, scanner_aligned, {rotation, {{x_offset, y_offset, z_offset}, _matched_points} }}] ->
#          IO.puts("=== found alignment")
#
#          # what is the location of the parent in real space?
#          parent = parent_scanner(probe_list, scanner_root)
#
#          # rebuild a probe/scanner
#          %{
#            scanner: scanner_aligned,
#            probes: probe_b.probes,
#            kinematic: parent.kinematic ++ [%{rotation: rotation, offset: {x_offset, y_offset, z_offset}}]
#          }
#          |> IO.inspect(label: "aligned scanner/probes")
#      end
#    end
#
#    defp parent_scanner(probe_list, scanner) do
#      probe_list
#      |> Enum.filter(fn probe_scanner -> probe_scanner.scanner == scanner end)
#      |> List.first()
#    end
#
#
#    defp apply_kinematics(scanner) do
#      scanner |> Map.put(:probes, apply_kinematics(scanner.probes, scanner.kinematic))
#    end
#
#    defp apply_kinematics(probe_data, []), do: probe_data
#    defp apply_kinematics(probe_data, [%{offset: {x, y, z}, rotation: c_rot} | kinematics]) do
#
#      # rotate and then translate?
#      probe_data
#      |> Enum.map(fn point ->
#        # rotate
#        {nx, ny, nz} = point
#        |> apply_canonical_rotation(c_rot)
#        # translate
#        {nx + x, ny + y, nz + z}
#      end)
#
#      # translate and then rotate?
##      probe_data
##      |> Enum.map(fn {px, py, pz} ->
##        {px + x, py + y, pz + z} |> apply_canonical_rotation(c_rot)
##      end)
#      |> apply_kinematics(kinematics)
#    end
#
#
#    # rethink - just align what we can from the current aligned map (that is those
#    # that depend on zero). At each stage do a re-alignment with compare_probe_data
#    # to get a new canonical rotation. Apply rotation, translate.
#    defp simple_alignment(aligned_map, unaligned_map, suffix_resolver) do
#      IO.inspect(aligned_map, label: "aligned_map")
#      IO.inspect(unaligned_map, label: "unaligned_map")
#      IO.inspect(suffix_resolver, label: "suffix_resolver")
#
#      # who can we align?
#      unaligned_map
#      |> Map.keys()
#      |> Enum.map(fn un_key ->
#        IO.puts("  - unkey: #{un_key}")
#        suffix_resolver |> Map.get(un_key) |> Map.get(:root)
#      end)
#      |> Enum.filter(fn root_key -> Enum.member?(aligned_map, root_key) end)
#      |> IO.inspect(label: "can resolve")
#    end
#
#
#
#    defp align_all_probes(_resolution_map, _intersection_data, [], _raw_probe_data, resolved_probe_data), do: resolved_probe_data
#    defp align_all_probes(resolution_map, intersection_data, [root | resolve_stack], raw_probe_data, resolved_probe_data) do
#
#      # use the current root node and pick the next things we can resolve
#      can_resolve = resolution_map |> Map.get(root, [])
#      IO.puts("root(#{root})")
#      IO.inspect(can_resolve, label: "can resolve")
#
#      scanner_merges = can_resolve
#      |> Enum.map(fn scanner_to_resolve ->
#
#        IO.puts(" -> Resolving #{scanner_to_resolve}")
#
#        # find the 3-space rotation against our match node
#        # {root, scanner_to_resolve}
#        {{s_dx, s_dy, s_dz}, {s_x, s_y, s_z}} = translation_and_offset(intersection_data, root, scanner_to_resolve) |> IO.inspect(label: "translation and offset")
#
#        # find the root translation of the previous entry (so we know how to chain together)
#        {root_dx, root_dy, root_dz} = resolved_probe_data |> Map.get(root) |> Map.get(:translation) |> IO.inspect(label: "root translation")
#
#        # resolve our offset location (resolved data)
#        {root_x, root_y, root_z} = resolved_probe_data |> Map.get(root) |> Map.get(:location) |> IO.inspect(label: "root location")
#
#        # total translation = root location + our offset
#        total_offset_x = translate_point(root_dx, s_dx, root_x, s_x)
#        total_offset_y = translate_point(root_dy, s_dy, root_y, s_y)
#        total_offset_z = translate_point(root_dz, s_dz, root_z, s_z)
#
#        IO.puts(" == total offset (#{total_offset_x}, #{total_offset_y}, #{total_offset_z})")
#
#        # rotate and then align the nodes for these probes
#        resolved_data = raw_probe_data
#        |> Map.get(scanner_to_resolve)
#        |> Enum.map(fn probe ->
#          {rx, ry, rz} = apply_canonical_rotation(probe, {s_dx, s_dy, s_dz})
#          {rx + total_offset_x, ry + total_offset_y, rz + total_offset_z}
#        end)
#
#        IO.puts(" !! completed rotation")
#        # create a resolved entry
#        {
#          scanner_to_resolve,
#          %{
#            raw: raw_probe_data
#                 |> Map.get(scanner_to_resolve),
#            resolved: resolved_data,
#            location: {total_offset_x, total_offset_y, total_offset_z},
#            translation: {s_dx, s_dy, s_dz}
#          }
#        }
#      end)
#      |> Map.new()
#
#      # push into resolved data
#      resolved_probe_data = resolved_probe_data |> Map.merge(scanner_merges)
#
#      # add these probes the resolve stack
#      new_stack = resolve_stack ++ can_resolve
#      IO.inspect(new_stack, label: "next stack")
#
#      align_all_probes(resolution_map, intersection_data, new_stack, raw_probe_data, resolved_probe_data)
#    end
#
#    defp translate_point(root_d, point_d, root_v, point_v) do
#      # + / + == add
#      # everything else is subtract
#      cond do
#        Atom.to_string(root_d) |> String.starts_with?("n") -> root_v - point_v
#        Atom.to_string(point_d) |> String.starts_with?("n") -> root_v - point_v
#        true -> root_v + point_v
#      end
#
#    end
#
#    defp translation_and_offset(intersection_data, root, scanner) do
#
#      intersection_data
#      |> Enum.filter(fn {a, b, _overlap} -> (a == root) and (b == scanner) end)
#      |> Enum.map(fn {_a, _b, {translation, {offset, _intersections}}} -> {translation, offset} end)
#      |> List.first()
#    end
#
#    defp compare_all_probes(probes) do
#      probes
#      |> combinations_calc(2)
#      |> Enum.map(&compare_probe_data/1)
#      |> Enum.filter(fn {_scanner_a, _scanner_b, res} -> res != nil end)
#    end
#
#    defp combinations_calc(_, 0), do: [[]]
#    defp combinations_calc([], k) when is_integer(k), do: []
#
#    defp combinations_calc([head | tail], k) when is_integer(k) do
#      Enum.map(
#        combinations_calc(tail, k - 1),
#        fn r_comb ->
#          [head | r_comb]
#        end
#      ) ++ combinations_calc(tail, k)
#    end
#
#    defp compare_probe_data([sensor_a, sensor_b]) do
#
#      comp_res = sensor_b.probes
#      |> rotate_probes()
#      |> Enum.map(fn {rot, rotated_probes} ->
#
#        # drop to the direct comparison first
#        {rot, match_probes(sensor_a.probes, rotated_probes)}
#
#      end)
#      # matches is {sensor_b_translation, sensor intersection}
#      |> Enum.filter(fn {_rot, matches} -> matches != nil end)
#      |> List.first()
#
#      {sensor_a.scanner, sensor_b.scanner, comp_res}
#
#    end
#
#    # given a set of already rotated positions, does
#    # this pair of probes have any overlap.
#    defp match_probes(probes_a, probes_b) do
#
#      # pairwise select coordinates from a and b
#      coordinate_pairs(probes_a, probes_b)
#      |> Enum.map(fn {probe_a, probe_b} ->
#
#        # what translation would be required to map
#        # b to a
#        translation = translation_from(probe_a, probe_b)
#
#        # apply translation to all of b
#        probe_b_set = probes_b |> translate_all(translation) |> MapSet.new()
#        probe_a_set = probes_a |> MapSet.new()
#
#        # set intersection
#        {translation, MapSet.intersection(probe_a_set, probe_b_set)}
#
#      end)
#
#      |> Enum.filter(fn {_translation, intersection} -> MapSet.size(intersection) >= 12 end)
#      |> List.first()
#
#    end
#
#    defp translate_all(points, {t_x, t_y, t_z}) do
#      points
#      |> Enum.map(fn {p_x, p_y, p_z} -> {p_x + t_x, p_y + t_y, p_z + t_z} end)
#    end
#
#    defp translation_from({p_a_x, p_a_y, p_a_z}, {p_b_x, p_b_y, p_b_z}) do
#      {p_a_x - p_b_x, p_a_y - p_b_y, p_a_z - p_b_z}
#    end
#
#    defp coordinate_pairs(probes_a, probes_b) do
#
#      probes_a
#      |> Enum.map(fn probe_a ->
#        probes_b
#        |> Enum.map(fn probe_b ->
#          {probe_a, probe_b}
#        end)
#      end)
#
#      |> List.flatten()
#    end
#
#    defp rotate_probes(probes) do
#      canonical_rotations()
#      |> Enum.map(fn rot ->
#
#        r_probes = probes
#        |> Enum.map(fn probe ->
#          probe |> apply_canonical_rotation(rot)
#        end)
#
#        {rot, r_probes}
#      end)
#    end
#
##    defp rotate_probes(probes) do
##      alterations()
##      |> Enum.map(fn {rot, fac} ->
##
##        r_probes = probes
##        |> Enum.map(fn probe ->
##          probe |> facing(fac) |> rotate(rot)
##        end)
##
##        {{rot, fac}, r_probes}
##      end)
##    end
#
##    defp alterations do
##      rotations()
##      |> Enum.map(fn i_rotation ->
##        facings()
##        |> Enum.map(fn i_facing ->
##          {i_rotation, i_facing}
##        end)
##      end)
##      |> List.flatten()
##    end
#
##    defp rotations, do: [{:x, :y, :z}, {:z, :x, :y}, {:y, :z, :x}]
##    defp rotate({x, y, z}=_probe, {:x, :y, :z}), do: {x, y, z}
##    defp rotate({x, y, z}=_probe, {:z, :x, :y}), do: {z, x, y}
##    defp rotate({x, y, z}=_probe, {:y, :z, :x}), do: {y, z, x}
##
##    defp facings do
##      [
##        {:px, :py, :pz},
##        {:px, :ny, :pz},
##        {:px, :py, :nz},
##        {:px, :ny, :nz},
##        {:nx, :py, :pz},
##        {:nx, :ny, :pz},
##        {:nx, :py, :nz},
##        {:nx, :ny, :nz},
##      ]
##    end
##    defp facing({x, y, z}=_probe, {:px, :py, :pz}), do: {x     , y     , z     }
##    defp facing({x, y, z}=_probe, {:px, :ny, :pz}), do: {x     , y * -1, z     }
##    defp facing({x, y, z}=_probe, {:px, :py, :nz}), do: {x     , y     , z * -1}
##    defp facing({x, y, z}=_probe, {:px, :ny, :nz}), do: {x     , y * -1, z * -1}
##    defp facing({x, y, z}=_probe, {:nx, :py, :pz}), do: {x * -1, y     , z     }
##    defp facing({x, y, z}=_probe, {:nx, :ny, :pz}), do: {x * -1, y * -1, z     }
##    defp facing({x, y, z}=_probe, {:nx, :py, :nz}), do: {x * -1, y     , z * -1}
##    defp facing({x, y, z}=_probe, {:nx, :ny, :nz}), do: {x * -1, y * -1, z * -1}
#
#    defp canonical_rotations do
#      [
#        # +x +y +z
#        {:x, :y, :z},
#
#        # +x -z +y
#        {:x, :nz, :y},
#
#        # +x -y -z
#        {:x, :ny, :nz},
#
#        # +x +z -y
#        {:x, :z, :ny},
#
#        # -x -y +z
#        {:nx, :ny, :z},
#
#        # -x +z +y
#        {:nx, :z, :y},
#
#        # -x +y -z
#        {:nx, :y, :nz},
#
#        # -x -z -y
#        {:nx, :nz, :ny},
#
#        # +y +z +x
#        {:y, :z, :x},
#
#        # +y -x +z
#        {:y, :nx, :z},
#
#        # +y -z -x
#        {:y, :nz, :nx},
#
#        # +y +x -z
#        {:y, :x, :nz},
#
#        # -y -z +x
#        {:ny, :nz, :x},
#
#        # -y +x +z
#        {:ny, :x, :z},
#
#        # -y +z -x
#        {:ny, :z, :nx},
#
#        # -y -x -z
#        {:ny, :nx, :nz},
#
#        # +z +x +y
#        {:z, :x, :y},
#
#        # +z -y +x
#        {:z, :ny, :x},
#
#        # +z -x -y
#        {:z, :nx, :ny},
#
#        # +z +y -x
#        {:z, :y, :nx},
#
#        # -z -x +y
#        {:nz, :nx, :y},
#
#        # -z +y +x
#        {:nz, :y, :x},
#
#        # -z +x -y
#        {:nz, :x, :ny},
#
#        # -z -y -x
#        {:nz, :ny, :nx}
#      ]
#
#    end
#
#    defp apply_canonical_rotation(point, {ta, tb, tc}) do
#      {
#        select_canonical(point, ta),
#        select_canonical(point, tb),
#        select_canonical(point, tc)
#      }
#    end
#
#    defp select_canonical({x, y, z}, canon) do
#      case canon do
#        :x -> x
#        :nx -> x * -1
#        :y -> y
#        :ny -> y * -1
#        :z -> z
#        :nz -> z * -1
#      end
#    end
#
##    defp canonical_rotations({x, y, z}) do
##
##      nx = x * -1
##      ny = y * -1
##      nz = z * -1
##      [
##        # +x +y +z
##        {x, y, z},
##
##        # +x -z +y
##        {x, nz, y},
##
##        # +x -y -z
##        {x, ny, nz},
##
##        # +x +z -y
##        {x, z, ny},
##
##        # -x -y +z
##        {nx, ny, z},
##
##        # -x +z +y
##        {nx, z, y},
##
##        # -x +y -z
##        {nx, y, nz},
##
##        # -x -z -y
##        {nx, nz, ny},
##
##        # +y +z +x
##        {y, z, x},
##
##        # +y -x +z
##        {y, nx, z},
##
##        # +y -z -x
##        {y, nz, nx},
##
##        # +y +x -z
##        {y, x, nz},
##
##        # -y -z +x
##        {ny, nz, x},
##
##        # -y +x +z
##        {ny, x, z},
##
##        # -y +z -x
##        {ny, z, nx},
##
##        # -y -x -z
##        {ny, nx, nz},
##
##        # +z +x +y
##        {z, x, y},
##
##        # +z -y +x
##        {z, ny, x},
##
##        # +z -x -y
##        {z, nx, ny},
##
##        # +z +y -x
##        {z, y, nx},
##
##        # -z -x +y
##        {nz, nx, y},
##
##        # -z +y +x
##        {nz, y, x},
##
##        # -z +x -y
##        {nz, x, ny},
##
##        # -z -y -x
##        {nz, ny, nx}
##      ]
##    end
#
#    @doc """
#    Part 02
#
#    Files: data/test_01.dat, data/input_01.dat
#    """
#    def part_02 do
#
#
#    end

end
