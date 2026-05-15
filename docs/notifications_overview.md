# Notifications System — Overview

## Architecture Principle

**Backend is the single source of truth.**

The ELMOGPS Flutter app does **not** maintain its own authoritative list of alerts.
All alert data — including read/unread state — is owned and persisted by the Backend
inside the `app_alerts` table.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA FLOW                                    │
│                                                                     │
│  Backend (app_alerts)                                               │
│       │                                                             │
│       ├─── GET /alerts/ ──────────────────► Alerts Screen (list)   │
│       │                                                             │
│       ├─── GET /alerts/unread-count ──────► Badge (bottom nav)     │
│       │                                                             │
│       ├─── GET /alerts/:id ─────────────── Alert Detail Screen     │
│       │                                                             │
│       ├─── PATCH /alerts/:id/read ────────► Mark single read       │
│       │                                                             │
│       └─── PATCH /alerts/read-all ───────► Mark all read           │
│                                                                     │
│  Firebase (FCM)                                                     │
│       │                                                             │
│       └─── Push { alertId } ────────────► refreshFromFcm()         │
│                                           └─ GET /alerts/unread-count
│                                           └─ reload list if on screen
│                                           └─ navigate to /alerts/:id
│                                              (on tap)              │
│  WebSocket                                                          │
│       │                                                             │
│       └─── event signal ────────────────► refreshUnreadCount()     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## What Each Channel Does

### Backend `/alerts/` API
- **Source of truth** for all alert content, ordering, and read/unread state.
- Flutter reads from it on screen open, pull-to-refresh, and after mutations.
- Filters: `all` | `read` | `unread` via `?status=` query param.

### Firebase Cloud Messaging (FCM)
- **Push delivery channel only.**
- Delivers a small payload containing `alertId` and metadata.
- The app does **not** create an alert object from the FCM payload.
- The app uses `alertId` to:
  - Refresh `GET /alerts/unread-count` (badge update).
  - Reload the alerts list if the screen is visible.
  - Navigate to `GET /alerts/:id` when the user taps the notification.

### WebSocket
- **Real-time signal only** — not the source of truth.
- Used to trigger a lightweight `unread-count` refresh when a new event arrives.
- Never used to build or populate the alert list independently.

---

## What Does NOT Happen

| ❌ Forbidden | Reason |
|---|---|
| Create alert object from FCM data | FCM payload is a hint, not the record |
| Store read/unread in SharedPreferences as final state | Would de-sync from Backend after reinstall or multi-device |
| Use WebSocket event as the alert list | Transient, not persistent |
| Use `reports/events` (legacy) as alert list | Replaced by `/alerts/` |
| Display Traccar internal names in UI | User-facing labels come from Backend |

---

## Screen Hierarchy

```
Bottom Nav (badge = unread-count)
    │
    └─ /alerts  → AlertsScreen
         ├── Tab: Toutes      (GET /alerts/?status=all)
         ├── Tab: Non lues    (GET /alerts/?status=unread)
         └── Tab: Lues        (GET /alerts/?status=read)
              └─ tap item ──► /alerts/:id  → AlertDetailScreen
                                               └─ GET /alerts/:id
                                               └─ PATCH /alerts/:id/read
```

---

## Key Files

| File | Role |
|---|---|
| `lib/features/alerts/data/datasources/alerts_remote_datasource.dart` | HTTP calls to `/alerts/` endpoints |
| `lib/features/alerts/data/repositories/alerts_repository_impl.dart` | Repository layer |
| `lib/features/alerts/presentation/providers/alerts_provider.dart` | Riverpod state (`AlertsState`) |
| `lib/features/alerts/presentation/screens/alerts_screen.dart` | 3-tab list UI |
| `lib/features/alerts/presentation/screens/alert_detail_screen.dart` | Single alert view + auto mark-read |
| `lib/features/notifications/services/fcm_service.dart` | Raw FCM setup (permission, token, listeners) |
| `lib/features/notifications/services/fcm_sync_provider.dart` | Auth-bound FCM lifecycle + logout cleanup |
| `lib/features/notifications/presentation/providers/notifications_provider.dart` | Deduplication + FCM→refresh bridge |

---

## Related Documentation

- [Firebase FCM Setup](./firebase_fcm_flutter.md)
- [API Contract](./alerts_api_contract.md)
- [State Management](./alerts_state_management.md)
- [UI / UX](./alerts_ui_ux.md)
- [Foreground / Background Push](./foreground_background_push.md)
- [Debugging](./debugging_notifications.md)
- [Production Checklist](./production_checklist.md)
