# Foreground / Background / Terminated Push Behaviour

## Summary Table

| App State | User Action | Result |
|---|---|---|
| **Foreground** | Push arrives silently | Badge updates, list refreshes if on screen |
| **Background** | System notification shown | Tap → opens Alert Detail |
| **Terminated** | System notification shown | App launches → tap → opens Alert Detail |

---

## 1. Foreground Push

When the app is open and active, `FirebaseMessaging.onMessage` fires.

```
onMessage(data)
  └─ notificationsProvider.addFcmEvent(data)
        └─ deduplication check (see below)
        └─ alertsProvider.refreshFromFcm(alertId)
              └─ GET /alerts/unread-count   → badge updated instantly
              └─ if statusFilter != 'read':
                    load()  → list reloads from /alerts/
```

**No system notification popup is shown** in foreground by default on Android.
The update is silent — the badge increments and the list refreshes.

If an in-app banner is desired, it can be added to `onMessage` handler
(e.g. a `SnackBar` or `OverlayEntry`) — currently not implemented.

---

## 2. Background Push

When the app is running in the background, Android shows a system notification
using the title/body from the FCM payload.

When the user taps the notification, `FirebaseMessaging.onMessageOpenedApp` fires.

```
onMessageOpenedApp(data)
  └─ read alertId from data
  └─ pendingNotificationAlertIdProvider = alertId

FcmEventListener (always mounted in app tree)
  └─ listens to pendingNotificationAlertIdProvider
  └─ if auth.isAuthenticated && alertId != null:
        └─ context.go('/alerts/$alertId')
        └─ pendingNotificationAlertIdProvider = null

AlertDetailScreen
  └─ GET /alerts/:id
  └─ PATCH /alerts/:id/read (auto)
```

---

## 3. Terminated Push

When the app is fully closed, the system shows a notification.
Tapping it launches the app.

`FcmService.initialize()` calls `getInitialMessage()` once on startup:

```
getInitialMessage()
  └─ if message != null:
        └─ treated same as onMessageOpenedApp
        └─ pendingNotificationAlertIdProvider = alertId
```

If auth is not yet ready (cold start → splash → login):

```
FcmEventListener listens to authProvider
  └─ when isAuthenticated transitions to true:
        └─ reads pendingNotificationAlertIdProvider
        └─ if alertId != null: context.go('/alerts/$alertId')
```

This guarantees that even a user who wasn't logged in will be navigated to
the correct alert after completing login.

---

## 4. Deduplication

Both FCM and WebSocket can deliver signals for the same alert event.
To avoid the same `alertId` triggering two refreshes:

```dart
final Set<String> _seenAlertIds = {};

// In addFcmEvent():
if (_seenAlertIds.contains(alertId)) return; // skip
_seenAlertIds.add(alertId);
// proceed with refresh

// In addLiveEventSignal():
if (_seenAlertIds.contains(alertId)) return; // skip
_seenAlertIds.add(alertId);
// proceed with refreshUnreadCount
```

The set lives in `NotificationsNotifier` and is cleared on logout.

### What Deduplication Does NOT Do

Deduplication only prevents **duplicate refresh calls** for the same event
in a single session. It does **not** affect the Backend:

- `GET /alerts/` always returns the authoritative list — the same alert
  will appear in the list regardless of how many times FCM or WebSocket
  fired for it.
- If the user pulls to refresh, the full list is re-fetched cleanly.

---

## 5. Edge Cases

### Notification arrives while screen is loading

`refreshFromFcm` is safe to call at any time — it simply fetches
`unread-count` and conditionally reloads the list. If the list is
already loading, the subsequent load call will overwrite the state.

### Multiple notifications before app opens

`getInitialMessage()` only returns the **last** notification that launched
the app. If multiple notifications arrived while terminated, only the most
recent one triggers navigation. The full list is available via
`GET /alerts/?status=unread`.

### Auth expires while app is backgrounded

If the session expires while the app is in the background and a notification
arrives:
1. The user taps the notification.
2. The router redirects to `/login` (because `isAuthenticated == false`).
3. `pendingNotificationAlertIdProvider` holds the `alertId`.
4. After successful login, `FcmEventListener` navigates to `/alerts/:id`.

### Token invalidated by Firebase

`onTokenRefresh` re-registers the new token via `POST /fcm/register-token`
automatically. No user action required.
