defmodule ShowtimeEx.Bridge do
  @hb_DURATION 1000

  use GenServer
  require Logger
  alias ShowtimeEx.Message, as: Message

  def init(_state) do
    EventBus.subscribe({__MODULE__, ["stage_msg_recv$"]})

    {:ok,
     %{
       stage_socket: nil,
       schema: nil
      }, {:continue, :load_schemas}
    }
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def join(address, name) do
    GenServer.cast(__MODULE__, {:send, {:ClientJoinRequest, %{address: address, name: name}}})
  end

  def leave(performer_path, reason = "QUIT") do
    GenServer.cast(
      __MODULE__,
      {:send, :ClientLeaveRequest, %{performer_path: performer_path, reason: reason}}
    )
  end

  def add(entity) do
    GenServer.cast(__MODULE__, {:send, {:EntityCreateRequest, %{entity: entity}}})
  end

  def remove(entity_path) do
    GenServer.cast(__MODULE__, {:send, {:EntityDestroyRequest, %{entity_path: entity_path}}})
  end

  def process({topic, id} = event_shadow) do
    GenServer.cast(__MODULE__, event_shadow)
    :ok
  end

  # ----------------------------

  def handle_continue(:load_schemas, state) do
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

  def handle_cast({:send, {:ClientJoinRequest, %{address: address, name: name}} = request}, state) do
    state = ensure_socket_connected(address, state)

    {:ok, result} =
      encode(request, state[:schema])
      |> sock_send(state[:stage_socket])

    {:noreply, state}
  end

  def handle_cast({:send, {content_type, content} = request}, state) when is_atom(content_type) do
    {:ok, result} =
      encode(request, state[:schema])
      |> sock_send(state[:stage_socket])

    {:noreply, state}
  end

  def handle_cast({:stage_msg_recv, id} = event_shadow, state) do
    message = EventBus.fetch_event(event_shadow)
    |> get_in([Access.key(:data), :msg_binary])
    |> Eflatbuffers.read!(state[:schema])
    # |> IO.inspect()

    EventBus.mark_as_completed({__MODULE__, event_shadow})
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
