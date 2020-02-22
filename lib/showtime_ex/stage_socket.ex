defmodule ShowtimeEx.StageSocket do
  use WebSockex
  use EventBus.EventSource
  alias EventBus.EventSource, as: EventSource

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  def handle_connect(_conn, state) do
    {:ok, state}
  end

  def handle_frame({:binary, msg}, state) do
    params = %{topic: :stage_msg_recv}
    EventSource.notify(params) do 
      %{msg_binary: msg}
    end
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    {:reply, frame, state}
  end
end
