defmodule Aimailbox.Repo do
  use Ecto.Repo,
    otp_app: :aimailbox,
    adapter: Ecto.Adapters.Postgres
end
