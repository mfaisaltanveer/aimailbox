defmodule Aimailbox.Schemas.GmailAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gmail_accounts" do
    field :email, :string
    field :access_token, Aimailbox.Encrypted.Binary
    field :refresh_token, Aimailbox.Encrypted.Binary
    field :token_expires_at, :utc_datetime
    field :last_history_id, :string

    belongs_to :user, Aimailbox.Schemas.User
    has_many :emails, Aimailbox.Schemas.Email

    timestamps(type: :utc_datetime)
  end

  def changeset(gmail_account, attrs) do
    gmail_account
    |> cast(attrs, [:user_id, :email, :access_token, :refresh_token, :token_expires_at, :last_history_id])
    |> validate_required([:user_id, :email])
    |> unique_constraint([:user_id, :email])
  end
end
