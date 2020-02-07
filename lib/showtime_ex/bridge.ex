defmodule ShowtimeEx.Bridge do
  @hb_DURATION 1000

  use GenServer
  require Logger
  alias ShowtimeEx.Message, as: Message

  def init(_state) do
    Process.send_after(self(), :load_schemas, 0)

    {:ok,
     %{
       stage_socket: nil,
       schema: nil
     }}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def join(address, name) do
    GenServer.cast(__MODULE__, {:ClientJoinRequest, %{address: address, name: name}})
  end

  def leave(performer_path, reason = "QUIT") do
    GenServer.cast(
      __MODULE__,
      {:ClientLeaveRequest, %{performer_path: performer_path, reason: reason}}
    )
  end

  def add(entity) do
    GenServer.cast(__MODULE__, {:EntityCreateRequest, %{entity: entity}})
  end

  def remove(entity_path) do
    GenServer.cast(__MODULE__, {:EntityDestroyRequest, %{entity_path: entity_path}})
  end

  def sock_receive(msg) do
    GenServer.cast(__MODULE__, {:sock_receive, msg})
  end

  # ----------------------------

  def handle_info(:load_schemas, state) do
    {:ok, schema} =
      Application.fetch_env!(:showtime_ex, :stage_schema_files)
      |> Message.load_schema()

    {:noreply, Map.put(state, :schema, schema)}
  end

  def handle_info({:heartbeat}, state) do
    {:ok, result} =
      encode({:SignalMessage, :CLIENT_HEARTBEAT}, state[:schema])
      |> sock_send(state[:stage_socket])

    send_heartbeat(@hb_DURATION)
    {:noreply, state}
  end

  def handle_cast({:sock_receive, msg}, state) do
    Eflatbuffers.read!(msg, state[:schema])
    |> IO.inspect()

    {:noreply, state}
  end

  def handle_cast({:ClientJoinRequest, %{address: address, name: name}} = request, state) do
    state = ensure_socket_connected(address, state)

    {:ok, result} =
      encode(request, state[:schema])
      |> sock_send(state[:stage_socket])

    {:noreply, state}
  end

  def handle_cast({content_type, content} = request, state) when is_atom(content_type) do
    {:ok, result} =
      encode(request, state[:schema])
      |> sock_send(state[:stage_socket])

    {:noreply, state}
  end

  def ensure_socket_connected(address, %{stage_socket: nil} = state) do
    {:ok, socket_pid} = connect(address)
    send_heartbeat(@hb_DURATION)
    Map.put(state, :stage_socket, socket_pid)
  end

  def ensure_socket_connected(_address, state), do: state

  def connect(address) do
    case ShowtimeEx.StageSocket.start_link(address) do
      {:ok, socket_pid} ->
        Logger.info("Connected to #{address}")
        {:ok, socket_pid}

      {:error, sock_err} ->
        Logger.error("Could not connect to #{address}")
        {:error, sock_err}
    end
  end

  def send_heartbeat(duration) do
    Process.send_after(self(), {:heartbeat}, duration)
  end

  def encode({content_type, content} = request, schema) do
    Message.format(request)
    |> Message.envelope(content_type)
    |> Eflatbuffers.write!(schema)
  end

  def sock_send(msg, socket) do
    case WebSockex.send_frame(socket, {:binary, msg}) do
      :ok ->
        {:ok, :success}

      {:error, sock_err} ->
        Logger.error("Could not send message: #{sock_err}")
        {:error, sock_err}
    end
  end
end
