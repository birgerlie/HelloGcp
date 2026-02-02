"""
FastAPI server for the Workspace Business Agent.

Endpoints:
    GET /health - Health check
    GET /api/calendar/events?user=email - List upcoming events
    GET /api/gmail/messages?user=email - List recent messages
    GET /api/hello?user=email - Combined summary
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from api.calendar import list_upcoming_events
from api.gmail import list_recent_messages, get_unread_count
from config import WORKSPACE_DOMAIN

app = FastAPI(
    title="Workspace Business Agent",
    description="Hello World agent with Google Workspace integration",
    version="0.1.0",
)

# Allow Chrome extension to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Lock this down in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def validate_user(user_email: str) -> None:
    """Validate that the user belongs to our Workspace domain."""
    if not user_email:
        raise HTTPException(status_code=400, detail="user parameter required")

    if WORKSPACE_DOMAIN and not user_email.endswith(f"@{WORKSPACE_DOMAIN}"):
        raise HTTPException(
            status_code=403,
            detail=f"User must be in domain {WORKSPACE_DOMAIN}"
        )


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/api/calendar/events")
def get_calendar_events(user: str = Query(..., description="User email to impersonate")):
    """List upcoming calendar events for a user."""
    validate_user(user)

    try:
        events = list_upcoming_events(user, max_results=5)
        return {"user": user, "events": events}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/gmail/messages")
def get_gmail_messages(user: str = Query(..., description="User email to impersonate")):
    """List recent Gmail messages for a user."""
    validate_user(user)

    try:
        messages = list_recent_messages(user, max_results=5)
        return {"user": user, "messages": messages}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/hello")
def hello_summary(user: str = Query(..., description="User email to impersonate")):
    """
    Combined hello endpoint - returns calendar and email summary.
    This is what the Chrome extension will call.
    """
    validate_user(user)

    try:
        events = list_upcoming_events(user, max_results=3)
        unread = get_unread_count(user)

        # Build a friendly summary
        user_name = user.split("@")[0].title()
        event_count = len(events)

        return {
            "user": user,
            "greeting": f"Hello {user_name}!",
            "summary": {
                "upcoming_events": event_count,
                "unread_emails": unread,
            },
            "events": events,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
