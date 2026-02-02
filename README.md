# Workspace Business Agent - Hello World

A proof-of-concept demonstrating Google Workspace integration with domain-wide delegation.

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Project context and current status
- **[docs/WORKSPACE_SETUP.md](docs/WORKSPACE_SETUP.md)** - Detailed Google Workspace configuration guide

## Architecture

```
Chrome Extension  →  Python Backend  →  Google Workspace APIs
      ↓                    ↓                    ↓
  Get user email    Impersonate user     Calendar, Gmail
```

## Setup

### 1. Get a Test Workspace Domain

1. Go to https://workspace.google.com/
2. Start a free trial (14 days)
3. Create 1-2 test users

### 2. Create GCP Project

1. Go to https://console.cloud.google.com/
2. Create new project: "business-agent-dev"
3. Enable APIs:
   - Google Calendar API
   - Gmail API

### 3. Create Service Account

1. Go to IAM & Admin → Service Accounts
2. Create service account: "business-agent-sa"
3. Click on the service account → Keys → Add Key → JSON
4. Download and save as `credentials.json` in this directory
5. Copy the **Client ID** (numeric) - you'll need it

### 4. Enable Domain-Wide Delegation

1. Edit the service account
2. Check "Enable Google Workspace Domain-wide Delegation"
3. Save

### 5. Configure Workspace Admin Console

1. Go to https://admin.google.com/
2. Security → Access and data control → API controls
3. Click "Manage Domain Wide Delegation"
4. Add new:
   - **Client ID**: (paste the numeric ID from step 3)
   - **OAuth Scopes**:
     ```
     https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/gmail.readonly
     ```

### 6. Configure Backend

```bash
cp .env.example .env
```

Edit `.env`:
```
SERVICE_ACCOUNT_FILE=credentials.json
WORKSPACE_DOMAIN=yourdomain.com
```

### 7. Run Backend

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python server.py
```

Test it:
```bash
curl "http://localhost:8000/api/hello?user=alice@yourdomain.com"
```

### 8. Install Chrome Extension

1. Create icon files (16x16, 48x48, 128x128 PNG) in `chrome-extension/`
   - Or use any placeholder images named `icon16.png`, `icon48.png`, `icon128.png`
2. Go to `chrome://extensions/`
3. Enable "Developer mode"
4. Click "Load unpacked"
5. Select the `chrome-extension` folder

### 9. Test End-to-End

1. Make sure you're signed into Chrome with a Workspace account
2. Click the extension icon
3. Enter backend URL: `http://localhost:8000`
4. Click "Connect"
5. See your calendar events and unread email count

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check |
| `GET /api/hello?user=email` | Combined summary (for extension) |
| `GET /api/calendar/events?user=email` | List upcoming events |
| `GET /api/gmail/messages?user=email` | List recent messages |

## Next Steps

- [ ] Add Marketplace submission for clean install
- [ ] Add Chrome Web Store submission
- [ ] Add more Workspace APIs (Drive, Admin SDK)
- [ ] Add proper error handling and logging
- [ ] Add authentication between extension and backend
