# Debugging — Notifications & FCM

> ⚠️ **Security reminder**: Never paste real FCM tokens, passwords, cookies,
> or API keys into logs, chat, or bug reports. All examples below use
> placeholders.

---

## 1. FCM Token Registration

### Confirm token was obtained

Look for this log line in Android Studio / `flutter logs`:

```
[FCM] Token obtained: AbCdEfGhIj...aBcDeF
[FCM] Token sent to backend ✓
```

The token is masked (first 10 + last 6 characters only) in debug mode.
Full token is **never** printed.

### Confirm Backend received token

Check the Backend logs or database for a new row in `app_fcm_tokens`:

```
POST /fcm/register-token → 200 OK
```

If you see a 401 response, the request was made before authentication was ready.
Check that `FcmService.initialize()` is only called when `isAuthenticated == true`.

---

## 2. Alerts List

### Confirm list is fetched

```
[ALERTS API] GET /alerts/ status=all limit=50 offset=0
```

If this line is missing when the alerts screen opens, check that:
- `alertsProvider` is being watched (not just read).
- The user is authenticated.
- `AlertsNotifier.load()` is called in the constructor.

### Confirm filter change works

```
[ALERTS API] GET /alerts/ status=unread limit=50 offset=0
[ALERTS API] GET /alerts/ status=read   limit=50 offset=0
```

---

## 3. Unread Count

```
[ALERTS API] unread-count = 7
```

If the badge is not updating:
- Check the log for this line after login and after FCM message.
- Confirm `GET /alerts/unread-count` returns `{ "count": N }` (or just `N`).
- Confirm `unreadAlertsCountProvider` is watched in `MainShell`.

---

## 4. Mark Read

### Single alert

```
[ALERTS] Mark read id=1201
```

After opening an alert detail, this line should appear. Confirm with:

```
PATCH /alerts/1201/read → 200 OK
```

If the alert still shows as unread after navigating back and pulling to refresh,
the Backend mutation may have failed — check the 4xx/5xx response.

### Mark all read

```
[ALERTS] Mark all read
```

Confirm with:

```
PATCH /alerts/read-all → 200 OK
```

---

## 5. FCM Push Test

From the Backend, send a test push:

```
POST /alerts/test
Body: { "sendPush": true, "deviceId": 5, "type": "overspeed" }
```

Expected flow in Flutter logs:

```
[FCM] Foreground message received – type=overspeed  alertId=1201
[ALERTS] FCM alertId received=1201
[ALERTS API] unread-count = 8
[ALERTS API] GET /alerts/ status=all limit=50 offset=0
```

If the log shows:
```
[Notifications] Deduplication: FCM alertId=1201 already seen – refresh skipped.
```
→ The same `alertId` arrived twice in the same session (FCM + WebSocket).
This is expected behaviour — the deduplication prevented a double refresh.

---

## 6. Navigation from Push

### Background tap

After tapping a system notification from background:

```
[FCM] App opened from background notification – alertId=1201
[ALERTS] Opening pending alertId=1201
[ALERTS API] GET /alerts/1201
[ALERTS] Mark read id=1201
```

### Terminated tap

After tapping a notification that launched the app from terminated state:

```
[FCM] App launched from terminated notification – alertId=1201
```

If the user isn't yet authenticated, the navigation is deferred until after login:

```
[FCM] Notification tap → pending alertId=1201
... (login happens) ...
[ALERTS] Opening pending alertId=1201
```

---

## 7. Common Problems

### Problem: FcmService is never initialized

**Symptom**: No `[FCM] Initializing…` log after login.

**Cause**: `fcmAuthSyncProvider` is not watched in the app root.

**Fix**: Confirm `ref.watch(fcmAuthSyncProvider)` is called inside `ElmoApp.build`.

---

### Problem: Token reaches Backend but push never arrives

**Cause**: Mismatch between the Firebase project in `google-services.json`
and the project used by the Backend Firebase Admin SDK.

**Fix**: Confirm both use the same Firebase project ID and the same
`applicationId` / bundle ID.

---

### Problem: Duplicate alert appears in UI

**Symptom**: Same alert shows twice in the list after FCM + WebSocket fire.

**Note**: If both channels fire for the same `alertId`, the deduplication
set prevents a double refresh — but the list is fetched from Backend which
only has one record, so duplicates should not appear.

If duplicates are visible, the source is likely two distinct Backend records
with different IDs for the same underlying event. This is a Backend concern.

---

### Problem: Alert reverts to unread after refresh

**Symptom**: PATCH succeeds, but after pull-to-refresh the alert is unread again.

**Cause**: The Backend did not persist the read state (check `app_alerts` table).
In the old architecture, read state was local-only (SharedPreferences) and
would be lost on refresh — this is **fixed** in the current implementation.

**Fix**: Confirm `PATCH /alerts/:id/read` returns 200 and that `app_alerts.isRead`
is updated in the database.

---

### Problem: `/alerts` causes redirect

**Symptom**: The alerts list never loads; network logs show a 301/302 redirect.

**Fix**: Use `/alerts/` (with trailing slash) in all API calls.
The `AlertsRemoteDataSource` already uses `/alerts/` — verify no other
code path uses the shorter form.

---

### Problem: Old unread count persists after logout

**Symptom**: After logout and login as a different user, the badge still
shows the previous user's count.

**Fix**: Confirm `resetOnLogout()` is called in `alertsProvider.notifier`
and `notificationsProvider.notifier` when auth state becomes `isAuthenticated == false`.
Check `fcm_sync_provider` — the logout branch handles this.
