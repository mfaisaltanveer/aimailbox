# AI Mailbox - Setup Guide

## Overview
AI Mailbox is a Phoenix LiveView application that automatically categorizes and summarizes your emails using AI. It connects to Gmail, imports emails, categorizes them using OpenAI GPT-4, and provides bulk actions like delete and unsubscribe.

## Prerequisites
- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 16+ (for assets)
- Google Cloud Platform account (for OAuth)
- OpenAI API account

## Setup Instructions

### 1. Install Dependencies
```bash
mix deps.get
cd assets && npm install && cd ..
```

### 2. Configure Environment Variables

Copy the example environment file:
```bash
cp .env.example .env
```

Then edit `.env` with your credentials:

#### Google OAuth Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Gmail API:
   - Go to "APIs & Services" > "Library"
   - Search for "Gmail API" and enable it
4. Create OAuth credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Application type: Web application
   - Authorized redirect URIs: `http://localhost:4000/auth/google/callback`
   - Copy the Client ID and Client Secret to your `.env` file
5. Configure OAuth consent screen:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Choose "External" (for testing)
   - Add your Gmail as a test user
   - Add the following scopes:
     - `userinfo.email`
     - `userinfo.profile`
     - `https://www.googleapis.com/auth/gmail.modify`

#### OpenAI API Setup
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Create an account or sign in
3. Navigate to [API Keys](https://platform.openai.com/api-keys)
4. Create a new API key
5. Copy it to your `.env` file as `OPENAI_API_KEY`

#### Generate Encryption Key
```bash
mix phx.gen.secret 32 | base64
```
Copy the output to your `.env` file as `CLOAK_KEY`

### 3. Load Environment Variables
```bash
source .env
export $(cat .env | xargs)
```

Or use a tool like `direnv`:
```bash
# Install direnv first
echo 'source .env' > .envrc
direnv allow
```

### 4. Setup Database
```bash
mix ecto.create
mix ecto.migrate
```

### 5. Start the Application
```bash
mix phx.server
```

Visit `http://localhost:4000` in your browser.

## Usage

### Getting Started
1. Click "Sign in with Google" on the homepage
2. Authorize the app to access your Gmail
3. You'll be redirected to the dashboard

### Create Categories
1. Click "+ Add Category" on the dashboard
2. Give it a name (e.g., "Newsletters")
3. Provide a description that helps AI identify emails:
   - Good: "Email newsletters from blogs, news sites, and subscription services about technology and business"
   - Bad: "Newsletters"
4. Click "Create Category"

### Import Emails
1. Your primary Gmail account is automatically added
2. To add more accounts, click "+ Add" under Gmail Accounts
3. Click "Sync" on any account to import recent emails
4. Emails will be:
   - Automatically categorized using AI based on your category descriptions
   - Summarized by AI
   - Archived in Gmail (moved out of inbox)

### Manage Emails
1. Click on any category to see its emails
2. Each email shows an AI-generated summary
3. Select emails (or "Select All") to perform bulk actions:
   - **Delete**: Permanently delete selected emails from the app
   - **Unsubscribe**: AI will simulate the unsubscribe process for emails with unsubscribe links

### View Email Details
1. Click on any email to see:
   - AI Summary
   - Plain text content
   - HTML content (if available)
   - Unsubscribe link (if available)

## Important Notes

### Google OAuth - Testing Mode
Since this app requests Gmail scopes, it needs to go through Google's security review to be publicly available. For development/testing:
- The app is in "Testing" mode
- Only users added as "Test Users" in the OAuth consent screen can sign in
- Add your Gmail address as a test user in Google Cloud Console

### Email Archiving
- When emails are imported, they are automatically ARCHIVED (not deleted) in Gmail
- They move out of your inbox but remain in "All Mail"
- You can still access them in Gmail if needed

### AI Limitations
- The AI categorization depends on your category descriptions - be specific!
- Unsubscribe feature is a simulation - it generates instructions but doesn't automatically unsubscribe
- OpenAI API costs apply based on usage

### Background Jobs
- Email importing runs as a background job (via Oban)
- Check the Oban dashboard at `/dev/dashboard` in development
- Jobs are processed asynchronously

## Troubleshooting

### "Failed to authenticate with Google"
- Check that your Google Client ID and Secret are correct
- Verify the redirect URI is exactly `http://localhost:4000/auth/google/callback`
- Make sure you're added as a test user in Google Cloud Console

### "Failed to fetch emails"
- The access token may have expired - try signing out and back in
- Check that Gmail API is enabled in Google Cloud Console

### OpenAI Errors
- Verify your API key is correct and has credits available
- Check the OpenAI dashboard for rate limits or quota issues

### Database Issues
- Make sure PostgreSQL is running
- Check database credentials in your `.env`
- Try `mix ecto.reset` to recreate the database

## Development

### Run Tests
```bash
mix test
```

### Generate Encryption Key
```bash
mix phx.gen.secret 32
```

### Reset Database
```bash
mix ecto.reset
```

### Access Live Dashboard
Visit `http://localhost:4000/dev/dashboard` to see:
- Oban job status
- Application metrics
- Request information

## Architecture

### Tech Stack
- **Framework**: Phoenix LiveView 1.0
- **Database**: PostgreSQL with Ecto
- **Background Jobs**: Oban
- **OAuth**: Ueberauth + ueberauth_google
- **HTTP Client**: Req
- **Encryption**: Cloak
- **AI**: OpenAI GPT-4 API
- **Gmail**: Google Gmail API

### Key Components
- `Accounts` - User management and OAuth
- `EmailsContext` - Email, category, and Gmail account management
- `Gmail.Client` - Gmail API integration
- `AI.OpenAIClient` - OpenAI integration for categorization and summarization
- `Workers.EmailImporter` - Background job for importing emails

## License
MIT
