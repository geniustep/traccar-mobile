# Alerts — UI / UX Guide

## Alerts Screen (`/alerts`)

### Tabs / Filters

The screen has three tabs backed by the same `alertsProvider` with different
`statusFilter` values:

| Tab Label | `statusFilter` | Shows |
|---|---|---|
| **Toutes** | `all` | All alerts regardless of read state |
| **Non lues** | `unread` | Only unread alerts |
| **Lues** | `read` | Only read (already seen) alerts |

Switching tabs triggers `setFilter()` on the notifier which reloads the list
from the Backend with the appropriate `?status=` query parameter.

### App Bar

- **Title**: "Alertes" (localized) + unread badge if `unreadCount > 0`.
- **Action button**: "✓✓ Tout marquer comme lu" — visible only when `unreadCount > 0`.
  Triggers `PATCH /alerts/read-all` and optimistically updates the UI.

### Unread Badge (bottom navigation)

The badge on the Alerts icon in the bottom navigation bar reflects
`unreadAlertsCountProvider`, which is sourced from
`GET /alerts/unread-count` via the Backend.

Updated:
- After login
- After FCM message arrives
- After WebSocket event
- After mark read (single or all)
- After pull-to-refresh

---

## Alert List Item

Each row in the list displays:

| Element | Source |
|---|---|
| **Icon** | Derived from `type` field (speed, fence, build, warning, etc.) |
| **Severity color strip** | Left accent bar colored by `severity` |
| **Title** | `alert.title` — human-readable text from Backend |
| **Message preview** | `alert.description` (`message` field from Backend), max 2 lines |
| **Vehicle name** | `alert.vehicleName` (from `metadata.vehicleName` if provided) |
| **Relative time** | `alert.createdAt` formatted as "il y a 5 min", "Just now", etc. |
| **"Non lue" chip** | Shown if `isRead == false` |
| **Unread dot** | Small red dot on the icon if `isRead == false` |
| **Severity badge** | Chip showing severity level |

### Severity Colors

| Value | Color |
|---|---|
| `critical` | Red (`severityCritical`) |
| `high` | Orange-red (`severityHigh`) |
| `medium` | Amber (`severityMedium`) |
| `low` | Blue-grey (`severityLow`) |
| `info` (default) | Accent blue |

### What Is NOT Displayed

- ❌ Raw `type` slug (e.g. `deviceOverspeed`, `geofenceExit`)
- ❌ `source_event_id` or any internal event reference
- ❌ Raw JSON or debug metadata
- ❌ Any name referencing internal tracking infrastructure
- ❌ Backend database IDs beyond what's needed for navigation

---

## States

### Loading State

Animated skeleton cards (shimmer effect) are shown while the first page
of alerts is being fetched.

### Empty State

Shown when the current filter returns zero results:

```
[Shield icon]
Aucune alerte
Vous êtes à jour.
```

(Localized via `l10n.noAlerts` / `l10n.noAlertsMessage`)

### Error State

Shown when the API call fails:

```
[Cloud-off icon]
Impossible de charger les alertes
Vérifiez votre connexion et réessayez.

[Réessayer button]
```

Tapping "Réessayer" calls `load()` on the notifier.

### Pull to Refresh

`RefreshIndicator` (accent color) triggers `load(resetOffset: true)`,
re-fetching both the alert list and unread count from the Backend.

---

## Alert Detail Screen (`/alerts/:id`)

Opened by:
- Tapping a row in the alerts list.
- Tapping a push notification (FCM `alertId` navigation).

### Data Source

Always fetches fresh data via `GET /alerts/:id` (`alertDetailProvider`).
Does **not** rely on the in-memory list from `alertsProvider`.

### Auto Mark-Read

When the detail screen opens for an **unread** alert:
1. `PATCH /alerts/:id/read` is called automatically (fire-and-forget).
2. The list item in `alertsProvider` is updated optimistically.
3. `unreadCount` is decremented optimistically and confirmed from Backend.

The user never needs to manually tap a "Mark as read" button for a newly
opened alert.

### Content Displayed

| Section | Fields |
|---|---|
| **Header card** | Severity badge, alert type label (human-readable), title, message |
| **Read status** | "Non lue" chip if still unread at render time |
| **Info card** | Vehicle name (tap → vehicle detail), event time, read time if available, coordinates if available |
| **Details card** | `metadata` key-value pairs (only shown if non-empty) |

### Content NOT Displayed

- ❌ `source_event_id`
- ❌ Raw type slug
- ❌ Raw JSON dump of `metadata`
- ❌ Internal infrastructure names
- ❌ Backend table names or database IDs in user-visible text

### Error States

| Scenario | Shown |
|---|---|
| `404` from Backend | "Alerte introuvable" — no retry button |
| Network error | "Impossible de charger l'alerte" + Retry button |
| Loading | `CircularProgressIndicator` centered |

---

## Localization Keys Used

| Key | Default (fr) |
|---|---|
| `l10n.navAlerts` | Alertes |
| `l10n.noAlerts` | Aucune alerte |
| `l10n.noAlertsMessage` | Vous êtes à jour. |
| `l10n.markAllRead` | Tout marquer comme lu |
| `l10n.alertDetail` | Détail de l'alerte |
| `l10n.alertNotFound` | Alerte introuvable |
| `l10n.vehicleLabel` | Véhicule |
| `l10n.timeLabel` | Heure |
| `l10n.locationLabel` | Localisation |
| `l10n.detailsLabel` | Détails |
| `l10n.geofenceZoneEntry` | Entrée de zone |
| `l10n.geofenceZoneExit` | Sortie de zone |
