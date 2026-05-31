# WebSocket Reconnect — ملاحظة مراقبة (Observation)

**الحالة:** مراقبة / متابعة لاحقة — **ليست Patch** ولا تغيّر سلوك الكود  
**التاريخ:** 2026-05-18  
**السياق:** ظهر أثناء QA لـ [Dashboard data coalescing](dashboard_data_coalescing_closeout.md) (pull-to-refresh)؛ **خارج نطاق** ذلك Patch المغلق.

**قرار:** لا تعديل WebSocket الآن. هذا المستند قائمة مراقبة لـ Debug Console / QA فقط.

---

## مقتطف لوج مُلاحظ

```
[WebSocket] Connection closed
[WebSocket] Reconnect scheduled retry=1/10
[LiveSync] connected -> reconnecting
Cookie present: true
```

قد يظهر أيضاً لاحقاً في نفس الجلسة:

```
[WebSocket] Reconnect scheduled: retry=1/10 nextRetry=…s endpoint=…
LiveSyncStatus changed: connected -> reconnecting, …
```

---

## Observed case — pull-to-refresh (2026-05-18)

**التسمية:** `Recovered on retry=2 after timeout on retry=1`

| الخطوة | الملاحظة |
|--------|----------|
| المسبق | WebSocket `Connection closed` **بعد** pull-to-refresh (تزامن؛ ليس بالضرورة سبباً مباشراً) |
| retry=1 | فشل: `WebSocketChannelException: SocketException: Connection timed out` |
| retry=2 | نجح — عاد الاتصال |
| Cookie | `Cookie present: true` أثناء المحاولات |
| LiveSync | `reconnecting` → `connected` |

**الاستنتاج (مراقبة فقط، ليس Patch):**

- **لا يدل** على مشكلة Auth أو JSESSIONID (الكوكي حاضر و REST يعمل).
- **الأقرب:** انقطاع WebSocket / شبكة / proxy **مؤقت**؛ آلية إعادة المحاولة استوعبت الحالة.

```
[WebSocket] Connection closed
[WebSocket] Reconnect scheduled retry=1/10
… Connection timed out (retry=1)
[WebSocket] Reconnect scheduled retry=2/10
… connected
LiveSyncStatus changed: reconnecting -> connected
Cookie present: true
```

---

## معيار فتح Phase تشخيص (لاحقاً فقط)

**لا Patch ولا تغيير WebSocket الآن.** اقترح Phase تشخيص (close code/reason + server logs) **فقط إذا** تحقّق أحد الشرطين في جلسة QA أو إنتاج:

| الشرط | العتبة |
|--------|--------|
| **Timeout متكرر** | أكثر من **3** مرات `Connection timed out` خلال **10 دقائق** |
| **Retry مرتفع متكرر** | الوصول إلى **retry ≥ 3** بشكل متكرر (مثلاً ≥2 جلسات في نفس اليوم أو ≥3 أحداث في 10 دقائق) |

ما دون ذلك: يبقى **observation** — حالة مثل `Recovered on retry=2` تعتبر مقبولة ما لم تتكرر العتبات أعلاه.

---

## أسئلة المراقبة (QA / Debug Console)

عند كل ظهور لـ `Connection closed` + `Reconnect scheduled`، سجّل في ملاحظات الجلسة:

| # | السؤال | ماذا تسجّل |
|---|--------|------------|
| 1 | **هل يحدث نادراً أم يتكرر؟** | عدد مرات `Connection closed` في جلسة واحدة (مثلاً 0–1 = نادر، ≥3 في 10 دق = متكرر). |
| 2 | **هل يعود إلى `connected` من المحاولة الأولى؟** | بعد `retry=1/10`: هل يظهر `LiveSyncStatus … -> connected` أو `SocketConnected` **قبل** `retry=2`؟ نعم/لا + الزمن التقريبي (ثوانٍ). |
| 3 | **متى يحدث؟** | اربط بالحدث: `pull_to_refresh`، `dashboard_opened`، تبديل تبويب، خلفية/أمامية، عشوائي أثناء الخمول. |
| 4 | **close code / close reason؟** | انظر القسم التالي — ما يظهر **حالياً** في اللوج vs ما نحتاجه لاحقاً. |

### قالب جلسة QA (نسخ سريع)

```
التاريخ:
السيناريو: [ ] pull-to-refresh  [ ] فتح لوحة  [ ] خلفية  [ ] عشوائي
عدد close في 10 دق:
عدد Connection timed out في 10 دق:
أقصى retry وصل إليه (1–10):
عودة connected من retry=1: [ ] نعم  [ ] لا  (من retry=___ بعد ___ ث)
Cookie present عند close/retry: [ ] true  [ ] false
تجاوز عتبة Phase (3 timeout / retry≥3 متكرر): [ ] نعم  [ ] لا
ملاحظات:
```

---

## ما يوفره اللوج الحالي (`traccar_socket_service`)

| الحدث | سطر تقريبي | ملاحظة |
|--------|------------|--------|
| إغلاق | `[WebSocket] Connection closed` | `_onDone` — **بدون** close code/reason في النص اليوم |
| إعادة الاتصال | `[WebSocket] Reconnect scheduled: retry=N/10 nextRetry=…s` | تأخير exponential + حد أقصى من `ApiConfig.maxSocketReconnectAttempts` |
| فشل نهائي | `[WebSocket] Reconnect limit reached` | بعد استنفاد المحاولات |
| Live sync | `LiveSyncStatus changed: connected -> reconnecting` | `app_connection_monitor` |
| Cookie | `Cookie present: true/false` (ضمن diagnostics عند أخطاء/اتصال) | يؤكد أن الجلسة ما زالت محفوظة أثناء reconnect |

**فجوة مراقبة (للمتابعة لاحقاً، ليس في هذا Patch):**  
Traccar / `web_socket_channel` قد يوفّر **close code** و **close reason** عند `_onDone` — غير مُسجَّلة صراحة في `Connection closed` اليوم. عند فتح Phase لاحقة، الهدف: إضافة سطر واحد مثل  
`Connection closed code=… reason=…` + تمييز **client-initiated** vs **server-initiated**.

---

## تفسير أولي (غير حاسم)

- `Cookie present: true` أثناء reconnect يشير أن **REST/الجلسة** ما زالت صالحة؛ الانقطاع قد يكون **قناة WS فقط** (مهلة، proxy، إعادة فتح من السيرفر، ضغط شبكة).
- ظهور الإغلاق **بعد** pull-to-refresh قد يكون **تزامناً** وليس سبباً مباشراً — سجّل السيناريو 3 قبل الاستنتاج.
- الحالة المُوثَّقة `Recovered on retry=2 after timeout on retry=1` تتوافق مع **شبكة/WS مؤقت** وليس فقدان جلسة — راقب عتبات Phase أعلاه قبل أي تشخيص أعمق.

---

## علاقة بالـ Patches المغلقة

| Patch | العلاقة |
|-------|---------|
| [dashboard_data_coalescing_closeout.md](dashboard_data_coalescing_closeout.md) | مغلق — لا يمس WebSocket |
| [reports_request_gate_qa2_closeout.md](reports_request_gate_qa2_closeout.md) | مغلق — إصلاح ping سابق منفصل |

**Phase لاحقة مقترحة:** تشخيص WS reconnect + close code/reason + server logs — **فقط عند تجاوز معيار المراقبة أعلاه** (ليس الآن).

---

## مرجع Debug Console

- شاشة: `/debug-console` (غير release).
- راقب فلتر **WebSocket** + **LiveSync** / **Dashboard** في نفس الجدول الزمني عند إعادة إنتاج الملاحظة.
