defmodule ShowtimeEx.MessageSchema do
  use GenServer

  def init(schema_files) do
    Process.send_after(self(), {:load_schema, schema_files}, 0)
    {:ok, nil}
  end

  def start_link(schema_files) do
    GenServer.start_link(__MODULE__, schema_files, name: __MODULE__)
  end

  def encode(message) do
    GenServer.call(__MODULE__, {:encode, message})
  end

  def decode(message) do
    GenServer.call(__MODULE__, {:decode, message})
  end

  def schema() do
    GenServer.call(__MODULE__, :schema)
  end

  # ---------

  def handle_info({:load_schema, schema_files}, _state) do
    schema =
      Stream.map(schema_files, fn file -> File.read!(Path.expand(file)) end)
      |> Enum.to_list()
      |> Enum.join()
      |> Eflatbuffers.Schema.parse!()
    {:noreply, %{schema: schema}}
  end

  def handle_call({:encode, message}, _from, state) do
    {:reply, Eflatbuffers.write!(message, state[:schema]), state}
  end

  def handle_call({:decode, message}, _from, state) do
    {:reply, Eflatbuffers.read!(message, state[:schema]), state}
  end

  def handle_call(:schema, _from, state) do
    {:reply, state[:schema], state}
  end
end
