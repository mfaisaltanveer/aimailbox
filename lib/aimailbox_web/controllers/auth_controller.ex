defmodule AimailboxWeb.AuthController do
  use AimailboxWeb, :controller
  plug Ueberauth

  alias Aimailbox.Contexts.Accounts
  alias Aimailbox.Contexts.Emails

  def request(conn, _params) do
    # This will redirect to Google OAuth
    conn
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate with Google")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_info = auth.info
    credentials = auth.credentials

    tokens = %{
      access_token: credentials.token,
      refresh_token: credentials.refresh_token,
      expires_at: DateTime.from_unix!(credentials.expires_at)
    }

    user_data = %{
      "sub" => auth.uid,
      "email" => user_info.email,
      "name" => user_info.name,
      "picture" => user_info.image
    }

    case Accounts.create_or_update_user_from_oauth(user_data, tokens) do
      {:ok, user} ->
        # Also create/update Gmail account for this user
        create_or_update_gmail_account(user, user_info.email, tokens)

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Successfully authenticated!")
        |> redirect(to: "/dashboard")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to create user account")
        |> redirect(to: "/")
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: "/")
  end

  defp create_or_update_gmail_account(user, email, tokens) do
    # Check if Gmail account already exists
    existing_accounts = Emails.list_gmail_accounts_for_user(user.id)
    existing = Enum.find(existing_accounts, fn acc -> acc.email == email end)

    attrs = %{
      user_id: user.id,
      email: email,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      token_expires_at: tokens.expires_at
    }

    if existing do
      Emails.update_gmail_account(existing, attrs)
    else
      Emails.create_gmail_account(attrs)
    end
  end
end
