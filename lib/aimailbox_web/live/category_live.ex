defmodule AimailboxWeb.CategoryLive do
  use AimailboxWeb, :live_view

  alias Aimailbox.Contexts.Emails
  alias Aimailbox.AI.OpenAIClient

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    category = Emails.get_category_with_emails(id)

    {:ok,
     socket
     |> assign(:category, category)
     |> assign(:selected_emails, MapSet.new())
     |> assign(:page_title, category.name)}
  end

  @impl true
  def handle_event("toggle_email", %{"id" => id}, socket) do
    email_id = String.to_integer(id)
    selected = socket.assigns.selected_emails

    new_selected =
      if MapSet.member?(selected, email_id) do
        MapSet.delete(selected, email_id)
      else
        MapSet.put(selected, email_id)
      end

    {:noreply, assign(socket, :selected_emails, new_selected)}
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    all_ids = Enum.map(socket.assigns.category.emails, & &1.id)
    {:noreply, assign(socket, :selected_emails, MapSet.new(all_ids))}
  end

  @impl true
  def handle_event("deselect_all", _params, socket) do
    {:noreply, assign(socket, :selected_emails, MapSet.new())}
  end

  @impl true
  def handle_event("delete_selected", _params, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_emails)

    case Emails.delete_emails(selected_ids) do
      {count, _} when count > 0 ->
        category = Emails.get_category_with_emails(socket.assigns.category.id)

        {:noreply,
         socket
         |> assign(:category, category)
         |> assign(:selected_emails, MapSet.new())
         |> put_flash(:info, "Deleted #{count} email(s)")}

      _ ->
        {:noreply, put_flash(socket, :error, "Failed to delete emails")}
    end
  end

  @impl true
  def handle_event("unsubscribe_selected", _params, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_emails)
    emails = Enum.filter(socket.assigns.category.emails, &(&1.id in selected_ids))

    # Process unsubscribe links for selected emails
    results =
      Enum.map(emails, fn email ->
        if email.unsubscribe_link do
          case OpenAIClient.generate_unsubscribe_plan(email.unsubscribe_link) do
            {:ok, plan} -> {:ok, email.subject, plan}
            {:error, _} -> {:error, email.subject}
          end
        else
          {:no_link, email.subject}
        end
      end)

    success_count = Enum.count(results, &match?({:ok, _, _}, &1))
    no_link_count = Enum.count(results, &match?({:no_link, _}, &1))

    message =
      cond do
        success_count > 0 ->
          "Generated unsubscribe plans for #{success_count} email(s). #{if no_link_count > 0, do: "#{no_link_count} had no unsubscribe link.", else: ""}"

        no_link_count > 0 ->
          "#{no_link_count} email(s) had no unsubscribe link"

        true ->
          "Failed to process unsubscribe requests"
      end

    {:noreply, put_flash(socket, :info, message)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <nav class="bg-white shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center h-16">
            <.link navigate={~p"/dashboard"} class="text-blue-600 hover:text-blue-800 mr-4">
              ← Back to Dashboard
            </.link>
            <h1 class="text-2xl font-bold text-gray-900"><%= @category.name %></h1>
          </div>
        </div>
      </nav>

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="bg-white rounded-lg shadow">
          <!-- Header with bulk actions -->
          <div class="p-6 border-b border-gray-200">
            <div class="flex justify-between items-center">
              <div>
                <p class="text-sm text-gray-600"><%= @category.description %></p>
                <p class="text-sm text-gray-500 mt-1">
                  <%= length(@category.emails) %> email(s) in this category
                </p>
              </div>

              <%= if MapSet.size(@selected_emails) > 0 do %>
                <div class="flex space-x-2">
                  <button
                    phx-click="deselect_all"
                    class="px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded hover:bg-gray-200"
                  >
                    Deselect All
                  </button>
                  <button
                    phx-click="delete_selected"
                    data-confirm={"Are you sure you want to delete #{MapSet.size(@selected_emails)} email(s)?"}
                    class="px-4 py-2 text-sm text-white bg-red-600 rounded hover:bg-red-700"
                  >
                    Delete (<%= MapSet.size(@selected_emails) %>)
                  </button>
                  <button
                    phx-click="unsubscribe_selected"
                    class="px-4 py-2 text-sm text-white bg-blue-600 rounded hover:bg-blue-700"
                  >
                    Unsubscribe (<%= MapSet.size(@selected_emails) %>)
                  </button>
                </div>
              <% else %>
                <button
                  phx-click="select_all"
                  class="px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded hover:bg-gray-200"
                >
                  Select All
                </button>
              <% end %>
            </div>
          </div>

          <!-- Emails list -->
          <div class="divide-y divide-gray-200">
            <%= if Enum.empty?(@category.emails) do %>
              <div class="text-center py-12">
                <svg
                  class="mx-auto h-12 w-12 text-gray-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  />
                </svg>
                <h3 class="mt-2 text-sm font-medium text-gray-900">No emails yet</h3>
                <p class="mt-1 text-sm text-gray-500">
                  Emails matching this category will appear here when they're imported.
                </p>
              </div>
            <% else %>
              <%= for email <- @category.emails do %>
                <div class="p-6 hover:bg-gray-50 transition-colors">
                  <div class="flex items-start space-x-4">
                    <div class="flex-shrink-0 pt-1">
                      <input
                        type="checkbox"
                        checked={MapSet.member?(@selected_emails, email.id)}
                        phx-click="toggle_email"
                        phx-value-id={email.id}
                        class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded cursor-pointer"
                      />
                    </div>

                    <div class="flex-1 min-w-0">
                      <.link
                        navigate={~p"/emails/#{email.id}"}
                        class="block hover:text-blue-600"
                      >
                        <div class="flex items-center justify-between mb-2">
                          <div class="flex-1">
                            <p class="text-sm font-semibold text-gray-900 truncate">
                              <%= email.subject || "(No subject)" %>
                            </p>
                            <p class="text-sm text-gray-600">
                              From: <%= email.from_name || email.from_email %>
                              <%= if email.from_name do %>
                                <span class="text-gray-400">&lt;<%= email.from_email %>&gt;</span>
                              <% end %>
                            </p>
                          </div>
                          <div class="ml-4 flex-shrink-0">
                            <p class="text-xs text-gray-500">
                              <%= if email.received_at do %>
                                <%= Calendar.strftime(email.received_at, "%b %d, %Y") %>
                              <% end %>
                            </p>
                          </div>
                        </div>

                        <%= if email.summary do %>
                          <div class="mt-2 p-3 bg-blue-50 rounded-lg border border-blue-100">
                            <p class="text-xs font-semibold text-blue-900 mb-1">AI Summary:</p>
                            <p class="text-sm text-gray-700"><%= email.summary %></p>
                          </div>
                        <% end %>

                        <%= if email.unsubscribe_link do %>
                          <div class="mt-2">
                            <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800">
                              <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                <path
                                  fill-rule="evenodd"
                                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                  clip-rule="evenodd"
                                />
                              </svg>
                              Unsubscribe Available
                            </span>
                          </div>
                        <% end %>
                      </.link>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
