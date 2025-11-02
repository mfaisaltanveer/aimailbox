# Aimailbox

AI-powered email sorting and management application built with Phoenix LiveView.

## Features

- Google OAuth authentication with Gmail integration
- AI-powered email categorization using custom categories
- AI email summarization
- Support for multiple Gmail accounts
- Automatic email archiving
- Bulk actions (delete, unsubscribe)
- Background job processing with Oban

## Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+
- Google OAuth credentials
- OpenAI API key

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/mfaisaltanveer/aimailbox.git
   cd aimailbox
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Set up environment variables**

   Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

   Then edit `.env` and add your credentials:
   - `GOOGLE_CLIENT_ID` - Get from [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - `GOOGLE_CLIENT_SECRET` - Get from Google Cloud Console
   - `OPENAI_API_KEY` - Get from [OpenAI Platform](https://platform.openai.com/api-keys)
   - `CLOAK_KEY` - Generate with: `echo -n $(mix phx.gen.secret 32) | base64`

4. **Set up the database**
   ```bash
   # Load environment variables and run setup
   export $(cat .env | xargs) && mix ecto.setup
   ```

5. **Start the Phoenix server**

   Option A - Using the helper script:
   ```bash
   ./load_env.sh mix phx.server
   ```

   Option B - Manual export:
   ```bash
   export $(cat .env | xargs) && mix phx.server
   ```

   Option C - Using iex:
   ```bash
   export $(cat .env | xargs) && iex -S mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

See [DEPLOY.md](DEPLOY.md) for detailed deployment instructions for Render.

## Running Tests

```bash
mix test
```

## Learn More

- Official Phoenix website: https://www.phoenixframework.org/
- Phoenix Guides: https://hexdocs.pm/phoenix/overview.html
- Phoenix Docs: https://hexdocs.pm/phoenix
- Elixir Forum: https://elixirforum.com/c/phoenix-forum
