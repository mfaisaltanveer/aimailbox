defmodule Aimailbox.Gmail.Client do
  @moduledoc """
  Gmail API client for fetching and managing emails.
  """

  @base_url "https://gmail.googleapis.com/gmail/v1/users/me"

  def fetch_recent_emails(access_token, max_results \\ 10) do
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get("#{@base_url}/messages", headers: headers, params: [maxResults: max_results]) do
      {:ok, %{status: 200, body: %{"messages" => messages}}} ->
        emails = Enum.map(messages, fn %{"id" => id} ->
          case get_email_details(access_token, id) do
            {:ok, email} -> email
            {:error, _} -> nil
          end
        end)
        |> Enum.filter(&(&1 != nil))

        {:ok, emails}

      {:ok, %{status: 200, body: %{}}} ->
        {:ok, []}

      {:ok, %{status: status}} ->
        {:error, "Failed to fetch emails: HTTP #{status}"}

      {:error, error} ->
        {:error, "Request failed: #{inspect(error)}"}
    end
  end

  def get_email_details(access_token, message_id) do
    headers = [{"Authorization", "Bearer #{access_token}"}]

    case Req.get("#{@base_url}/messages/#{message_id}", headers: headers, params: [format: "full"]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_email(body)}

      {:ok, %{status: status}} ->
        {:error, "Failed to get email: HTTP #{status}"}

      {:error, error} ->
        {:error, "Request failed: #{inspect(error)}"}
    end
  end

  def archive_email(access_token, message_id) do
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      "removeLabelIds" => ["INBOX"]
    })

    case Req.post("#{@base_url}/messages/#{message_id}/modify",
      headers: headers,
      body: body
    ) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, "Failed to archive email: HTTP #{status}"}

      {:error, error} ->
        {:error, "Request failed: #{inspect(error)}"}
    end
  end

  defp parse_email(%{"id" => id, "payload" => payload}) do
    headers = Map.get(payload, "headers", [])

    %{
      gmail_message_id: id,
      subject: get_header(headers, "Subject"),
      from_email: parse_from_email(get_header(headers, "From")),
      from_name: parse_from_name(get_header(headers, "From")),
      body_text: get_body_text(payload),
      body_html: get_body_html(payload),
      received_at: parse_date(get_header(headers, "Date")),
      unsubscribe_link: get_header(headers, "List-Unsubscribe")
    }
  end

  defp get_header(headers, name) do
    case Enum.find(headers, fn %{"name" => n} -> String.downcase(n) == String.downcase(name) end) do
      %{"value" => value} -> value
      _ -> nil
    end
  end

  defp parse_from_email(from) when is_binary(from) do
    case Regex.run(~r/<(.+?)>/, from) do
      [_, email] -> email
      _ -> from
    end
  end
  defp parse_from_email(_), do: nil

  defp parse_from_name(from) when is_binary(from) do
    case Regex.run(~r/^(.+?)\s*</, from) do
      [_, name] -> String.trim(name, "\"")
      _ -> nil
    end
  end
  defp parse_from_name(_), do: nil

  defp get_body_text(%{"parts" => parts}) do
    find_part_by_mime_type(parts, "text/plain")
  end
  defp get_body_text(%{"body" => %{"data" => data}}) do
    decode_body(data)
  end
  defp get_body_text(_), do: nil

  defp get_body_html(%{"parts" => parts}) do
    find_part_by_mime_type(parts, "text/html")
  end
  defp get_body_html(_), do: nil

  defp find_part_by_mime_type(parts, mime_type) do
    Enum.find_value(parts, fn part ->
      cond do
        Map.get(part, "mimeType") == mime_type ->
          part |> Map.get("body") |> Map.get("data") |> decode_body()

        Map.has_key?(part, "parts") ->
          find_part_by_mime_type(Map.get(part, "parts"), mime_type)

        true ->
          nil
      end
    end)
  end

  defp decode_body(nil), do: nil
  defp decode_body(data) do
    data
    |> String.replace("-", "+")
    |> String.replace("_", "/")
    |> Base.decode64!(padding: false)
  end

  defp parse_date(nil), do: DateTime.utc_now()
  defp parse_date(date_string) do
    # This is a simplified parser - in production you'd want a more robust solution
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> datetime
      _ -> DateTime.utc_now()
    end
  end
end
