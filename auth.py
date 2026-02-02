"""
Service account authentication with domain-wide delegation.

This module handles impersonating users in the Workspace domain.
"""

from google.oauth2 import service_account
from googleapiclient.discovery import build

from config import SERVICE_ACCOUNT_FILE, SCOPES


def get_impersonated_credentials(user_email: str):
    """
    Create credentials that impersonate a specific user.

    Args:
        user_email: The email of the user to impersonate (e.g., alice@yourdomain.com)

    Returns:
        Credentials object that can be used to make API calls as that user
    """
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=SCOPES,
    )

    # Impersonate the user via domain-wide delegation
    delegated_credentials = credentials.with_subject(user_email)

    return delegated_credentials


def get_calendar_service(user_email: str):
    """Get a Calendar API service for the specified user."""
    credentials = get_impersonated_credentials(user_email)
    return build("calendar", "v3", credentials=credentials)


def get_gmail_service(user_email: str):
    """Get a Gmail API service for the specified user."""
    credentials = get_impersonated_credentials(user_email)
    return build("gmail", "v1", credentials=credentials)
