import Config

common_schema_files = ["priv/schemas/messaging/graph_types.fbs"]

config :showtime_ex,
  stage_schema_files: common_schema_files ++ ["priv/schemas/messaging/stage_message.fbs"],
  graph_schema_files: common_schema_files ++ ["priv/schemas/messaging/graph_message.fbs"]

config :event_bus,
  topics: [
    :stage_msg_recv,
    :another_event_occurred
  ]

# import_config "#{Mix.env()}.exs"
