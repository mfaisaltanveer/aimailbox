defmodule Aimailbox.AccountsTest do
  use Aimailbox.DataCase

  alias Aimailbox.Contexts.Accounts

  describe "users" do
    @valid_oauth_data %{
      "sub" => "google_123",
      "email" => "test@example.com",
      "name" => "Test User",
      "picture" => "https://example.com/avatar.jpg"
    }

    @valid_tokens %{
      access_token: nil,
      refresh_token: nil,
      expires_at: DateTime.add(DateTime.utc_now(), 3600)
    }

    test "create_or_update_user_from_oauth/2 creates a new user" do
      assert {:ok, user} = Accounts.create_or_update_user_from_oauth(@valid_oauth_data, @valid_tokens)
      assert user.email == "test@example.com"
      assert user.name == "Test User"
      assert user.google_id == "google_123"
    end

    test "create_or_update_user_from_oauth/2 updates existing user" do
      {:ok, user} = Accounts.create_or_update_user_from_oauth(@valid_oauth_data, @valid_tokens)

      updated_data = Map.put(@valid_oauth_data, "name", "Updated Name")
      assert {:ok, updated_user} = Accounts.create_or_update_user_from_oauth(updated_data, @valid_tokens)

      assert updated_user.id == user.id
      assert updated_user.name == "Updated Name"
    end

    test "get_user/1 returns the user with given id" do
      {:ok, user} = Accounts.create_or_update_user_from_oauth(@valid_oauth_data, @valid_tokens)
      assert Accounts.get_user(user.id).id == user.id
    end

    test "get_user_by_email/1 returns the user with given email" do
      {:ok, user} = Accounts.create_or_update_user_from_oauth(@valid_oauth_data, @valid_tokens)
      assert Accounts.get_user_by_email("test@example.com").id == user.id
    end
  end
end
