import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :aimailbox, Aimailbox.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aimailbox_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :aimailbox, AimailboxWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+ngHhxZDNipKSd9VI+6e3wdoMeLTXE1ZSXvGdGs9gCtMXJGk9qn1TVlMRH24e7ri",
  server: false

# In test we don't send emails
config :aimailbox, Aimailbox.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure Cloak for encryption in tests (using a dummy key)
config :aimailbox, Aimailbox.Encrypted,
  ciphers: [
    default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Base.decode64!("YVh1azIxMDVMZFNUS1ZreE5CVFBEeTd3TU1RL2NxSUs=")}
  ]

# Configure Oban to use inline testing mode
config :aimailbox, Oban,
  testing: :inline

# Configure dummy OpenAI API key for tests
config :aimailbox, :openai_api_key, "test_key_123"
