defmodule ShowtimeEx.Message do
  require Logger

  def load_schema(schema_files) do
    schema =
      Stream.map(schema_files, fn file -> File.read!(Path.expand(file)) end)
      |> Enum.to_list()
      |> Enum.join()
      |> Eflatbuffers.Schema.parse!()
    {:ok, schema}
  end

  def format({:SignalMessage, signal}) when is_atom(signal) do
    %{signal: Atom.to_string(signal)}
  end

  def format({:ClientJoinRequest, %{name: name}}) do
    %{
      performer: %{
        entity: %{
          URI: name
        }
      }
    }
  end

  def format({:ClientLeaveRequest, %{performer_path: performer_path, reason: reason}}) do
    %{
      performer_URI: performer_path,
      reason: reason
    }
  end

  def envelope(content, type) when is_atom(type) and is_map(content) do
    %{
      content: content,
      content_type: Atom.to_string(type),
      id: 0
    }
  end
end
