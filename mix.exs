defmodule ShowtimeEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :showtime_ex,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ShowtimeEx.Application, []},
      extra_applications: [:logger, :event_bus]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:eflatbuffers, git: "https://github.com/mystfit/eflatbuffers", branch: "comments"},
      {:websockex, "~> 0.4.2"},
      {:event_bus, "~> 1.6.1"},
      {:uuid, "~> 1.1"}
    ]
  end
end
