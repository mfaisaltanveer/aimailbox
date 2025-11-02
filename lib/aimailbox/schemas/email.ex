defmodule Aimailbox.Schemas.Email do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emails" do
    field :gmail_message_id, :string
    field :subject, :string
    field :from_email, :string
    field :from_name, :string
    field :body_text, :string
    field :body_html, :string
    field :summary, :string
    field :received_at, :utc_datetime
    field :unsubscribe_link, :string

    belongs_to :category, Aimailbox.Schemas.Category
    belongs_to :gmail_account, Aimailbox.Schemas.GmailAccount

    timestamps(type: :utc_datetime)
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, [
      :gmail_account_id,
      :category_id,
      :gmail_message_id,
      :subject,
      :from_email,
      :from_name,
      :body_text,
      :body_html,
      :summary,
      :received_at,
      :unsubscribe_link
    ])
    |> validate_required([:gmail_account_id, :gmail_message_id])
    |> unique_constraint([:gmail_account_id, :gmail_message_id])
  end
end
