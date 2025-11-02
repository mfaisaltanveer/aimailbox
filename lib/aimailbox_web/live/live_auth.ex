defmodule AimailboxWeb.LiveAuth do
  @moduledoc """
  Ensures common assigns are applied to all LiveViews.
  """
  import Phoenix.Component
  import Phoenix.LiveView

  alias Aimailbox.Contexts.Accounts

  def on_mount(:default, _params, session, socket) do
    socket =
      socket
      |> assign_new(:current_user, fn ->
        find_current_user(session)
      end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end

  defp find_current_user(session) do
    with user_id when not is_nil(user_id) <- session["user_id"],
         %_{} = user <- Accounts.get_user(user_id) do
      user
    else
      _ -> nil
    end
  end
end
