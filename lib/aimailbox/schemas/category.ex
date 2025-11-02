defmodule Aimailbox.Schemas.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :description, :string

    belongs_to :user, Aimailbox.Schemas.User
    has_many :emails, Aimailbox.Schemas.Email

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:user_id, :name, :description])
    |> validate_required([:user_id, :name, :description])
    |> unique_constraint([:user_id, :name])
  end
end
