import Config

# config :algoliax,
#   api_key: "e7c7b7e90041606165d80ba87cdb93f2",
#   application_id: "W38ASRUMOC"

if Mix.env() == :test do
  import_config("test.exs")
end
