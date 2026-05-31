# MapAudit QA — Runbook (جلسة واحدة)

## 1. تشغيل

```powershell
cd d:\flutter\app\traccar-mobile
flutter run -d emulator-5554 --debug
```

**لا** تشغّل `flutter attach` من طرفية ثانية.

## 2. تسجيل الدخول

- سجّل الدخول على المحاكي حتى `Entered: /dashboard` في الطرفية.

## 3. Hot Restart

- في **نفس** طرفية `flutter run`: اضغط **R**.
- المتوقع بعد الإصلاح: `Auth sync: isLoading=true` ثم `isAuthenticated=true` **بدون** `Logout — FCM`.
- يجب البقاء على Dashboard (أو Splash → Dashboard)، وليس `/login`.

## 4. QA يدوي / adb

```powershell
# طرفية ثانية — مراقبة السجلات:
powershell -File tools\map_audit_qa_monitor.ps1

# بعد R — أتمتة لمس (تقريبية):
powershell -File tools\map_audit_qa_after_login.ps1
```

أو integration test (بعد login على المحاكي):

```powershell
flutter test integration_test/map_audit_emulator_qa_test.dart -d emulator-5554
```

## 5. معايير السجلات

### Live Map

- `[MapAudit] screen=LiveMap opened`
- `[LivePosition] screen=LiveMap deviceId=11`
- `[LiveDelay] deviceId=11`
- `[MarkerUpdate] screen=LiveMap deviceId=11`
- `[FollowMode] screen=LiveMap enabled=true cameraAnimated=true`
- `[Polling] screen=LiveMap started` / `stopped`
- `[Dispose] screen=LiveMap`

### Vehicle Tracking

- `[MapAudit] screen=VehicleTracking opened vehicleId=11`
- نفس العائلات مع `screen=VehicleTracking`

## 6. إصلاح Auth (Hot Restart)

`AuthNotifier` يبدأ الآن بـ `isLoading: true` حتى لا يُفسَّر Hot Restart كـ logout قبل قراءة Secure Storage.
