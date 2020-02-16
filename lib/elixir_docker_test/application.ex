defmodule ElixirDockerTest.Application do
  use Application

  def start(_type, _args) do
    children = [
      Alpine.Service
    ]

    opts = [strategy: :one_for_one, name: ElixirDockerTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
