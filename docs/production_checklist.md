# Production Checklist — Alerts & Notifications

Use this checklist before each production release that touches the
alerts / notifications / FCM system.

---

## 🔒 Security & Secrets

- [ ] No full FCM token printed in release logs
      (`FcmService._logToken` masks the token — verify `kDebugMode` guard is intact)
- [ ] No password or cookie printed anywhere in production code
- [ ] `ApiConfig.loggingEnabled` is `false` (or gated on debug) in release build
- [ ] `google-services.json` contains the correct **production** Firebase project
      (not a dev/staging project)
- [ ] `google-services.json` is in `.gitignore` (or stored via CI secret injection)
- [ ] `firebase_options.dart` matches the correct `applicationId` / bundle ID

---

## 📦 Firebase Configuration

- [ ] Firebase project ID matches the project used by the Backend Admin SDK
- [ ] `applicationId` in `android/app/build.gradle.kts` matches the Firebase project
- [ ] Android notification channel is configured for high-priority alerts
      (optional but recommended for critical severity alerts)
- [ ] `AndroidManifest.xml` includes all permissions required by `firebase_messaging`
- [ ] APNs certificate / key configured in Firebase for iOS (if iOS is targeted)

---

## 🧪 Manual Test — Foreground Push

1. Log in to the app.
2. Confirm `[FCM] Token sent to backend ✓` appears in logs.
3. From the Backend, call `POST /alerts/test` with `sendPush: true`.
4. While the app is in the foreground and the alerts screen is open:
   - [ ] No duplicate popup / snackbar appears
   - [ ] Unread badge increments within ~5 seconds
   - [ ] Alert list refreshes and the new alert appears at the top
5. While on a different screen:
   - [ ] Unread badge increments
   - [ ] No intrusive popup

---

## 🧪 Manual Test — Background Push

1. Send the app to the background (home button).
2. From the Backend, call `POST /alerts/test` with `sendPush: true`.
   - [ ] System notification appears in the notification shade
3. Tap the notification:
   - [ ] App opens directly on the Alert Detail screen for that alert
   - [ ] Alert is automatically marked as read (`PATCH /alerts/:id/read` in logs)
   - [ ] Navigating back shows the alert marked as read in the list

---

## 🧪 Manual Test — Terminated Push

1. Force-close the app (remove from recents).
2. From the Backend, call `POST /alerts/test` with `sendPush: true`.
   - [ ] System notification appears
3. Tap the notification:
   - [ ] App launches
   - [ ] If already logged in: navigates directly to alert detail
   - [ ] If session expired: redirected to login → after login, navigates to alert detail
   - [ ] Alert is marked as read

---

## 🧪 Manual Test — Read / Unread State

- [ ] Open an unread alert → it becomes read in the list after navigating back
- [ ] Pull to refresh → alert remains read (Backend persists state)
- [ ] Reinstall app → alerts remain read (no local-only state)
- [ ] Tap "Tout marquer comme lu" → all alerts become read
- [ ] `unreadCount` becomes 0 after mark-all
- [ ] Pull to refresh after mark-all → all still read (Backend confirmed)
- [ ] Unread badge disappears when `unreadCount == 0`

---

## 🧪 Manual Test — Logout

- [ ] Logout clears the alerts list in memory
- [ ] Unread badge resets to 0
- [ ] Login as a different user → shows that user's alerts only
- [ ] `pendingAlertId` is cleared on logout
- [ ] FCM listener is reset (no push delivered to logged-out session)

---

## 🧪 Manual Test — UI

- [ ] No "Traccar" text visible anywhere in the app (alerts, detail, metadata)
- [ ] No `source_event_id` or raw type slugs visible in UI
- [ ] All alert titles are in the configured locale (French by default)
- [ ] Severity colors are correct (critical = red, warning = amber)
- [ ] Empty state shows correctly when filter returns no results
- [ ] Error state shows retry button on network failure
- [ ] Pull to refresh works on all three tabs

---

## 🧪 Manual Test — Deduplication

1. Configure a scenario where both FCM and WebSocket fire for the same event.
2. Confirm the alert appears only **once** in the list (not duplicated).
3. Confirm logs show:
   ```
   [Notifications] Deduplication: FCM alertId=1201 already seen – refresh skipped.
   ```

---

## ✅ Code Review Checklist

- [ ] No new `SharedPreferences` writes for alert read/unread state
- [ ] No calls to legacy `reports/events` endpoint from the alerts screen
- [ ] All new API calls use `TraccarClient` (not raw `http` or a second Dio instance)
- [ ] `AlertsRemoteDataSource` uses `/alerts/` (with trailing slash)
- [ ] `refreshFromFcm` / `refreshUnreadCount` are the only FCM-triggered mutations
      (no alert objects created from FCM payload)
- [ ] `resetOnLogout()` is called for both `alertsProvider` and `notificationsProvider`

---

## 📋 Known TODOs (post-production)

| Item | Priority | Notes |
|---|---|---|
| `DELETE /fcm/token` on logout | Medium | Endpoint not yet on Backend; prevents ghost push after logout |
| User notification preferences | Low | Per-type opt-in/opt-out in settings |
| Quiet hours | Low | Suppress foreground refresh between 22:00–07:00 |
| Rate-limit UI feedback | Low | Show "trop de requêtes" banner on 429 |
| Per-type alert icons | Low | Custom SVG icons for overspeed, geofence, maintenance, etc. |
| Localization AR / FR / EN / ES | Medium | All alert titles currently come from Backend in French by default |
| Pagination "load more" button | Low | Currently shows first 50 results; infinite scroll or a button needed for large fleets |
| iOS APNs configuration | High (if iOS targeted) | Separate certificate/key setup required |
