defmodule Aimailbox.Contexts.Accounts do
  @moduledoc """
  The Accounts context for managing users.
  """

  alias Aimailbox.Repo
  alias Aimailbox.Schemas.User

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def get_user_by_google_id(google_id), do: Repo.get_by(User, google_id: google_id)

  def create_or_update_user_from_oauth(%{
        "sub" => google_id,
        "email" => email,
        "name" => name,
        "picture" => avatar_url
      }, tokens) do
    attrs = %{
      google_id: google_id,
      email: email,
      name: name,
      avatar_url: avatar_url,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      token_expires_at: tokens.expires_at
    }

    case get_user_by_google_id(google_id) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()

      user ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  def update_user_tokens(user, access_token, refresh_token, expires_at) do
    user
    |> User.changeset(%{
      access_token: access_token,
      refresh_token: refresh_token,
      token_expires_at: expires_at
    })
    |> Repo.update()
  end
end
