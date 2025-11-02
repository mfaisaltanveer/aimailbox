defmodule Aimailbox.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :google_id, :string, null: false
      add :name, :string
      add :avatar_url, :string
      add :access_token, :binary
      add :refresh_token, :binary
      add :token_expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:google_id])
  end
end
