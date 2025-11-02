defmodule Aimailbox.AI.OpenAIClient do
  @moduledoc """
  OpenAI API client for email categorization and summarization.
  """

  @api_url "https://api.openai.com/v1/chat/completions"

  def categorize_email(email_content, categories) do
    api_key = Application.get_env(:aimailbox, :openai_api_key)

    categories_text = Enum.map_join(categories, "\n", fn cat ->
      "- #{cat.name}: #{cat.description}"
    end)

    prompt = """
    You are an email categorization assistant. Given an email and a list of categories with descriptions,
    determine which category the email belongs to. Return ONLY the category name, nothing else.

    Categories:
    #{categories_text}

    Email Subject: #{email_content.subject || "No subject"}
    Email From: #{email_content.from_email}
    Email Body (first 500 chars): #{String.slice(email_content.body_text || "", 0, 500)}

    Which category does this email belong to? Return only the category name.
    """

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      "model" => "gpt-4o-mini",
      "messages" => [
        %{"role" => "system", "content" => "You are a helpful email categorization assistant."},
        %{"role" => "user", "content" => prompt}
      ],
      "temperature" => 0.3,
      "max_tokens" => 50
    })

    case Req.post(@api_url, headers: headers, body: body) do
      {:ok, %{status: 200, body: response}} ->
        category_name = response
        |> Map.get("choices", [])
        |> List.first()
        |> Map.get("message", %{})
        |> Map.get("content", "")
        |> String.trim()

        # Find matching category
        matching_category = Enum.find(categories, fn cat ->
          String.downcase(cat.name) == String.downcase(category_name)
        end)

        case matching_category do
          nil -> {:ok, nil}
          category -> {:ok, category.id}
        end

      {:error, error} ->
        {:error, "OpenAI request failed: #{inspect(error)}"}
    end
  end

  def summarize_email(email_content) do
    api_key = Application.get_env(:aimailbox, :openai_api_key)

    prompt = """
    Summarize the following email in 1-2 concise sentences. Focus on the main point and any action items.

    Subject: #{email_content.subject || "No subject"}
    From: #{email_content.from_email}
    Body: #{email_content.body_text || "No content"}
    """

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      "model" => "gpt-4o-mini",
      "messages" => [
        %{"role" => "system", "content" => "You are a helpful email summarization assistant. Be concise and focus on key information."},
        %{"role" => "user", "content" => prompt}
      ],
      "temperature" => 0.5,
      "max_tokens" => 150
    })

    case Req.post(@api_url, headers: headers, body: body) do
      {:ok, %{status: 200, body: response}} ->
        summary = response
        |> Map.get("choices", [])
        |> List.first()
        |> Map.get("message", %{})
        |> Map.get("content", "")
        |> String.trim()

        {:ok, summary}

      {:error, error} ->
        {:error, "OpenAI request failed: #{inspect(error)}"}
    end
  end

  def generate_unsubscribe_plan(unsubscribe_link, page_content \\ nil) do
    api_key = Application.get_env(:aimailbox, :openai_api_key)

    prompt = if page_content do
      """
      You are an AI agent helping to unsubscribe from email lists.
      Given the following unsubscribe page content, describe the exact steps needed to unsubscribe.

      Unsubscribe Link: #{unsubscribe_link}
      Page Content (simplified): #{String.slice(page_content, 0, 1000)}

      Provide clear, step-by-step instructions on how to complete the unsubscribe process.
      """
    else
      """
      You are an AI agent helping to unsubscribe from email lists.
      Given the following unsubscribe link: #{unsubscribe_link}

      Describe what steps would typically be needed to unsubscribe from this type of email.
      Note: This is a simulation - describe the process but don't actually perform it.
      """
    end

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      "model" => "gpt-4o-mini",
      "messages" => [
        %{"role" => "system", "content" => "You are a helpful assistant for managing email subscriptions."},
        %{"role" => "user", "content" => prompt}
      ],
      "temperature" => 0.7,
      "max_tokens" => 300
    })

    case Req.post(@api_url, headers: headers, body: body) do
      {:ok, %{status: 200, body: response}} ->
        plan = response
        |> Map.get("choices", [])
        |> List.first()
        |> Map.get("message", %{})
        |> Map.get("content", "")
        |> String.trim()

        {:ok, plan}

      {:error, error} ->
        {:error, "OpenAI request failed: #{inspect(error)}"}
    end
  end
end
