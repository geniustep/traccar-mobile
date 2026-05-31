# QA MapAudit — Build حديث (2026-05-31)

## ما تم تنفيذه

1. **تشغيل build حديث** عبر `flutter run -d emulator-5554 --debug` (PID جديد، APK مع `MapAuditLogger`).
2. **تأكيد سجلات WebSocket الجديدة** في logcat / stdout:
   ```
   [WebSocket] [WebSocket] position received deviceId=11 fixTime=2026-05-31T12:13:11.000Z
   ```
3. **اختبار تكامل** `integration_test/map_audit_emulator_qa_test.dart` + مفاتيح QA (`nav_dest_map`, `vehicle_card_11`, …).
4. **محاولات adb** — لم تفتح شاشات الخريطة (بقيت على Dashboard أو Login).

## ما لم يكتمل (يتطلب تسجيل دخول يدوي)

المحاكي على **شاشة Login** في آخر جلسة `flutter run`. بدون دخول لا تظهر:
`[MapAudit]`, `[LivePosition]`, `[MarkerUpdate]`, `[FollowMode]`, `[Polling]`, `[Dispose]`.

## خطواتك (دقيقتان) ثم إعادة الجمع التلقائي

1. على المحاكي: **سجّل الدخول**.
2. في طرفية `flutter run`: اضغط **R** (Hot Restart).
3. نفّذ يدوياً أو شغّل:
   ```powershell
   powershell -File tools\map_audit_qa_v3.ps1
   ```
   أو:
   ```powershell
   flutter test integration_test/map_audit_emulator_qa_test.dart -d emulator-5554
   ```

## معايير القبول — الحالة

| المعيار | الحالة |
|---------|--------|
| Build يحتوي MapAudit | **نعم** (WebSocket layer مؤكد) |
| Live Map 60s + سجلات كاملة | **معلق** — يحتاج login + فتح شاشة |
| Vehicle Tracking 60s | **معلق** |
| Follow ON/OFF | **معلق** |
| Dispose + Polling stopped | **معلق** |
| WebSocket + تأخير بيانات | **نعم** — متصل، device 11 ~ثوانٍ |

## ملفات السجلات

- `qa_logs/integration_map_audit_output.txt` — محاولة integration (وصل /vehicles ثم فشل card)
- `qa_logs/v2_full_audit.txt` — WebSocket فقط
- `terminals/389434.txt` — جلسة flutter run سابقة مع WS لـ device 11
