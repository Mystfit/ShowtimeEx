defmodule ShowtimeEx.Bridge do
  use GenServer

  def init(state) do
    {:ok, schema_pid} =
      ShowtimeEx.MessageSchema.start_link(
        Application.fetch_env!(:showtime_ex, :stage_schema_files)
      )

    {:ok,
     %{
       schema: schema_pid,
       socket: nil
     }}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def join(address, name) do
    GenServer.cast(__MODULE__, {"ClientJoinRequest", %{name: name, address: address}})
  end

  def leave(performer, reason = "QUIT") do
    GenServer.cast(__MODULE__, {"ClientLeaveRequest", %{performer: performer, reason: reason}})
  end

  def recv(msg) do
    GenServer.cast(__MODULE__, {"recv", msg})
  end

  # ----------------------------
  def handle_cast({"recv", msg}, state) do
    Eflatbuffers.read(msg, ShowtimeEx.MessageSchema.schema())
    |> IO.inspect()
    {:noreply, state}
  end

  def handle_cast({"ClientJoinRequest", %{address: address, name: name}}, state) do
    state = ensure_socket_connected(address, state)

    msg = %{
      content_type: "ClientJoinRequest",
      content: %{
        performer: %{
          entity: %{
            URI: name
          }
        }
      }
    }

    send(state[:socket], msg, state[:schema])
    {:noreply, state}
  end

  def handle_cast({"ClientLeaveRequest", %{performer: performer, reason: reason}}, state) do
    msg = %{
      content_type: "ClientLeaveRequest",
      content: %{
        performer_URI: performer,
        reason: reason
      }
    }

    send(state[:socket], msg, state[:schema])
    {:noreply, state}
  end

  def handle_info(:heartbeat, state) do
    msg = %{
      content_type: "SignalMessage",
      content: %{
        signal: "CLIENT_HEARTBEAT"
      }
    }

    send(state[:socket], msg, state[:schema])

    Process.send_after(self(), :heartbeat, 1000)
    {:noreply, state}
  end

  def ensure_socket_connected(address, %{socket: nil} = state) do
    Map.put(state, :socket, connect(address))
  end

  def connect(address) do
    {:ok, socket_pid} = ShowtimeEx.BridgeSocket.start_link(address)
    Process.send_after(self(), :heartbeat, 1000)
    socket_pid
  end

  def ensure_socket_connected(address, state), do: state

  def send(socket, content, schema) do
    WebSockex.send_frame(
      socket,
      {:binary, ShowtimeEx.MessageSchema.encode(Map.merge(%{id: 0}, content))}
    )
  end
end
