# ELMO Fleet Intelligence — Flutter Mobile App

A production-ready Flutter frontend for the **ELMO Smart Fleet Intelligence Platform**.

---

## Architecture

Clean Architecture with feature-first folder organisation:

```
lib/
  app/              # Router, App widget, MainShell (bottom nav)
  core/
    config/         # AppConfig (env-based base URLs)
    constants/      # API paths, storage keys, app constants
    network/        # DioClient + AuthInterceptor (token refresh)
    storage/        # SecureStorageService (flutter_secure_storage)
    theme/          # AppColors, AppTextStyles, AppSpacing, AppTheme
    utils/          # DateFormatter, FormatUtils
    widgets/        # ElmoCard, ElmoButton, ElmoTextField, StatusBadge, etc.
  features/
    auth/           # Login screen, JWT token handling, AuthNotifier
    dashboard/      # Fleet summary, insights, quick actions
    vehicles/       # Fleet list, search/filter, vehicle detail
    map/            # Live map (Google Maps), vehicle markers, auto-refresh
    trips/          # Trip history cards, distance/duration/speed stats
    alerts/         # All alerts, smart alerts, severity badges
    analytics/      # Weekly KPIs, bar chart, efficiency score
    notifications/  # Push notification centre, read/unread state
    settings/       # Profile, preferences, sign out
  shared/
    mock/           # MockData — fallback data during development
    providers/      # Core Riverpod providers (DioClient, storage, etc.)
```

Each feature follows `data / domain / presentation` layering.

---

## Tech Stack

| Concern | Library |
|---|---|
| State management | flutter_riverpod |
| Navigation | go_router |
| HTTP client | dio |
| Secure token storage | flutter_secure_storage |
| Local preferences | shared_preferences |
| Maps | google_maps_flutter |
| Formatting | intl |

---

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure API base URL

Edit `lib/core/config/app_config.dart`:

```dart
static const AppConfig development = AppConfig(
  baseUrl: 'https://api-dev.elmofleet.com/api',
  ...
);
```

Or pass at build time:

```bash
flutter run --dart-define=ENV=production
```

### 3. Configure Google Maps

Add your Google Maps API key:

- **Android**: `android/app/src/main/AndroidManifest.xml`  
  ```xml
  <meta-data android:name="com.google.android.geo.API_KEY"
             android:value="YOUR_KEY_HERE"/>
  ```
- **iOS**: `ios/Runner/AppDelegate.swift`  
  ```swift
  GMSServices.provideAPIKey("YOUR_KEY_HERE")
  ```

### 4. Run

```bash
flutter run
```

---

## Backend API Integration

The app is pre-wired to these endpoints (defined in `lib/core/constants/api_constants.dart`):

| Endpoint | Feature |
|---|---|
| `POST /auth/login` | Authentication |
| `POST /auth/refresh` | Token refresh |
| `GET /auth/me` | Current user |
| `GET /dashboard/summary` | Fleet KPIs |
| `GET /dashboard/insights` | Smart insights |
| `GET /vehicles` | Vehicle list |
| `GET /vehicles/:id` | Vehicle detail |
| `GET /vehicles/:id/live` | Live position |
| `GET /vehicles/:id/trips` | Trip history |
| `GET /vehicles/:id/alerts` | Per-vehicle alerts |
| `GET /alerts` | All alerts |
| `GET /alerts/smart` | Smart/interpreted alerts |
| `GET /analytics/weekly` | Weekly KPIs |
| `GET /notifications` | Notification centre |
| `POST /devices/fcm` | Register FCM token |

All repositories fall back to `MockData` when the API is unavailable — remove fallbacks before going to production.

---

## Push Notifications (FCM)

FCM integration is stubbed in `lib/features/notifications/services/fcm_service.dart`.  
To activate:

1. Add `firebase_core` and `firebase_messaging` to `pubspec.yaml`
2. Configure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Uncomment the implementation in `FcmService.initialize()`

The backend token registration call (`POST /devices/fcm`) is already wired — it fires automatically after the token is obtained.

---

## Mock Data

`lib/shared/mock/mock_data.dart` contains realistic fallback data for all features.  
Each repository catches API errors and returns mock data during development.  
**Remove the `catch (_) { return MockData.xxx; }` blocks before production.**

---

## Environment Configuration

```bash
# Development (default)
flutter run

# Production
flutter run --dart-define=ENV=production

# Build release APK
flutter build apk --dart-define=ENV=production --release
```
