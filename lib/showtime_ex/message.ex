defmodule ShowtimeEx.Message do
  def load_schema(schema_files) do
    schema =
      Stream.map(schema_files, fn file -> File.read!(Path.expand(file)) end)
      |> Enum.to_list()
      |> Enum.join()
      |> Eflatbuffers.Schema.parse!()

    {:ok, schema}
  end

  def format({:SignalMessage = type, signal}) when is_atom(signal) do
    envelope(type)
    |> body(%{signal: Atom.to_string(signal)})
  end

  def format({:ClientJoinRequest = type, %{address: _address, name: name}}) do
    envelope(type)
    |> body(%{
      performer: %{
        entity: %{
          URI: name
        }
      }
    })
  end

  def format({:ClientLeaveRequest = type, %{performer_path: performer_path, reason: reason}}) do
    envelope(type)
    |> body(%{
      performer_URI: performer_path,
      reason: reason
    })
  end

  def envelope(type) do
    %{
      content_type: Atom.to_string(type),
      id: 0
    }
  end

  def body(msg, body) do
    Map.put(msg, :content, body)
  end
end
