"""Gmail API operations."""

from auth import get_gmail_service


def list_recent_messages(user_email: str, max_results: int = 5) -> list[dict]:
    """
    List recent email messages for a user.

    Args:
        user_email: The user to impersonate
        max_results: Maximum number of messages to return

    Returns:
        List of message dictionaries with id, subject, from, and snippet
    """
    service = get_gmail_service(user_email)

    # List message IDs
    results = service.users().messages().list(
        userId="me",
        maxResults=max_results,
        labelIds=["INBOX"],
    ).execute()

    messages = results.get("messages", [])

    detailed_messages = []
    for msg in messages:
        # Get full message details
        full_msg = service.users().messages().get(
            userId="me",
            id=msg["id"],
            format="metadata",
            metadataHeaders=["Subject", "From"],
        ).execute()

        headers = {h["name"]: h["value"] for h in full_msg.get("payload", {}).get("headers", [])}

        detailed_messages.append({
            "id": msg["id"],
            "subject": headers.get("Subject", "(No subject)"),
            "from": headers.get("From", "Unknown"),
            "snippet": full_msg.get("snippet", ""),
        })

    return detailed_messages


def get_unread_count(user_email: str) -> int:
    """Get the count of unread messages in inbox."""
    service = get_gmail_service(user_email)

    results = service.users().messages().list(
        userId="me",
        labelIds=["INBOX", "UNREAD"],
        maxResults=1,
    ).execute()

    return results.get("resultSizeEstimate", 0)
