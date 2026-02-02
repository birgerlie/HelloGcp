// Get DOM elements
const contentDiv = document.getElementById('content');
const connectBtn = document.getElementById('connectBtn');
const apiUrlInput = document.getElementById('apiUrl');

// Load saved API URL
chrome.storage?.local?.get(['apiUrl'], (result) => {
  if (result.apiUrl) {
    apiUrlInput.value = result.apiUrl;
  } else {
    apiUrlInput.value = 'http://localhost:8000';
  }
});

// Save API URL when changed
apiUrlInput.addEventListener('change', () => {
  chrome.storage?.local?.set({ apiUrl: apiUrlInput.value });
});

// Connect button handler
connectBtn.addEventListener('click', async () => {
  contentDiv.innerHTML = '<p class="loading">Connecting...</p>';

  try {
    // Get the user's email from Chrome identity
    const userInfo = await new Promise((resolve, reject) => {
      chrome.identity.getProfileUserInfo({ accountStatus: 'ANY' }, (info) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
        } else if (!info.email) {
          reject(new Error('No user signed in to Chrome'));
        } else {
          resolve(info);
        }
      });
    });

    const userEmail = userInfo.email;
    const apiUrl = apiUrlInput.value.replace(/\/$/, '');

    // Call the backend
    const response = await fetch(`${apiUrl}/api/hello?user=${encodeURIComponent(userEmail)}`);

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'API request failed');
    }

    const data = await response.json();

    // Render the response
    renderSummary(data);

  } catch (error) {
    contentDiv.innerHTML = `<p class="error">${error.message}</p>`;
  }
});

function renderSummary(data) {
  const eventsHtml = data.events.map(event => `
    <div class="event">
      <div class="event-title">${escapeHtml(event.summary)}</div>
      <div class="event-time">${formatTime(event.start)}</div>
    </div>
  `).join('');

  contentDiv.innerHTML = `
    <div class="greeting">${escapeHtml(data.greeting)}</div>

    <div class="summary">
      <div class="stat">
        <div class="stat-number">${data.summary.upcoming_events}</div>
        <div class="stat-label">Meetings</div>
      </div>
      <div class="stat">
        <div class="stat-number">${data.summary.unread_emails}</div>
        <div class="stat-label">Unread</div>
      </div>
    </div>

    <div class="events">
      <strong>Upcoming:</strong>
      ${eventsHtml || '<p>No upcoming events</p>'}
    </div>
  `;
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function formatTime(isoString) {
  if (!isoString) return '';
  const date = new Date(isoString);
  return date.toLocaleString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}
