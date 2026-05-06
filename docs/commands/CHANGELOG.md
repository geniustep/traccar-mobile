# Command System — Changelog

---

## v1.0.0 — Stable Release
**Date:** 2026-05-06  
**Status:** ✅ Approved & Merged

### Overview
Complete rewrite of the Traccar command system. Replaced the previous 2-tab,
static command list with a dynamic, role-aware, safety-enforced architecture.

---

### New Features

#### Architecture
- **`TraccarCommandMapping`** — Central mapping of every command to its Traccar
  API type, risk level, send method, required roles, and safety rules.
- **`CommandCapabilityService`** — Runtime resolver merging 5 sources of truth:
  UserRole, DeviceCommandProfile, Traccar API `/commands/types`, DeviceInstallationProfile,
  and device context (online state, speed).
- **`CommandValidationService`** — 6-step pre-execution validation pipeline with
  structured results (`ValidationPassed`, `ValidationFailed`, `ValidationNeedsConfirmation`).
- **`CommandExecutionService`** — Full dispatch lifecycle: validate → build payload
  → POST `/commands/send` → log result. Replaces old `DeviceCommandService`.
- **`DeviceInstallationService`** — SharedPreferences-backed persistence of
  per-device physical hardware flags.

#### Commands Catalog (44 commands, 6 categories)
| Category | Count | Notes |
|---|---|---|
| Device Information | 8 | All roles (Low/Medium risk) |
| Tracking | 6 | Operator+ (Medium risk) |
| Security & Alerts | 10 | Operator+ (Medium risk) |
| Vehicle Control | 10 | Technician/Admin only (HIGH risk) |
| Maintenance | 6 | Technician/Admin + Admin-only (High risk) |
| Advanced | 4 | Technician/Admin + Admin-only (High risk) |

#### User Role System
- 4 roles derived from Traccar user flags: `viewer`, `operator`, `technician`, `admin`
- Role derivation: `administrator=true` → admin, `readonly=true` → viewer,
  `attributes.appRole='technician'` → technician, else → operator
- `permissionDenied` commands hidden from viewer and operator; shown as disabled
  to technician (for admin-only commands)

#### Safety Enforcement
- **High Risk commands** (`engineStop`, `engineResume`, `relayOn/Off`, `outputControl*`,
  `immobilizerOn/Off`, `factoryReset`, `setAPN`, `setServerAddress`):
  - `supportsQueue: false` — **NEVER queued**
  - `requiresOnline: true` — blocked if device offline
  - require user confirmation dialog with `CONFIRMER` text input
- **Speed gate** — `engineStop`/`immobilizerOn` blocked above 10/5 km/h
- **Installation gate** — commands disabled if required hardware not installed
- `hasEngineControl` virtual flag = `hasRelay OR hasImmobilizer` (for
  `engineStop`/`engineResume`)

#### Command History
- Every dispatch logged to SharedPreferences with:
  `commandKey`, `riskLevel`, `sendMethod`, `sentByUserId`, `sentByUserName`,
  `deviceOnlineAtExecution`, `vehicleSpeedAtExecution`, `failureReason`, `rawResponse`
- **Rejected attempts also logged** (`status: rejected`) — full audit trail
- Schema v2 (`cmd_logs_v2_$deviceId`) with migration from v1

#### UI
- 6 collapsible sections with `available/total` count per section
- `CommandCard` adapts to 11 capability states with contextual badges and icons
- `CommandStatusBanner` — pulsing online/offline dot + speed indicator
- Medium Risk: confirm/cancel dialog
- High Risk: CONFIRMER text-input dialog (button disabled until exact match)
- `CommandLogsScreen` — tappable entries with detail bottom sheet;
  `rawResponse` + `failureReason` visible to Technician/Admin only

#### Error Handling
All Traccar API errors translated to user-friendly French messages:
`saved command not provided`, `unsupported`, `timeout`, `unauthorized`,
`forbidden`, `bad request`, `server error`, `network error`

---

### Bug Fixes (v1 Hardening)

| Fix | Description |
|---|---|
| Filtering fix | `permissionDenied` commands now hidden from `operator` too (was viewer-only) |
| Rejected logging | Safety-blocked attempts now create a log entry with `status: rejected` |
| `engineStop`/`engineResume` | Now accept `hasRelay OR hasImmobilizer` via virtual `hasEngineControl` flag |
| Log detail UI | `rawResponse` and `failureReason` shown in bottom sheet for Technician/Admin |

---

### Files Changed
See session transcript for the full file list.

---

## Backlog → v2.0.0
See [`BACKLOG_V2.md`](./BACKLOG_V2.md)
