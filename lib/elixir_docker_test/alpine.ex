defmodule Alpine.Service do
  use GenServer, restart: :transient
  require Logger

  @mod __MODULE__
  @defaults %{
    container_name: "alpine",
    image_name: "alpine",
    shell: "/bin/sh"
  }

  @spec start_link(maybe_improper_list) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(@mod, @defaults, name: {:global, @mod})
  end

  def cmd(args) when is_list(args) do
    GenServer.call({:global, @mod}, {:cmd, args})
  end

  def cmd(cmd) when is_binary(cmd) do
    GenServer.call({:global, @mod}, {:cmd, [cmd]})
  end

  # Callbacks

  @impl true
  def init(opts) do
    # Process.flag(:trap_exit, true)
    start(opts)
  end

  @impl true
  def terminate(_reason, _state = %{config: opts}) do
    # Do Shutdown Stuff
    Logger.info("Stopped: #{inspect(stop(opts.container_name))}")
    :normal
  end

  @impl true
  def handle_call({:cmd, args}, _from, state = %{config: opts}) do
    case exec_cmd(opts.container_name, args) do
      {stdio, 0} ->
        {:reply, {:ok, stdio}, state}

      {stdio, code} ->
        {:stop, :error, {:error, stdio, code}, state}
    end
  end

  def start(opts) do
    case run(opts.image_name, opts.container_name, opts.shell) do
      {_stdio, 125} ->
        # already running
        # Logger.info("already running")
        {:ok, %{config: opts}}

      {stdio, 0} ->
        # started
        Logger.info("started: #{stdio}")
        {:ok, %{config: opts}}

      {stdio, code} ->
        # other
        {:error, "Some error occurred: #{inspect(stdio)} code: #{code}"}
    end
  end

  defp exec_cmd(container_name, args) do
    args = ["exec", container_name] ++ args

    System.cmd(
      "docker",
      args,
      stderr_to_stdout: true
    )
  end

  defp run(image, container_name, shell \\ "/bin/sh") do
    System.cmd(
      "docker",
      ["run", "--init", "-d", "-t", "--rm", "--name", container_name, image, shell],
      stderr_to_stdout: true
    )
  end

  defp stop(container_name) do
    case System.cmd(
           "docker",
           ["rm", "-f", container_name],
           stderr_to_stdout: true
         ) do
      {stdio, 0} -> {:ok, stdio}
      {stdio, code} -> {:error, stdio, code}
    end
  end
end
