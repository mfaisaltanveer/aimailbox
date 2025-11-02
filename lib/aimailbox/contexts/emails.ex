defmodule Aimailbox.Contexts.Emails do
  @moduledoc """
  The Emails context for managing Gmail accounts, categories, and emails.
  """

  import Ecto.Query
  alias Aimailbox.Repo
  alias Aimailbox.Schemas.{GmailAccount, Category, Email}

  # Gmail Accounts

  def list_gmail_accounts_for_user(user_id) do
    GmailAccount
    |> where([g], g.user_id == ^user_id)
    |> Repo.all()
  end

  def get_gmail_account(id), do: Repo.get(GmailAccount, id)

  def create_gmail_account(attrs) do
    %GmailAccount{}
    |> GmailAccount.changeset(attrs)
    |> Repo.insert()
  end

  def update_gmail_account(gmail_account, attrs) do
    gmail_account
    |> GmailAccount.changeset(attrs)
    |> Repo.update()
  end

  def delete_gmail_account(gmail_account) do
    Repo.delete(gmail_account)
  end

  # Categories

  def list_categories_for_user(user_id) do
    Category
    |> where([c], c.user_id == ^user_id)
    |> preload(:emails)
    |> Repo.all()
  end

  def get_category(id) do
    Repo.get(Category, id)
  end

  def get_category_with_emails(id) do
    Category
    |> where([c], c.id == ^id)
    |> preload(emails: [:gmail_account])
    |> Repo.one()
  end

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(category) do
    Repo.delete(category)
  end

  # Emails

  def list_emails_for_category(category_id) do
    Email
    |> where([e], e.category_id == ^category_id)
    |> order_by([e], desc: e.received_at)
    |> preload(:gmail_account)
    |> Repo.all()
  end

  def get_email(id) do
    Repo.get(Email, id)
  end

  def get_email_by_gmail_message_id(gmail_account_id, gmail_message_id) do
    Email
    |> where([e], e.gmail_account_id == ^gmail_account_id and e.gmail_message_id == ^gmail_message_id)
    |> Repo.one()
  end

  def create_email(attrs) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  def update_email(email, attrs) do
    email
    |> Email.changeset(attrs)
    |> Repo.update()
  end

  def delete_email(email) do
    Repo.delete(email)
  end

  def delete_emails(email_ids) do
    Email
    |> where([e], e.id in ^email_ids)
    |> Repo.delete_all()
  end
end
