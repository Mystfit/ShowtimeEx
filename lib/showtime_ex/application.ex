defmodule ShowtimeEx.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @impl true
  def start(_type, _args) do
    # import Supervisor.Spec

    children = [
      {ShowtimeEx.Bridge, []},
    ]

    opts = [strategy: :one_for_one, name: ShowtimeEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
