defmodule AOC do

    def read_bits do

      # Parse the hex string
      System.argv()
      |> List.last()
      |> File.read!()
      |> String.trim()
      |> decode_bits_hex()
    end

    defp decode_bits_hex(str) do
      str
      |> String.split("", trim: true)
      |> Enum.map(&bits_hex/1)
      |> List.flatten()
    end

    defp bits_hex(c) do
      case c do
        "0" -> [0,0,0,0]
        "1" -> [0,0,0,1]
        "2" -> [0,0,1,0]
        "3" -> [0,0,1,1]
        "4" -> [0,1,0,0]
        "5" -> [0,1,0,1]
        "6" -> [0,1,1,0]
        "7" -> [0,1,1,1]
        "8" -> [1,0,0,0]
        "9" -> [1,0,0,1]
        "A" -> [1,0,1,0]
        "B" -> [1,0,1,1]
        "C" -> [1,1,0,0]
        "D" -> [1,1,0,1]
        "E" -> [1,1,1,0]
        "F" -> [1,1,1,1]
      end
    end

    @doc """
    Part 01
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_01 do

      read_bits()
      |> IO.inspect(label: "raw BITS")
      |> decode()
      |> IO.inspect(label: "decoded")
      |> version_sum()
      |> IO.inspect(label: "version sum")
    end

    def decode(stream, opts \\ [])

    # literal
    def decode([v_1, v_2, v_3, 1, 0, 0 | stream], opts) do
      IO.puts("literal")
      {tail_stream, literal} = decode_stream_literal([], stream)

      if Keyword.get(opts, :recurse, true) do
        # list of packets
        [{:literal, %{version: [v_1, v_2, v_3] |> Integer.undigits(2), value: literal |> Integer.undigits(2)}}] ++ decode(tail_stream)
      else
        # tuple of tail stream and packet
        {tail_stream, {:literal, %{version: [v_1, v_2, v_3] |> Integer.undigits(2), value: literal |> Integer.undigits(2)}}}
      end
    end

    # operator - payload length
    def decode([v_1, v_2, v_3, op_1, op_2, op_3, 0 | stream], opts) do
      IO.puts("operator - length")
      # extract the packet data to parse, with an updated stream
      {tail_stream, _sub_packet_count, operator_data} = extract_operator_by_length(stream)

      if Keyword.get(opts, :recurse, true) do
        # list of packets
        [{:operator, %{version: [v_1, v_2, v_3] |> Integer.undigits(2), operator: [op_1, op_2, op_3] |> Integer.undigits(2), values: decode(operator_data)}}] ++ decode(tail_stream)
      else
        # tuple of tail stream and packet
        {tail_stream, {:operator, %{version: [v_1, v_2, v_3] |> Integer.undigits(2), operator: [op_1, op_2, op_3] |> Integer.undigits(2), values: decode(operator_data)}}}
      end

    end

    # operator - packet count
    def decode([v_1, v_2, v_3, op_1, op_2, op_3, 1 | stream], opts) do

      # break down our stream
      {tail_stream, packets} = extract_operator_by_packet_count(stream)

      if Keyword.get(opts, :recurse, true) do
        [{:operator, %{version: [v_1, v_2, v_3] |> Integer.undigits(2), operator: [op_1, op_2, op_3] |> Integer.undigits(2), values: packets}}] ++ decode(tail_stream)
      else
        {tail_stream, {:operator, %{version: [v_1, v_2, v_3] |> Integer.undigits(2), operator: [op_1, op_2, op_3] |> Integer.undigits(2), values: packets}}}
      end

    end

    # eat any tail we don't decode
    def decode(_stream, _opts), do: []

    # parse a literal entry
    defp decode_stream_literal(carry_digits, [1, b_1, b_2, b_3, b_4 | stream]) do
      decode_stream_literal(carry_digits ++ [b_1, b_2, b_3, b_4], stream)
    end
    defp decode_stream_literal(carry_digits, [0, b_1, b_2, b_3, b_4 | stream]) do
      {stream, carry_digits ++ [b_1, b_2, b_3, b_4]}
    end

    # extract length delimited packet data
    defp extract_operator_by_length(stream) do

      # take our header
      l = stream |> Enum.take(15) |> Integer.undigits(2)
      stream = stream |> Enum.drop(15)

      # now we can take our data to pass back, and an updated stream
      {stream |> Enum.drop(l), l, stream |> Enum.take(l)}
    end

    defp extract_operator_by_packet_count(stream) do

      # take our header
      l = stream |> Enum.take(11) |> Integer.undigits(2)
      stream = stream |> Enum.drop(11)

      # now read packets
      take_packets([], stream, l)

    end

    # extract packets
    defp take_packets(packet_carry, stream, 0) do
      {stream, packet_carry}
    end
    defp take_packets(packet_carry, stream, count) do

      # take a packet
      {tail_stream, packet} = decode(stream, recurse: false)
      take_packets(packet_carry ++ [packet], tail_stream, count - 1)
    end

    defp version_sum(packet_list) do
      packet_list
      |> Enum.map(fn {packet_type, payload} ->
        if packet_type == :literal do
          payload.version
        else
          payload.version + (payload.values |> version_sum())
        end
      end)
      |> List.flatten()
      |> Enum.sum()
    end

    @doc """
    Part 02
    
    Files: data/test_01.dat, data/input_01.dat
    """
    def part_02 do
      read_bits()
      |> IO.inspect(label: "raw BITS")
      |> decode()
      |> IO.inspect(label: "decoded")
      |> List.first()
      |> evaluate()
      |> IO.inspect(label: "eval")

    end

    # summation
    defp evaluate({:operator, %{operator: 0, values: packets}}) do
      packets
      |> Enum.map(&evaluate/1)
      |> Enum.sum()
    end

    # product
    defp evaluate({:operator, %{operator: 1, values: packets}}) do
      packets
      |> Enum.map(&evaluate/1)
      |> Enum.reduce(1, fn v, acc -> v * acc end)
    end

    # minimum
    defp evaluate({:operator, %{operator: 2, values: packets}}) do
      packets
      |> Enum.map(&evaluate/1)
      |> Enum.min()
    end

    # maximum
    defp evaluate({:operator, %{operator: 3, values: packets}}) do
      packets
      |> Enum.map(&evaluate/1)
      |> Enum.max()
    end

    # >
    defp evaluate({:operator, %{operator: 5, values: packets}}) do
      [a, b] = packets
      |> Enum.map(&evaluate/1)

      if a > b do
        1
      else
        0
      end
    end

    # <
    defp evaluate({:operator, %{operator: 6, values: packets}}) do
      [a, b] = packets
      |> Enum.map(&evaluate/1)

      if a < b do
        1
      else
        0
      end
    end

    # =
    defp evaluate({:operator, %{operator: 7, values: packets}}) do
      [a, b] = packets
      |> Enum.map(&evaluate/1)

      if a == b do
        1
      else
        0
      end
    end

    defp evaluate({:literal, %{value: v}}), do: v

end
