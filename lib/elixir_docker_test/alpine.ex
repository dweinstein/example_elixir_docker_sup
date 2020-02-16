defmodule Alpine.Service do
  @name "alpine"
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:global, :alpine})
  end

  def cmd(args \\ []) do
    GenServer.call({:global, :alpine}, {:cmd, args})
  end

  # Callbacks

  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)
    start()
  end

  @impl true
  def terminate(reason, state) do
    # Do Shutdown Stuff
    Logger.info("Stopped: #{inspect(stop())}")
    :normal
  end

  @impl true
  def handle_call({:cmd, args}, _from, state) do
    case exec_cmd(args) do
      {stdio, 0} ->
        {:reply, {:ok, stdio}, state}

      {stdio, code} ->
        {:stop, :normal, {:error, stdio, code}, state}
    end
  end

  def start do
    case run() do
      {_stdio, 125} ->
        # already running
        # Logger.info("already running")
        {:ok, %{}}

      {stdio, 0} ->
        # started
        Logger.info("started: #{stdio}")
        {:ok, %{}}

      {stdio, code} ->
        # other
        {:error, "Some error occurred: #{inspect(stdio)} code: #{code}"}
    end
  end

  def exec_cmd(args) do
    args = ["exec", @name] ++ args

    System.cmd(
      "docker",
      args,
      stderr_to_stdout: true
    )
  end

  def run do
    System.cmd(
      "docker",
      ["run", "--init", "-d", "-t", "--rm", "--name", @name, "alpine", "/bin/sh"],
      stderr_to_stdout: true
    )
  end

  def stop do
    case System.cmd(
           "docker",
           ["rm", "-f", "alpine"],
           stderr_to_stdout: true
         ) do
      {stdio, 0} -> {:ok, stdio}
      {stdio, code} -> {:error, stdio, code}
    end
  end
end
