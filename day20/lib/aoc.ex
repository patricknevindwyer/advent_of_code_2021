defmodule AOC do
  alias ExGrids.Grid2D

  def read_image_and_algorithm do
    # Parse the hex string
    [algo, image] =
      System.argv()
      |> List.last()
      |> File.read!()
      |> String.trim()
      |> String.split("\n\n")

    %{
      algorithm: algo |> String.split("", trim: true),
      image:
        Grid2D.Create.from_string(String.trim(image), :character_cells)
    }
  end

  @doc """
  Part 01

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_01 do
    %{algorithm: algo, image: image} = read_image_and_algorithm()

    # let's start processing
    image
    |> enhance_image(algo, 2)
    |> Grid2D.Display.display(:character_cells)
    |> Grid2D.Enum.coordinates_and_values()
    |> Enum.filter(fn {_c, v} -> v == "#" end)
    |> length()
    |> IO.inspect(label: "active cells")
  end

  def enhance_image(image, _algo, 0), do: image

  def enhance_image(image, algo, count) do

    # what is our edge/outer space pixel?
    edge = if rem(count, 2) == 1 do
      "#"
    else
      "."
    end

    # enhance
    image
    |> Grid2D.Mutate.grow(1, edge)
    |> Grid2D.Enum.update(fn og_image, coord, _old_value ->
      neighborbood =
        og_image
        |> Grid2D.Enum.neighborhood_values(coord, edge)

        # get our neighborhood
        enhance_offset =
          neighborbood
          # translate to binary
          |> Enum.map(fn c ->
            if c == "#" do
              1
            else
              0
            end
          end)

          # convert to number
          |> Integer.undigits(2)

        # new value
        algo |> Enum.at(enhance_offset)
    end)
    |> enhance_image(algo, count - 1)
  end

  @doc """
  Part 02

  Files: data/test_01.dat, data/input_01.dat
  """
  def part_02 do
    %{algorithm: algo, image: image} = read_image_and_algorithm()

    # let's start processing
    image
    |> enhance_image(algo, 50)
    |> Grid2D.Display.display(:character_cells)
    |> Grid2D.Enum.coordinates_and_values()
    |> Enum.filter(fn {_c, v} -> v == "#" end)
    |> length()
    |> IO.inspect(label: "active cells")

  end
end
