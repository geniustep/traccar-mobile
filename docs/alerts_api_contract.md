# Alerts API Contract — Flutter ↔ Backend

> All requests are authenticated via the same session / credentials used for
> the rest of the ELMOGPS API (Basic Auth header managed by `TraccarClient`).
> No additional Firebase Auth is needed.

> **Note on trailing slash**: Use `/alerts/` (with trailing slash) to avoid
> a server-side redirect from `/alerts` → `/alerts/`, which adds an extra
> round-trip and may strip headers or body on some HTTP clients.

---

## Base URL

```
https://api.elmogps.com
```

---

## 1. GET /alerts/

Fetch a paginated list of alerts for the authenticated user.

**When used**: On alerts screen open, tab switch, pull-to-refresh, and after FCM refresh.

### Query Parameters

| Param | Type | Default | Description |
|---|---|---|---|
| `status` | `all` \| `read` \| `unread` | `all` | Filter by read state |
| `limit` | integer | `50` | Max results per page |
| `offset` | integer | `0` | Pagination offset |
| `deviceId` | integer | — | Filter by vehicle/device |
| `type` | string | — | Filter by alert type |
| `severity` | string | — | Filter by severity level |
| `from` | ISO 8601 UTC | — | Start of time range |
| `to` | ISO 8601 UTC | — | End of time range |

### Response — 200 OK

```json
[
  {
    "id":        1201,
    "deviceId":  5,
    "type":      "overspeed",
    "severity":  "warning",
    "title":     "Excès de vitesse",
    "message":   "Le véhicule a dépassé la limite autorisée",
    "eventTime": "2026-05-11T20:30:00.000Z",
    "isRead":    false,
    "readAt":    null,
    "metadata":  {}
  }
]
```

> The response may also be wrapped: `{ "data": [...], "total": 100 }`.
> The Flutter datasource handles both shapes transparently.

---

## 2. GET /alerts/unread-count

Returns the number of unread alerts for the authenticated user.

**When used**: After login, after FCM message, after mark-read, after mark-all-read,
on app foreground resume.

### Response — 200 OK

```json
{ "count": 7 }
```

---

## 3. GET /alerts/:id

Fetch the full details of a single alert.

**When used**: When opening `AlertDetailScreen` (from list tap or FCM navigation).

### Path Parameter

| Param | Type | Description |
|---|---|---|
| `id` | integer | Backend alert ID from `app_alerts` |

### Response — 200 OK

```json
{
  "id":        1201,
  "deviceId":  5,
  "type":      "overspeed",
  "severity":  "warning",
  "title":     "Excès de vitesse",
  "message":   "Le véhicule a dépassé la limite autorisée",
  "eventTime": "2026-05-11T20:30:00.000Z",
  "isRead":    true,
  "readAt":    "2026-05-11T20:35:00.000Z",
  "metadata":  {
    "vehicleName": "Camion 01",
    "speedKmh":    112,
    "limitKmh":    90
  }
}
```

### Response — 404 Not Found

```json
{ "error": "Alert not found" }
```

---

## 4. PATCH /alerts/:id/read

Mark a single alert as read.

**When used**: Automatically when `AlertDetailScreen` opens (fire-and-forget).

### Path Parameter

| Param | Type | Description |
|---|---|---|
| `id` | integer | Backend alert ID |

### Request Body

None required.

### Response — 200 OK

```json
{ "success": true }
```

---

## 5. PATCH /alerts/read-all

Mark all unread alerts as read (optionally filtered to those before a timestamp).

**When used**: When the user taps "Tout marquer comme lu".

### Request Body (optional)

```json
{ "before": "2026-05-11T21:00:00.000Z" }
```

If `before` is omitted, all unread alerts for the user are marked read.

### Response — 200 OK

```json
{ "updated": 12 }
```

---

## 6. POST /fcm/register-token

Register or refresh the device FCM push token after login.

**When used**: Immediately after FCM token is obtained in `FcmService.initialize()`,
and again on `onTokenRefresh`.

### Request Body

```json
{
  "token":      "<fcm_token_masked>",
  "platform":   "android",
  "appVersion": "1.2.3"
}
```

> ⚠️ Never log the full token. The `FcmService` logs only a masked version
> (first 10 + last 6 characters) in debug mode.

### Response — 200 OK

```json
{ "registered": true }
```

---

## 7. DELETE /fcm/token

Remove the device FCM token on logout, preventing push delivery to
a logged-out session.

**Status**: **TODO** — endpoint not yet implemented on Backend.

Once available, this should be called in `fcm_sync_provider` before
`FcmService.reset()` on logout.

### Request Body

```json
{ "token": "<fcm_token_masked>" }
```

### Response — 200 OK

```json
{ "removed": true }
```

---

## Error Handling Summary

| HTTP Status | Flutter Behaviour |
|---|---|
| `200` | Success — update state |
| `401` | Session expired → redirect to login |
| `404` | Alert not found → show "Alerte introuvable" message |
| `4xx` | Show generic error with retry |
| `5xx` | Show generic server error with retry |
| Network error | Show offline banner with retry |

All HTTP calls go through `TraccarClient` which converts `DioException`
to `AppException` before reaching the UI layer.
