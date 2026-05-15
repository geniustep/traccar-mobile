# Alerts — State Management

## Provider: `alertsProvider`

**Type**: `StateNotifierProvider<AlertsNotifier, AlertsState>`
**Auto-dispose**: No — survives tab navigation so filter and unreadCount persist.

---

## State Shape

```dart
class AlertsState {
  final AsyncValue<List<AlertEntity>> alertsAsync;  // loaded alert list
  final int     unreadCount;    // from GET /alerts/unread-count
  final String  statusFilter;   // 'all' | 'read' | 'unread'
  final bool    isLoadingMore;  // pagination in progress
  final int     offset;         // current pagination offset
  final bool    hasMore;        // whether more pages exist
}
```

### Derived Providers

| Provider | Source | Used by |
|---|---|---|
| `unreadAlertsCountProvider` | `alertsProvider.unreadCount` | `MainShell` bottom-nav badge |
| `alertDetailProvider(id)` | `GET /alerts/:id` (FutureProvider) | `AlertDetailScreen` |
| `vehicleAlertsProvider(id)` | `GET /alerts/?deviceId=id` | Vehicle detail screen |

---

## Lifecycle

### On Login

```
fcm_sync_provider detects isAuthenticated == true
  └─ FcmService.initialize()
        └─ POST /fcm/register-token
  └─ alertsProvider.notifier.refreshUnreadCount()
        └─ GET /alerts/unread-count  → unreadCount updated
```

### On Alerts Screen Open

```
AlertsScreen build()
  └─ ref.watch(alertsProvider)
        └─ AlertsNotifier constructor → load()
              └─ GET /alerts/?status=all&limit=50&offset=0
              └─ GET /alerts/unread-count
              └─ state = AlertsState(alertsAsync: data, unreadCount: N)
```

### On Tab Switch (filter change)

```
_tabController listener → setFilter('unread' | 'read' | 'all')
  └─ state.statusFilter = newFilter
  └─ load(resetOffset: true)
        └─ GET /alerts/?status=<filter>&limit=50&offset=0
```

### On Pull to Refresh

```
RefreshIndicator.onRefresh → load(resetOffset: true)
  └─ GET /alerts/?status=<currentFilter>&limit=50&offset=0
  └─ GET /alerts/unread-count
```

### On FCM Message (foreground)

```
fcm_sync_provider.onMessage(data)
  └─ notificationsProvider.notifier.addFcmEvent(data)
        └─ deduplication check on alertId
        └─ alertsProvider.notifier.refreshFromFcm(alertId)
              └─ GET /alerts/unread-count   → unreadCount updated
              └─ if statusFilter != 'read': load()  → list refreshed
```

### On WebSocket Event

```
socketProvider event
  └─ notificationsProvider.notifier.addLiveEventSignal(alertId)
        └─ deduplication check on alertId
        └─ alertsProvider.notifier.refreshUnreadCount()
              └─ GET /alerts/unread-count   → unreadCount updated
```

### On Mark Read (single)

```
AlertDetailScreen opens
  └─ GET /alerts/:id   (alertDetailProvider)
  └─ PATCH /alerts/:id/read  (fire-and-forget)
  └─ alertsProvider.notifier.markAlertReadById(id)
        └─ optimistic: item.isRead = true, item.readAt = now
        └─ unreadCount - 1
        └─ GET /alerts/unread-count  → confirms server count
```

### On Mark All Read

```
User taps "Tout marquer comme lu"
  └─ alertsProvider.notifier.markAllAsRead()
        └─ optimistic: all items.isRead = true
        └─ unreadCount = 0
        └─ PATCH /alerts/read-all
        └─ GET /alerts/unread-count  → confirms 0
```

### On Logout

```
fcm_sync_provider detects isAuthenticated == false
  └─ FcmService.reset()
  └─ alertsProvider.notifier.resetOnLogout()
        └─ state = AlertsState(alertsAsync: data([]), unreadCount: 0)
  └─ notificationsProvider.notifier.resetOnLogout()
        └─ _seenAlertIds.clear()
        └─ state = AsyncValue.data([])
  └─ pendingNotificationAlertIdProvider = null
```

No previous user's alerts are visible after logout.

---

## Pending Alert Navigation

When the user taps a push notification while the app is **not authenticated**
(cold start from terminated, or session expired):

```
FCM onMessageOpenedApp / getInitialMessage
  └─ pendingNotificationAlertIdProvider = alertId

FcmEventListener (always active in app tree)
  └─ listens to authProvider
  └─ when isAuthenticated becomes true:
        └─ context.go('/alerts/$alertId')
        └─ pendingNotificationAlertIdProvider = null
```

This ensures the user is never left on a blank screen — login happens first,
then navigation completes.

---

## Important: No Local SharedPreferences for Read State

Previous versions of the alerts feature used `SharedPreferences` to persist
read/unread IDs locally. **This is no longer used for the alerts list.**

Read/unread state is now authoritative on the Backend (`app_alerts.isRead`).
After a pull-to-refresh or app restart, the correct state is always fetched
from the server — no local cache can become stale.
