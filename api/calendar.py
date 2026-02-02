"""Calendar API operations."""

from datetime import datetime, timezone

from auth import get_calendar_service


def list_upcoming_events(user_email: str, max_results: int = 5) -> list[dict]:
    """
    List upcoming calendar events for a user.

    Args:
        user_email: The user to impersonate
        max_results: Maximum number of events to return

    Returns:
        List of event dictionaries with summary, start, and end times
    """
    service = get_calendar_service(user_email)

    now = datetime.now(timezone.utc).isoformat()

    events_result = service.events().list(
        calendarId="primary",
        timeMin=now,
        maxResults=max_results,
        singleEvents=True,
        orderBy="startTime",
    ).execute()

    events = events_result.get("items", [])

    return [
        {
            "id": event.get("id"),
            "summary": event.get("summary", "(No title)"),
            "start": event.get("start", {}).get("dateTime", event.get("start", {}).get("date")),
            "end": event.get("end", {}).get("dateTime", event.get("end", {}).get("date")),
        }
        for event in events
    ]
