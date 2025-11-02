defmodule Aimailbox.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :category_id, references(:categories, on_delete: :nilify_all)
      add :gmail_account_id, references(:gmail_accounts, on_delete: :delete_all), null: false
      add :gmail_message_id, :string, null: false
      add :subject, :string
      add :from_email, :string
      add :from_name, :string
      add :body_text, :text
      add :body_html, :text
      add :summary, :text
      add :received_at, :utc_datetime
      add :unsubscribe_link, :string

      timestamps(type: :utc_datetime)
    end

    create index(:emails, [:category_id])
    create index(:emails, [:gmail_account_id])
    create unique_index(:emails, [:gmail_account_id, :gmail_message_id])
  end
end
