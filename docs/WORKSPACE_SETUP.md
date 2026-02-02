# Google Workspace Setup Guide

This guide walks you through configuring domain-wide delegation in Google Workspace Admin Console to allow the Business Agent to access Calendar and Gmail on behalf of users in your domain.

## Prerequisites

- A Google Workspace domain (Business Starter, Standard, Plus, or Enterprise)
- Admin access to the Google Workspace Admin Console
- The service account Client ID: `116525101320077229188`

## Step-by-Step Setup

### Step 1: Access the Admin Console

1. Open your browser and go to **https://admin.google.com**
2. Sign in with your **Workspace administrator account**
   - This must be an account with Super Admin or equivalent privileges
   - Personal Gmail accounts (e.g., @gmail.com) won't work

![Admin Console Login](https://workspace.google.com/static/img/admin-console.png)

### Step 2: Navigate to API Controls

1. In the Admin Console, click the **hamburger menu** (☰) in the top-left
2. Navigate to: **Security** → **Access and data control** → **API controls**

Alternative path:
- Go directly to: `https://admin.google.com/ac/owl/domainwidedelegation`

### Step 3: Open Domain-Wide Delegation

1. Scroll down to the **Domain wide delegation** section
2. Click **MANAGE DOMAIN WIDE DELEGATION**

You'll see a list of any existing delegated clients (may be empty).

### Step 4: Add the Service Account

1. Click **Add new**
2. Fill in the form:

| Field | Value |
|-------|-------|
| **Client ID** | `116525101320077229188` |
| **OAuth scopes** | See below |

**OAuth Scopes** (copy this entire line):
```
https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/gmail.readonly
```

> **Important**: Enter scopes as a comma-separated list with NO spaces between them.

3. Click **AUTHORIZE**

### Step 5: Verify the Configuration

After authorizing, you should see the service account listed in the Domain wide delegation table:

| Client ID | Client Name | API Scopes |
|-----------|-------------|------------|
| 116525101320077229188 | business-agent-sa | calendar.readonly, gmail.readonly |

## Scope Reference

| Scope | Permission | Description |
|-------|------------|-------------|
| `calendar.readonly` | Read | View calendar events |
| `gmail.readonly` | Read | View email messages and metadata |

### Adding More Scopes Later

If you need to add write capabilities or additional APIs:

1. Return to Domain wide delegation
2. Click the **Edit** icon next to the Client ID
3. Add new scopes (comma-separated)
4. Click **AUTHORIZE**

Common additional scopes:
```
https://www.googleapis.com/auth/calendar              # Read/write calendar
https://www.googleapis.com/auth/gmail.send            # Send emails
https://www.googleapis.com/auth/gmail.modify          # Modify emails
https://www.googleapis.com/auth/drive.readonly        # Read Drive files
https://www.googleapis.com/auth/admin.directory.user.readonly  # List users
```

## Testing the Configuration

### 1. Set Up the Backend

```bash
cd /path/to/hello-workspace-agent

# Create .env file with your domain
echo "WORKSPACE_DOMAIN=yourdomain.com" > .env

# Set up Python environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Start the server
python server.py
```

### 2. Test the API

Replace `user@yourdomain.com` with an actual user in your Workspace domain:

```bash
# Health check
curl http://localhost:8000/health

# Get user summary (calendar + email)
curl "http://localhost:8000/api/hello?user=user@yourdomain.com"

# Get calendar events only
curl "http://localhost:8000/api/calendar/events?user=user@yourdomain.com"

# Get recent emails only
curl "http://localhost:8000/api/gmail/messages?user=user@yourdomain.com"
```

### Expected Successful Response

```json
{
  "user": "user@yourdomain.com",
  "greeting": "Hello User!",
  "summary": {
    "upcoming_events": 3,
    "unread_emails": 12
  },
  "events": [
    {
      "id": "abc123",
      "summary": "Team Meeting",
      "start": "2024-01-15T10:00:00-08:00",
      "end": "2024-01-15T11:00:00-08:00"
    }
  ]
}
```

## Troubleshooting

### Error: "Access denied" or 403 Forbidden

**Cause**: Domain-wide delegation not configured correctly.

**Solution**:
1. Verify the Client ID matches exactly: `116525101320077229188`
2. Check that scopes are comma-separated with no spaces
3. Wait 5-10 minutes for changes to propagate
4. Try authorizing again

### Error: "User not found" or "Invalid user"

**Cause**: The user email doesn't exist in your Workspace domain.

**Solution**:
1. Verify the user exists in Admin Console → Users
2. Check that WORKSPACE_DOMAIN in .env matches your domain
3. Use the full email address (user@yourdomain.com)

### Error: "Service account not authorized"

**Cause**: Missing scopes or delegation not enabled.

**Solution**:
1. Return to Admin Console → API controls → Domain wide delegation
2. Verify the service account is listed
3. Check that all required scopes are included
4. Click Edit and re-authorize if needed

### Error: "credentials.json not found"

**Cause**: Service account key file missing.

**Solution**:
1. Download the key from GCP Console:
   - Go to https://console.cloud.google.com
   - IAM & Admin → Service Accounts
   - Click on `business-agent-sa`
   - Keys → Add Key → Create new key → JSON
2. Save as `credentials.json` in the project root

### Changes Not Taking Effect

Domain-wide delegation changes can take up to 24 hours to propagate, though usually it's 5-15 minutes.

If issues persist:
1. Try a different user in the domain
2. Check Google Workspace service status: https://www.google.com/appsstatus
3. Review Admin Console audit logs for errors

## Security Considerations

### Principle of Least Privilege

Only grant the scopes you actually need. Start with read-only scopes and add write scopes only when necessary.

### Monitor Usage

1. In Admin Console, go to **Reports** → **Audit and investigation**
2. Filter by **Service account** to see API usage
3. Set up alerts for unusual activity

### Rotate Keys Regularly

1. Create a new key before deleting the old one
2. Update `credentials.json` in your application
3. Verify the application works with the new key
4. Delete the old key from GCP Console

### Limit Service Account Access

The service account can impersonate ANY user in the domain. In production:
- Consider using Organizational Units to limit scope
- Implement additional authorization in your application
- Log all impersonation requests

## Next Steps

Once domain-wide delegation is working:

1. **Test the Chrome Extension**
   - Load it in Chrome (chrome://extensions → Developer mode → Load unpacked)
   - Sign into Chrome with a Workspace account
   - Click the extension and connect

2. **Deploy to Production**
   - Deploy backend to Cloud Run or similar
   - Update Chrome extension with production URL
   - Consider Google Workspace Marketplace listing

3. **Add More Features**
   - Additional APIs (Drive, Admin SDK, etc.)
   - Write capabilities (create events, send emails)
   - Better error handling and logging
