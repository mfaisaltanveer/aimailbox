defmodule Aimailbox.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :google_id, :string
    field :name, :string
    field :avatar_url, :string
    field :access_token, Aimailbox.Encrypted.Binary
    field :refresh_token, Aimailbox.Encrypted.Binary
    field :token_expires_at, :utc_datetime

    has_many :gmail_accounts, Aimailbox.Schemas.GmailAccount
    has_many :categories, Aimailbox.Schemas.Category

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :google_id, :name, :avatar_url, :access_token, :refresh_token, :token_expires_at])
    |> validate_required([:email, :google_id])
    |> unique_constraint(:email)
    |> unique_constraint(:google_id)
  end
end
