defmodule AimailboxWeb.EmailDetailLive do
  use AimailboxWeb, :live_view

  alias Aimailbox.Contexts.Emails

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    email = Emails.get_email(id) |> Aimailbox.Repo.preload([:category, :gmail_account])

    {:ok,
     socket
     |> assign(:email, email)
     |> assign(:view_mode, "summary")
     |> assign(:page_title, email.subject || "Email Detail")}
  end

  @impl true
  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  @impl true
  def handle_event("delete_email", _params, socket) do
    case Emails.delete_email(socket.assigns.email) do
      {:ok, _} ->
        category_id = socket.assigns.email.category_id

        {:noreply,
         socket
         |> put_flash(:info, "Email deleted")
         |> push_navigate(to: ~p"/categories/#{category_id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete email")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <nav class="bg-white shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16">
            <div class="flex items-center">
              <%= if @email.category_id do %>
                <.link
                  navigate={~p"/categories/#{@email.category_id}"}
                  class="text-blue-600 hover:text-blue-800 mr-4"
                >
                  ← Back to Category
                </.link>
              <% else %>
                <.link navigate={~p"/dashboard"} class="text-blue-600 hover:text-blue-800 mr-4">
                  ← Back to Dashboard
                </.link>
              <% end %>
              <h1 class="text-xl font-bold text-gray-900">Email Detail</h1>
            </div>
            <button
              phx-click="delete_email"
              data-confirm="Are you sure you want to delete this email?"
              class="px-4 py-2 text-sm text-white bg-red-600 rounded hover:bg-red-700"
            >
              Delete
            </button>
          </div>
        </div>
      </nav>

      <main class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="bg-white rounded-lg shadow overflow-hidden">
          <!-- Email Header -->
          <div class="p-6 border-b border-gray-200">
            <div class="mb-4">
              <h2 class="text-2xl font-bold text-gray-900 mb-2">
                <%= @email.subject || "(No subject)" %>
              </h2>
              <%= if @email.category do %>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                  <%= @email.category.name %>
                </span>
              <% end %>
            </div>

            <div class="space-y-2 text-sm">
              <div class="flex">
                <span class="font-semibold text-gray-700 w-24">From:</span>
                <span class="text-gray-900">
                  <%= @email.from_name || @email.from_email %>
                  <%= if @email.from_name do %>
                    <span class="text-gray-500">&lt;<%= @email.from_email %>&gt;</span>
                  <% end %>
                </span>
              </div>
              <%= if @email.received_at do %>
                <div class="flex">
                  <span class="font-semibold text-gray-700 w-24">Date:</span>
                  <span class="text-gray-900">
                    <%= Calendar.strftime(@email.received_at, "%B %d, %Y at %I:%M %p") %>
                  </span>
                </div>
              <% end %>
              <div class="flex">
                <span class="font-semibold text-gray-700 w-24">Account:</span>
                <span class="text-gray-900"><%= @email.gmail_account.email %></span>
              </div>
            </div>
          </div>

          <!-- View Toggle -->
          <div class="px-6 py-3 bg-gray-50 border-b border-gray-200">
            <div class="flex space-x-2">
              <button
                phx-click="toggle_view"
                phx-value-mode="summary"
                class={"px-4 py-2 text-sm rounded #{if @view_mode == "summary", do: "bg-blue-600 text-white", else: "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"}"}
              >
                AI Summary
              </button>
              <button
                phx-click="toggle_view"
                phx-value-mode="text"
                class={"px-4 py-2 text-sm rounded #{if @view_mode == "text", do: "bg-blue-600 text-white", else: "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"}"}
              >
                Plain Text
              </button>
              <%= if @email.body_html do %>
                <button
                  phx-click="toggle_view"
                  phx-value-mode="html"
                  class={"px-4 py-2 text-sm rounded #{if @view_mode == "html", do: "bg-blue-600 text-white", else: "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"}"}
                >
                  HTML
                </button>
              <% end %>
            </div>
          </div>

          <!-- Email Content -->
          <div class="p-6">
            <%= case @view_mode do %>
              <% "summary" -> %>
                <%= if @email.summary do %>
                  <div class="p-4 bg-blue-50 rounded-lg border border-blue-200">
                    <h3 class="font-semibold text-blue-900 mb-2">AI Summary</h3>
                    <p class="text-gray-800 whitespace-pre-wrap"><%= @email.summary %></p>
                  </div>
                <% else %>
                  <div class="text-center py-8">
                    <p class="text-gray-500">No AI summary available for this email.</p>
                  </div>
                <% end %>
              <% "text" -> %>
                <%= if @email.body_text do %>
                  <div class="prose max-w-none">
                    <pre class="whitespace-pre-wrap text-sm font-mono bg-gray-50 p-4 rounded overflow-x-auto"><%= @email.body_text %></pre>
                  </div>
                <% else %>
                  <div class="text-center py-8">
                    <p class="text-gray-500">No plain text content available.</p>
                  </div>
                <% end %>
              <% "html" -> %>
                <%= if @email.body_html do %>
                  <div class="border border-gray-200 rounded-lg p-4">
                    <iframe
                      srcdoc={@email.body_html}
                      class="w-full h-96 border-0"
                      sandbox="allow-same-origin"
                    >
                    </iframe>
                  </div>
                <% else %>
                  <div class="text-center py-8">
                    <p class="text-gray-500">No HTML content available.</p>
                  </div>
                <% end %>
            <% end %>
          </div>

          <!-- Unsubscribe Section -->
          <%= if @email.unsubscribe_link do %>
            <div class="px-6 py-4 bg-yellow-50 border-t border-yellow-200">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="font-semibold text-yellow-900">Unsubscribe Available</h3>
                  <p class="text-sm text-yellow-700 mt-1">
                    This email contains an unsubscribe link.
                  </p>
                </div>
                <a
                  href={@email.unsubscribe_link}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700 text-sm font-medium"
                >
                  Visit Unsubscribe Page
                </a>
              </div>
            </div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end
