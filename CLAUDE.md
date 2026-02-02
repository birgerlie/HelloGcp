# CLAUDE.md - Project Context for Claude Code

## Project Overview

This is a **Google Workspace Business Agent** proof-of-concept. The goal is to build an agent that can access Google Workspace data (Calendar, Gmail) on behalf of users in a Workspace domain using domain-wide delegation.

## Architecture

```
┌─────────────────────┐       ┌─────────────────────┐       ┌──────────────────┐
│  Chrome Extension   │ ───→  │   Python Backend    │ ───→  │  Google APIs     │
│  (User Interface)   │ HTTP  │   (FastAPI)         │       │  (Calendar,      │
│                     │       │                     │       │   Gmail)         │
│  - Gets user email  │       │  - Service Account  │       │                  │
│  - Displays summary │       │  - Impersonates     │       │                  │
│                     │       │    users            │       │                  │
└─────────────────────┘       └─────────────────────┘       └──────────────────┘
```

## Current Status

### Completed

| Component | Details | Status |
|-----------|---------|--------|
| GCP Project | `workspace-agent-dev` (ID: 97703644199) | ✅ Done |
| Calendar API | Enabled in GCP | ✅ Done |
| Gmail API | Enabled in GCP | ✅ Done |
| Service Account | `business-agent-sa@workspace-agent-dev.iam.gserviceaccount.com` | ✅ Done |
| Service Account Key | `credentials.json` (downloaded, in .gitignore) | ✅ Done |
| Client ID | `116525101320077229188` | ✅ Done |
| Python Backend | FastAPI server with Calendar/Gmail endpoints | ✅ Done |
| Chrome Extension | Manifest V3, popup UI | ✅ Done |
| GitHub Repo | https://github.com/birgerlie/HelloGcp | ✅ Done |

### Not Yet Completed

| Task | Details | Status |
|------|---------|--------|
| Domain-wide Delegation | Must be configured in Workspace Admin Console | ❌ Pending |
| .env Configuration | Need to set WORKSPACE_DOMAIN | ❌ Pending |
| End-to-end Test | Run server, test with real user | ❌ Pending |

## What Needs to Happen Next

### 1. Configure Domain-Wide Delegation (Manual - requires Workspace Admin)

The service account needs to be granted domain-wide delegation in the Google Workspace Admin Console. This allows it to impersonate users in the domain.

**Steps:**
1. Go to https://admin.google.com
2. Sign in with a **Workspace admin account** (not personal Gmail)
3. Navigate to: **Security → Access and data control → API controls**
4. Click **Manage Domain Wide Delegation**
5. Click **Add new**
6. Enter:
   - **Client ID**: `116525101320077229188`
   - **OAuth scopes** (comma-separated, no spaces):
     ```
     https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/gmail.readonly
     ```
7. Click **Authorize**

### 2. Configure Environment

```bash
cd /Users/birger/code/HelloGcp/hello-workspace-agent
cp .env.example .env
# Edit .env and set:
# WORKSPACE_DOMAIN=yourdomain.com
```

### 3. Test the Backend

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run server
python server.py

# Test endpoint (replace with actual user in your domain)
curl "http://localhost:8000/api/hello?user=someuser@yourdomain.com"
```

Expected response:
```json
{
  "user": "someuser@yourdomain.com",
  "greeting": "Hello Someuser!",
  "summary": {
    "upcoming_events": 3,
    "unread_emails": 12
  },
  "events": [...]
}
```

### 4. Test the Chrome Extension

1. Go to `chrome://extensions/`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `chrome-extension/` folder
5. Click the extension icon
6. Enter backend URL: `http://localhost:8000`
7. Click "Connect"

## File Structure

```
hello-workspace-agent/
├── CLAUDE.md              # This file - project context
├── README.md              # Setup instructions
├── credentials.json       # Service account key (DO NOT COMMIT)
├── .env                   # Environment config (DO NOT COMMIT)
├── .env.example           # Template for .env
├── .gitignore
├── requirements.txt       # Python dependencies
├── config.py              # Configuration loader
├── auth.py                # Service account impersonation
├── server.py              # FastAPI server
├── api/
│   ├── __init__.py
│   ├── calendar.py        # Calendar API calls
│   └── gmail.py           # Gmail API calls
└── chrome-extension/
    ├── manifest.json      # Chrome extension manifest (V3)
    ├── popup.html         # Extension popup UI
    ├── popup.js           # Extension logic
    └── icon*.png          # Extension icons
```

## Key Concepts

### Domain-Wide Delegation
- Allows a service account to impersonate any user in a Workspace domain
- Must be configured by a Workspace admin in the Admin Console
- The service account uses `credentials.with_subject(user_email)` to impersonate

### Service Account vs OAuth
- **OAuth**: Each user consents individually (good for consumer apps)
- **Service Account + Domain-Wide Delegation**: Admin consents once for entire domain (good for enterprise/business apps)

### Scopes
Currently using read-only scopes:
- `https://www.googleapis.com/auth/calendar.readonly` - Read calendar events
- `https://www.googleapis.com/auth/gmail.readonly` - Read emails

To add write capabilities later, would need additional scopes and re-authorization in Admin Console.

## Future Enhancements (Phase 2+)

- [ ] Add Google Workspace Marketplace listing for cleaner onboarding
- [ ] Add Chrome Web Store listing for extension distribution
- [ ] Add more Workspace APIs (Drive, Admin SDK, Docs)
- [ ] Add authentication between Chrome extension and backend
- [ ] Add proper error handling and logging
- [ ] Add write capabilities (create events, send emails)
- [ ] Deploy backend to Cloud Run or similar

## Troubleshooting

### "Access denied" or 403 errors
- Domain-wide delegation not configured, or wrong Client ID
- User email not in the configured WORKSPACE_DOMAIN
- Scopes not matching what's authorized in Admin Console

### "Service account not found"
- `credentials.json` missing or wrong path
- Check SERVICE_ACCOUNT_FILE in .env

### Chrome extension can't connect
- Backend not running on specified URL
- CORS issues (should be handled, but check browser console)
- User not signed into Chrome with a Workspace account
