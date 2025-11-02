defmodule AimailboxWeb.DashboardLive do
  use AimailboxWeb, :live_view

  alias Aimailbox.Contexts.Emails
  alias Aimailbox.Workers.EmailImporter

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    gmail_accounts = Emails.list_gmail_accounts_for_user(user.id)
    categories = Emails.list_categories_for_user(user.id)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:gmail_accounts, gmail_accounts)
     |> assign(:categories, categories)
     |> assign(:show_category_form, false)
     |> assign(:show_account_form, false)
     |> assign(:category_form, to_form(%{}))
     |> assign(:page_title, "Dashboard")}
  end

  @impl true
  def handle_event("show_category_form", _params, socket) do
    {:noreply, assign(socket, show_category_form: true)}
  end

  @impl true
  def handle_event("hide_category_form", _params, socket) do
    {:noreply, assign(socket, show_category_form: false)}
  end

  @impl true
  def handle_event("create_category", %{"name" => name, "description" => description}, socket) do
    attrs = %{
      user_id: socket.assigns.user.id,
      name: name,
      description: description
    }

    case Emails.create_category(attrs) do
      {:ok, _category} ->
        categories = Emails.list_categories_for_user(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:categories, categories)
         |> assign(:show_category_form, false)
         |> put_flash(:info, "Category created successfully!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create category")}
    end
  end

  @impl true
  def handle_event("delete_category", %{"id" => id}, socket) do
    category = Emails.get_category(id)

    case Emails.delete_category(category) do
      {:ok, _} ->
        categories = Emails.list_categories_for_user(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:categories, categories)
         |> put_flash(:info, "Category deleted")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete category")}
    end
  end

  @impl true
  def handle_event("show_account_form", _params, socket) do
    {:noreply, assign(socket, show_account_form: true)}
  end

  @impl true
  def handle_event("hide_account_form", _params, socket) do
    {:noreply, assign(socket, show_account_form: false)}
  end

  @impl true
  def handle_event("sync_emails", %{"account_id" => account_id}, socket) do
    # Queue job to import emails
    %{gmail_account_id: String.to_integer(account_id)}
    |> EmailImporter.new()
    |> Oban.insert()

    {:noreply, put_flash(socket, :info, "Email sync started in the background!")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <nav class="bg-white shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex items-center">
              <h1 class="text-2xl font-bold text-gray-900">AI Mailbox</h1>
            </div>
            <div class="flex items-center space-x-4">
              <span class="text-sm text-gray-600"><%= @user.email %></span>
              <a href="/auth/signout" class="text-sm text-red-600 hover:text-red-800">
                Sign Out
              </a>
            </div>
          </div>
        </div>
      </nav>

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Gmail Accounts Section -->
          <div class="lg:col-span-1">
            <div class="bg-white rounded-lg shadow p-6">
              <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-semibold text-gray-900">Gmail Accounts</h2>
                <button
                  phx-click="show_account_form"
                  class="text-sm bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700"
                >
                  + Add
                </button>
              </div>

              <%= if @show_account_form do %>
                <div class="mb-4 p-4 bg-blue-50 rounded border border-blue-200">
                  <p class="text-sm text-gray-700 mb-2">
                    To add another Gmail account, click the button below to authorize access:
                  </p>
                  <div class="flex space-x-2">
                    <a
                      href="/auth/google"
                      class="flex-1 text-center bg-blue-600 text-white px-3 py-2 rounded text-sm hover:bg-blue-700"
                    >
                      Authorize Gmail
                    </a>
                    <button
                      phx-click="hide_account_form"
                      class="bg-gray-300 text-gray-700 px-3 py-2 rounded text-sm hover:bg-gray-400"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              <% end %>

              <div class="space-y-2">
                <%= if Enum.empty?(@gmail_accounts) do %>
                  <p class="text-sm text-gray-500 italic">No accounts connected yet</p>
                <% else %>
                  <%= for account <- @gmail_accounts do %>
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded">
                      <div class="flex-1">
                        <p class="text-sm font-medium text-gray-900"><%= account.email %></p>
                      </div>
                      <button
                        phx-click="sync_emails"
                        phx-value-account_id={account.id}
                        class="text-xs bg-green-600 text-white px-2 py-1 rounded hover:bg-green-700"
                      >
                        Sync
                      </button>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Categories Section -->
          <div class="lg:col-span-2">
            <div class="bg-white rounded-lg shadow p-6">
              <div class="flex justify-between items-center mb-6">
                <h2 class="text-lg font-semibold text-gray-900">Email Categories</h2>
                <button
                  phx-click="show_category_form"
                  class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                >
                  + Add Category
                </button>
              </div>

              <%= if @show_category_form do %>
                <div class="mb-6 p-6 bg-blue-50 rounded-lg border border-blue-200">
                  <h3 class="font-semibold text-gray-900 mb-4">Create New Category</h3>
                  <form phx-submit="create_category" class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Category Name
                      </label>
                      <input
                        type="text"
                        name="name"
                        required
                        placeholder="e.g., Newsletters, Receipts, Work"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Description (for AI)
                      </label>
                      <textarea
                        name="description"
                        required
                        rows="3"
                        placeholder="Describe what emails belong in this category. E.g., 'Email newsletters from blogs, news sites, and subscription services'"
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      ></textarea>
                    </div>
                    <div class="flex space-x-2">
                      <button
                        type="submit"
                        class="flex-1 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                      >
                        Create Category
                      </button>
                      <button
                        type="button"
                        phx-click="hide_category_form"
                        class="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                </div>
              <% end %>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= if Enum.empty?(@categories) do %>
                  <div class="col-span-2">
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
                          d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                        />
                      </svg>
                      <h3 class="mt-2 text-sm font-medium text-gray-900">No categories</h3>
                      <p class="mt-1 text-sm text-gray-500">
                        Get started by creating a new category.
                      </p>
                    </div>
                  </div>
                <% else %>
                  <%= for category <- @categories do %>
                    <div class="border border-gray-200 rounded-lg hover:shadow-md transition-shadow">
                      <.link
                        navigate={~p"/categories/#{category.id}"}
                        class="block p-4 hover:bg-gray-50"
                      >
                        <div class="flex justify-between items-start mb-2">
                          <h3 class="font-semibold text-gray-900"><%= category.name %></h3>
                          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            <%= length(category.emails) %> emails
                          </span>
                        </div>
                        <p class="text-sm text-gray-600 line-clamp-2">
                          <%= category.description %>
                        </p>
                      </.link>
                      <div class="px-4 pb-3">
                        <button
                          phx-click="delete_category"
                          phx-value-id={category.id}
                          data-confirm="Are you sure you want to delete this category?"
                          class="text-xs text-red-600 hover:text-red-800"
                        >
                          Delete
                        </button>
                      </div>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
