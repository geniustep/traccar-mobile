# Command System — Backlog v2.0.0

Items deferred from v1 stable. Prioritized for the next development cycle.

---

## Priority: High

### BL-01 — Real `rawResponse` capture from Traccar API
**Context:** `CommandLogEntry.rawResponse` field exists and is saved, but the
datasource (`CommandsRemoteDatasource`) does not yet capture the raw HTTP
response body from `/commands/send`.

**Work required:**
- Modify `CommandsRemoteDatasource.sendCommand()` to return the raw response
  string alongside the result.
- Update `CommandsRepository` / `CommandsRepositoryImpl` to propagate it.
- Pass it to `CommandExecutionService._send()` for inclusion in the log entry.

**Impact:** Technicians/Admins will be able to see the actual device
acknowledgement string in the command history detail sheet.

---

### BL-02 — Saved Command Picker (endpoint `/api/commands`)
**Context:** Commands with `sendMethod: saved` resolve to `availableViaSaved`
but the UI has no way to select which saved command to use.

**Work required:**
- New datasource method: `GET /api/commands?deviceId=X` to fetch saved commands.
- New Riverpod provider: `savedCommandsProvider(deviceId)`.
- New UI widget: `SavedCommandPickerSheet` — bottom sheet list of saved commands.
- Wire into `DeviceCommandsScreen`: when user taps a `savedCommand`, show picker
  before dispatch.

**Impact:** Users can execute pre-configured saved commands from Traccar dashboard.

---

## Priority: Medium

### BL-03 — SMS Fallback — Real implementation
**Context:** `supportsSmsFallback: true` is defined in the mapping and
`DeviceInstallationProfile.smsEnabled` / `simPhoneNumber` exist, but the actual
SMS sending is not implemented — commands always route through Traccar API.

**Work required:**
- Integrate `telephony` or `url_launcher` (SMS URI) package.
- Implement `SmsFallbackService.send(phoneNumber, commandText)`.
- Extend `CommandExecutionService._send()`: if API fails AND `supportsSmsFallback`
  AND `smsEnabled`, retry via SMS.
- Update `CommandLogEntry.sendMethod` to `CommandSendMethod.sms` for SMS-sent entries.

**Impact:** Devices with no GPRS / offline devices can still receive critical
commands via SMS.

---

### BL-04 — Sync `DeviceInstallationProfile` with Traccar attributes
**Context:** Installation profiles are stored only in local SharedPreferences.
If the app is reinstalled, or if a different technician uses a different device,
the profiles are lost or out of sync.

**Work required:**
- Define a standard Traccar device attribute schema:
  e.g. `attributes.installation = { hasRelay: true, hasOutput1: false, ... }`
- New sync service: read from `GET /api/devices/{id}` → parse attributes →
  merge with local profile.
- Write back: `PUT /api/devices/{id}` with updated attributes when technician
  edits the installation profile.
- Conflict resolution: server wins on fresh install; local wins if server
  attribute is absent.

**Impact:** Installation profiles survive app reinstall and are consistent
across multiple users/devices.

---

## Priority: Normal

### BL-05 — Unit & Integration Tests
**Context:** No automated tests exist for the command system.

**Test targets:**

```
test/features/commands/
  ├── command_capability_service_test.dart
  │     ├── viewer → vehicleControl commands hidden
  │     ├── operator → vehicleControl commands hidden
  │     ├── admin + engineStop + offline → offlineBlocked
  │     ├── admin + engineStop + hasRelay=false + hasImmobilizer=false → notInstalled
  │     ├── admin + engineStop + hasImmobilizer=true → available
  │     ├── Low Risk + offline + supportsQueue=true → offlineQueued
  │     ├── High Risk + speed > limit → blockedBySpeed
  │     └── missingParameters → missingParameters
  ├── command_validation_service_test.dart
  │     ├── High Risk + offline → ValidationFailed(offlineBlocked)
  │     ├── High Risk + speed → ValidationFailed(blockedBySpeed)
  │     ├── Medium Risk + not confirmed → ValidationNeedsConfirmation
  │     ├── High Risk + confirmed → ValidationPassed
  │     └── Missing required param → ValidationFailed(missingParameters)
  └── command_log_entry_test.dart
        ├── toJson / fromJson round-trip
        ├── Legacy v1 schema migration
        └── rejected status serialization
```

**Impact:** Prevents regressions when adding new commands or modifying rules.

---

## Manual Test Checklist (for each release)

Before merging to main, verify manually on a physical device:

- [ ] **Online device — Low Risk command** (positionSingle): sends immediately, logged as `success`
- [ ] **Online device — High Risk command** (engineStop, hasRelay=true): requires CONFIRMER dialog, logged
- [ ] **Online device — High Risk command, speed > 10 km/h**: blocked, logged as `rejected`
- [ ] **Offline device — Low Risk + supportsQueue=true**: queued, logged as `queued`
- [ ] **Offline device — High Risk command**: `offlineBlocked` displayed, NOT queued, logged as `rejected`
- [ ] **viewer user**: Vehicle Control section absent from screen
- [ ] **operator user**: Vehicle Control section absent from screen
- [ ] **technician user**: Vehicle Control visible, admin-only commands (immobilizerOn, factoryReset) shown as disabled
- [ ] **admin user**: All commands accessible
- [ ] **Command without required hardware** (engineStop, hasRelay=false, hasImmobilizer=false): `notInstalled` shown
- [ ] **Command with hasImmobilizer=true, hasRelay=false** (engineStop): `available` (hasEngineControl passes)
- [ ] **Technician opens log detail**: rawResponse section visible (even if null)
- [ ] **Viewer opens log detail**: rawResponse section hidden
- [ ] **Factory reset** (Admin): shows HIGH badge, requires CONFIRMER input, works only online
