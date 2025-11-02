defmodule Aimailbox.Workers.EmailImporter do
  @moduledoc """
  Oban worker that imports new emails from Gmail accounts.
  """
  use Oban.Worker, queue: :emails, max_attempts: 3

  alias Aimailbox.Contexts.Emails
  alias Aimailbox.Gmail.Client, as: GmailClient
  alias Aimailbox.AI.OpenAIClient

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"gmail_account_id" => gmail_account_id}}) do
    gmail_account = Emails.get_gmail_account(gmail_account_id)

    if gmail_account do
      import_emails(gmail_account)
    else
      {:error, :account_not_found}
    end
  end

  defp import_emails(gmail_account) do
    # Get user's categories
    categories = Emails.list_categories_for_user(gmail_account.user_id)

    # Fetch recent emails from Gmail
    case GmailClient.fetch_recent_emails(gmail_account.access_token) do
      {:ok, emails} ->
        Enum.each(emails, fn email_data ->
          process_email(email_data, gmail_account, categories)
        end)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_email(email_data, gmail_account, categories) do
    # Check if email already exists
    existing = Emails.get_email_by_gmail_message_id(
      gmail_account.id,
      email_data.gmail_message_id
    )

    if existing do
      :already_imported
    else
      # Categorize email using AI
      {:ok, category_id} = if Enum.empty?(categories) do
        {:ok, nil}
      else
        OpenAIClient.categorize_email(email_data, categories)
      end

      # Summarize email using AI
      {:ok, summary} = OpenAIClient.summarize_email(email_data)

      # Create email record
      email_attrs = Map.merge(email_data, %{
        gmail_account_id: gmail_account.id,
        category_id: category_id,
        summary: summary
      })

      case Emails.create_email(email_attrs) do
        {:ok, _email} ->
          # Archive email in Gmail
          GmailClient.archive_email(gmail_account.access_token, email_data.gmail_message_id)
          :ok

        {:error, _} ->
          :error
      end
    end
  end
end
