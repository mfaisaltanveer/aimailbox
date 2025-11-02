defmodule AimailboxWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Aimailbox.Contexts.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    cond do
      user = user_id && Accounts.get_user(user_id) ->
        assign(conn, :current_user, user)

      true ->
        conn
        |> put_flash(:error, "You must be signed in to access this page")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
