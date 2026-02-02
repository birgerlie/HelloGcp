import os
from dotenv import load_dotenv

load_dotenv()

# Path to your service account JSON key
SERVICE_ACCOUNT_FILE = os.getenv("SERVICE_ACCOUNT_FILE", "credentials.json")

# Your Workspace domain (e.g., "yourdomain.com")
WORKSPACE_DOMAIN = os.getenv("WORKSPACE_DOMAIN", "")

# Scopes for domain-wide delegation
SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/gmail.readonly",
]
