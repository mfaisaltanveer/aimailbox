defmodule Aimailbox.EmailsContextTest do
  use Aimailbox.DataCase

  alias Aimailbox.Contexts.Emails
  alias Aimailbox.Contexts.Accounts

  setup do
    oauth_data = %{
      "sub" => "google_123",
      "email" => "test@example.com",
      "name" => "Test User",
      "picture" => "https://example.com/avatar.jpg"
    }

    tokens = %{
      access_token: nil,
      refresh_token: nil,
      expires_at: DateTime.add(DateTime.utc_now(), 3600)
    }

    {:ok, user} = Accounts.create_or_update_user_from_oauth(oauth_data, tokens)
    %{user: user}
  end

  describe "categories" do
    test "create_category/1 creates a category", %{user: user} do
      attrs = %{
        user_id: user.id,
        name: "Newsletters",
        description: "Email newsletters from blogs and news sites"
      }

      assert {:ok, category} = Emails.create_category(attrs)
      assert category.name == "Newsletters"
      assert category.user_id == user.id
    end

    test "list_categories_for_user/1 returns all categories for a user", %{user: user} do
      attrs1 = %{user_id: user.id, name: "Work", description: "Work emails"}
      attrs2 = %{user_id: user.id, name: "Personal", description: "Personal emails"}

      {:ok, _cat1} = Emails.create_category(attrs1)
      {:ok, _cat2} = Emails.create_category(attrs2)

      categories = Emails.list_categories_for_user(user.id)
      assert length(categories) == 2
    end

    test "delete_category/1 deletes the category", %{user: user} do
      attrs = %{user_id: user.id, name: "Test", description: "Test category"}
      {:ok, category} = Emails.create_category(attrs)

      assert {:ok, _} = Emails.delete_category(category)
      assert Emails.get_category(category.id) == nil
    end
  end

  describe "gmail_accounts" do
    test "create_gmail_account/1 creates a gmail account", %{user: user} do
      attrs = %{
        user_id: user.id,
        email: "test@gmail.com",
        access_token: nil,
        refresh_token: nil
      }

      assert {:ok, account} = Emails.create_gmail_account(attrs)
      assert account.email == "test@gmail.com"
      assert account.user_id == user.id
    end

    test "list_gmail_accounts_for_user/1 returns all accounts for a user", %{user: user} do
      attrs = %{
        user_id: user.id,
        email: "test@gmail.com",
        access_token: nil
      }

      {:ok, _account} = Emails.create_gmail_account(attrs)

      accounts = Emails.list_gmail_accounts_for_user(user.id)
      assert length(accounts) == 1
    end
  end

  describe "emails" do
    setup %{user: user} do
      {:ok, account} = Emails.create_gmail_account(%{
        user_id: user.id,
        email: "test@gmail.com",
        access_token: nil
      })

      {:ok, category} = Emails.create_category(%{
        user_id: user.id,
        name: "Test",
        description: "Test category"
      })

      %{account: account, category: category}
    end

    test "create_email/1 creates an email", %{account: account, category: category} do
      attrs = %{
        gmail_account_id: account.id,
        category_id: category.id,
        gmail_message_id: "msg_123",
        subject: "Test Email",
        from_email: "sender@example.com",
        body_text: "This is a test email"
      }

      assert {:ok, email} = Emails.create_email(attrs)
      assert email.subject == "Test Email"
      assert email.gmail_account_id == account.id
    end

    test "list_emails_for_category/1 returns emails for a category", %{account: account, category: category} do
      attrs = %{
        gmail_account_id: account.id,
        category_id: category.id,
        gmail_message_id: "msg_123",
        subject: "Test Email"
      }

      {:ok, _email} = Emails.create_email(attrs)

      emails = Emails.list_emails_for_category(category.id)
      assert length(emails) == 1
    end

    test "delete_emails/1 deletes multiple emails", %{account: account, category: category} do
      {:ok, email1} = Emails.create_email(%{
        gmail_account_id: account.id,
        category_id: category.id,
        gmail_message_id: "msg_1",
        subject: "Email 1"
      })

      {:ok, email2} = Emails.create_email(%{
        gmail_account_id: account.id,
        category_id: category.id,
        gmail_message_id: "msg_2",
        subject: "Email 2"
      })

      {count, _} = Emails.delete_emails([email1.id, email2.id])
      assert count == 2
    end
  end
end
