defmodule ShowtimeEx.BridgeSocket do
  use WebSockex
  alias EventBus.Model.Event

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  def handle_connect(_conn, state) do
    {:ok, state}
  end

  def handle_frame({:binary, msg}, state) do
    ShowtimeEx.Bridge.recv(msg)
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    {:reply, frame, state}
  end
end
