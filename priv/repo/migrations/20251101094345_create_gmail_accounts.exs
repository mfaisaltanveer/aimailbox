defmodule Aimailbox.Repo.Migrations.CreateGmailAccounts do
  use Ecto.Migration

  def change do
    create table(:gmail_accounts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :email, :string, null: false
      add :access_token, :binary
      add :refresh_token, :binary
      add :token_expires_at, :utc_datetime
      add :last_history_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:gmail_accounts, [:user_id])
    create unique_index(:gmail_accounts, [:user_id, :email])
  end
end
