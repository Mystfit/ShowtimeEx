import Config

common_schema_files = ["priv/schemas/messaging/graph_types.fbs"]

config :showtime_ex,
  stage_schema_files: common_schema_files ++ ["priv/schemas/messaging/stage_message.fbs"],
  graph_schema_files: common_schema_files ++ ["priv/schemas/messaging/graph_message.fbs"]

config :event_bus,
  topics: [
    :stage_msg_recv
  ],
  ttl: 30_000_000,
  time_unit: :microsecond,
  id_generator: EventBus.Util.Base62

# import_config "#{Mix.env()}.exs"
