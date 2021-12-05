defmodule AOC.MixProject do
  use Mix.Project

  def project do
    [
      app: :day01,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
  
  defp aliases do
     [
         part_01: ["run -e 'AOC.part_01()'"],
         part_02: ["run -e 'AOC.part_02()'"]
     ] 
  end
end
