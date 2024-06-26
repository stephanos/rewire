defmodule Rewire.MixProject do
  use Mix.Project

  def project do
    [
      app: :rewire,
      version: "0.9.2",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/stephanos/rewire",
      test_coverage: [tool: Rewire.TestCover]
    ]
  end

  defp description() do
    "Dependency injection for Elixir. Zero code changes required."
  end

  def application do
    [
      extra_applications: [:logger, :tools],
      mod: {Rewire.Setup, []}
    ]
  end

  defp deps do
    [
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "fixtures/"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      licenses: ["Apache-2.0"],
      files: ~w(lib mix.exs README* LICENSE* CHANGELOG*),
      links: %{"GitHub" => "https://github.com/stephanos/rewire"}
    ]
  end
end
