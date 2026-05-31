// ignore_for_file: avoid_print
/// اختبار تكامل Geofence + إشعارات geofenceEnter / geofenceExit على خادم Traccar حقيقي.
///
/// متطلبات (متغيرات بيئة — لا تُخزَّن أي اعتمادات في الكود):
/// - [TRACCAR_URL] — لـ ELMOGPS استخدم `https://api.elmogps.com` دون `/api`.
/// - [TRACCAR_EMAIL] ، [TRACCAR_PASSWORD] ، [TEST_DEVICE_ID]
///
/// اختياري:
/// - [TRACCAR_OSMAND_URL] بروتوكول OsmAnd
/// - [GEONOTIF_DEBUG]=1 — طباعة مفصّلة (منطقة، نقاط، أحداث خام، مواضع، حساب داخل/خارج)
/// - [GEONOTIF_SKIP_NOTIFICATIONS]=1 — لا يُنشئ إشعارات؛ يختبر فقط سياج + جهاز + مواقع + أحداث المحرّك

library traccar_geofence_notifications_qa;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const double _earthRadiusM = 6371000.0;

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double _haversineMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const rLat = math.pi / 180;
  final phi1 = lat1 * rLat;
  final phi2 = lat2 * rLat;
  final dphi = (lat2 - lat1) * rLat;
  final dlambda = (lon2 - lon1) * rLat;
  final a = math.pow(math.sin(dphi / 2), 2) +
      math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dlambda / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusM * c;
}

/// يُعتمد على نفس فكرة التطبيق: داخل الدائرة إذا المسافة ≤ نصف القطر (+ هامش بسيط).
bool _pointInsideCircle({
  required double lat,
  required double lon,
  required double centerLat,
  required double centerLon,
  required double radiusM,
  double epsilonM = 1.0,
}) {
  final d = _haversineMeters(lat, lon, centerLat, centerLon);
  return d <= radiusM + epsilonM;
}

void _debugPrint(bool debug, String msg) {
  if (debug) print('[debug] $msg');
}

String _jsonPretty(Object? o) {
  try {
    return const JsonEncoder.withIndent('  ').convert(o);
  } catch (_) {
    return o.toString();
  }
}

class _MotionStep {
  const _MotionStep({
    required this.label,
    required this.lat,
    required this.lon,
    required this.expectInside,
  });

  final String label;
  final double lat;
  final double lon;
  final bool expectInside;
}

Future<int> _run() async {
  final env = Platform.environment;
  final base = env['TRACCAR_URL']?.replaceAll(RegExp(r'/$'), '');
  final email = env['TRACCAR_EMAIL'];
  final password = env['TRACCAR_PASSWORD'];
  final deviceIdRaw = env['TEST_DEVICE_ID'];
  final debug = env['GEONOTIF_DEBUG'] == '1';
  final skipNotifications = env['GEONOTIF_SKIP_NOTIFICATIONS'] == '1';

  if (base == null ||
      base.isEmpty ||
      email == null ||
      email.isEmpty ||
      password == null ||
      password.isEmpty ||
      deviceIdRaw == null ||
      deviceIdRaw.isEmpty) {
    stderr.writeln(
      'يجب تعيين TRACCAR_URL و TRACCAR_EMAIL و TRACCAR_PASSWORD و TEST_DEVICE_ID',
    );
    return 1;
  }

  final optionalOsmAnd =
      env['TRACCAR_OSMAND_URL']?.replaceAll(RegExp(r'/$'), '');
  final derivedOsmAnd = _deriveOsmAndBase(base);
  final osmandBase = (optionalOsmAnd != null && optionalOsmAnd.isNotEmpty)
      ? optionalOsmAnd
      : derivedOsmAnd;

  HttpClient? client;
  var cookieJar = '';
  final createdNotificationIds = <int>[];
  int? createdGeofenceId;

  Future<void> cleanupOnError(Object e, StackTrace st) async {
    if (client == null) return;
    print('');
    print('— تنظيف الموارد (بعد خطأ) —');
    for (final nid in createdNotificationIds.reversed) {
      try {
        await _deletePath(client, cookieJar, base, '/notifications/$nid');
        print('DELETE /notifications/$nid OK');
      } catch (err) {
        print('تحذير: فشل حذف الإشعار $nid: $err');
      }
    }
    if (createdGeofenceId != null) {
      try {
        await _deletePath(client, cookieJar, base, '/geofences/$createdGeofenceId');
        print('DELETE /geofences/$createdGeofenceId OK');
      } catch (err) {
        print('تحذير: فشل حذف السياج: $err');
      }
    }
    print('');
    print('FAIL: $e');
    print(st);
  }

  try {
    final http = HttpClient();
    client = http;
    print('API: $base');
    print('OsmAnd base: $osmandBase');
    if (debug) {
      print('[debug] GEONOTIF_DEBUG=1');
      if (skipNotifications) {
        print('[debug] GEONOTIF_SKIP_NOTIFICATIONS=1 (بدون إنشاء إشعارات)');
      }
    }

    String combineSetCookie(List<String>? setCookies) {
      if (setCookies == null) return '';
      final buf = StringBuffer();
      for (final line in setCookies) {
        final part = line.split(';').first.trim();
        if (part.isNotEmpty) buf.write('$part; ');
      }
      return buf.toString();
    }

    Future<Map<String, dynamic>> jsonResponse(HttpClientResponse r) async {
      final text = await r.transform(utf8.decoder).join();
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw HttpException('HTTP ${r.statusCode}: $text');
      }
      final trimmed = text.trim();
      if (trimmed.isEmpty) return {};
      return jsonDecode(trimmed) as Map<String, dynamic>;
    }

    Future<HttpClientRequest> open(
      String method,
      String path, {
      bool jsonBody = false,
    }) async {
      final uri = Uri.parse('$base$path');
      final req = await http.openUrl(method, uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (jsonBody) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      }
      if (cookieJar.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader, cookieJar);
      }
      return req;
    }

    Future<Map<String, dynamic>> postJson(
      String path,
      Map<String, dynamic> body,
    ) async {
      final req = await open('POST', path, jsonBody: true);
      req.write(jsonEncode(body));
      final res = await req.close();
      final jar = combineSetCookie(res.headers['set-cookie']);
      if (jar.isNotEmpty) cookieJar = jar;
      return jsonResponse(res);
    }

    Future<Map<String, dynamic>> getJsonMap(String path) async {
      final req = await open('GET', path);
      final res = await req.close();
      final jar = combineSetCookie(res.headers['set-cookie']);
      if (jar.isNotEmpty) cookieJar = jar;
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode}: $text');
      }
      return jsonDecode(text) as Map<String, dynamic>;
    }

    Future<List<dynamic>> getJsonList(String path) async {
      final req = await open('GET', path);
      final res = await req.close();
      final jar = combineSetCookie(res.headers['set-cookie']);
      if (jar.isNotEmpty) cookieJar = jar;
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode}: $text');
      }
      return jsonDecode(text) as List<dynamic>;
    }

    Future<Map<String, dynamic>> resolveDevice(String requested) async {
      final trimmed = requested.trim();
      if (trimmed.isEmpty) {
        throw StateError('TEST_DEVICE_ID فارغ');
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        try {
          return await getJsonMap('/devices/$parsed');
        } on HttpException catch (e) {
          if (!e.message.contains('404')) rethrow;
        }
      }
      final list = await getJsonList('/devices');
      for (final row in list) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final uid = m['uniqueId']?.toString() ?? '';
        final id = (m['id'] as num?)?.toInt();
        if (uid == trimmed || (parsed != null && id == parsed)) {
          return m;
        }
      }
      throw StateError(
        'لا جهاز يطابق TEST_DEVICE_ID="$trimmed" (id داخلي أو uniqueId من Traccar)',
      );
    }

    // ── تسجيل الدخول ─────────────────────────────────────────────────────
    final sessReq = await open('POST', '/session');
    sessReq.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/x-www-form-urlencoded',
    );
    sessReq.write(
      'email=${Uri.encodeQueryComponent(email)}'
      '&password=${Uri.encodeQueryComponent(password)}',
    );
    final sessRes = await sessReq.close();
    final sc = combineSetCookie(sessRes.headers['set-cookie']);
    if (sc.isNotEmpty) cookieJar = sc;
    await jsonResponse(sessRes);
    print('POST /session => OK');

    final sessionUser = await getJsonMap('/session');
    final userId = (sessionUser['id'] as num).toInt();
    print('GET /session => userId=$userId');

    final dev = await resolveDevice(deviceIdRaw);
    final effectiveDeviceId = (dev['id'] as num).toInt();
    final uniqueIdRaw = dev['uniqueId'];
    final uniqueId = uniqueIdRaw?.toString() ?? '';
    if (uniqueId.isEmpty) {
      throw StateError('الجهاز $effectiveDeviceId لا يحتوي uniqueId');
    }
    print('الجهاز => id=$effectiveDeviceId uniqueId=$uniqueId');

    /// نصف قطر واضح (متر) — 400 م بين 300 و 500 كما طُلب
    const double centerLat = 24.7136;
    const double centerLon = 46.6753;
    const double radiusM = 400.0;

    // تقريب: ~111 م لكل 0.001° خط عرض؛ ~101 م لكل 0.001° طول عند خط العرض 24.7°
    const double mPerDegLat = 111320.0;
    final double mPerDegLon =
        111320.0 * math.cos(centerLat * math.pi / 180.0);

    // نقطتان خارج — بعيدتان عن المركز (> 450 م)
    const o1Lat = centerLat + 850 / mPerDegLat;
    const o1Lon = centerLon;
    const o2Lat = centerLat - 820 / mPerDegLat;
    const o2Lon = centerLon;
    // ثلاث نقاط داخل — بين 80 و 220 م من المركز
    const i1Lat = centerLat + 120 / mPerDegLat;
    const i1Lon = centerLon;
    const i2Lat = centerLat + 100 / mPerDegLat;
    final i2Lon = centerLon + 150 / mPerDegLon;
    const i3Lat = centerLat - 90 / mPerDegLat;
    final i3Lon = centerLon + 130 / mPerDegLon;
    // ثلاث نقاط خارج أخرى
    const o3Lat = centerLat + 920 / mPerDegLat;
    final o3Lon = centerLon + 280 / mPerDegLon;
    const o4Lat = centerLat - 900 / mPerDegLat;
    final o4Lon = centerLon - 260 / mPerDegLon;
    const o5Lat = centerLat + 880 / mPerDegLat;
    final o5Lon = centerLon - 300 / mPerDegLon;

    final motionSteps = <_MotionStep>[
      _MotionStep(
        label: 'خارج1',
        lat: o1Lat,
        lon: o1Lon,
        expectInside: false,
      ),
      _MotionStep(
        label: 'خارج2',
        lat: o2Lat,
        lon: o2Lon,
        expectInside: false,
      ),
      _MotionStep(
        label: 'داخل1',
        lat: i1Lat,
        lon: i1Lon,
        expectInside: true,
      ),
      _MotionStep(
        label: 'داخل2',
        lat: i2Lat,
        lon: i2Lon,
        expectInside: true,
      ),
      _MotionStep(
        label: 'داخل3',
        lat: i3Lat,
        lon: i3Lon,
        expectInside: true,
      ),
      _MotionStep(
        label: 'خارج3',
        lat: o3Lat,
        lon: o3Lon,
        expectInside: false,
      ),
      _MotionStep(
        label: 'خارج4',
        lat: o4Lat,
        lon: o4Lon,
        expectInside: false,
      ),
      _MotionStep(
        label: 'خارج5',
        lat: o5Lat,
        lon: o5Lon,
        expectInside: false,
      ),
    ];

    final circleArea =
        'CIRCLE ($centerLat $centerLon, ${radiusM.toStringAsFixed(0)})';

    print('');
    print('═══ تفاصيل السياج المؤقت (قبل الإنشاء) ═══');
    print('deviceId=$effectiveDeviceId');
    print('device uniqueId=$uniqueId');
    print('area (WKT) → $circleArea');
    print(
      'center(lat,lon)=($centerLat, $centerLon)  radius=${radiusM.toStringAsFixed(0)} m',
    );
    print('(صيغة Traccar: CIRCLE(latitude longitude, radiusMeters))');

    print('');
    print('═══ النقاط المرسلة عبر OsmAnd (مخطط) ═══');
    for (var i = 0; i < motionSteps.length; i++) {
      final s = motionSteps[i];
      final d = _haversineMeters(s.lat, s.lon, centerLat, centerLon);
      final calcInside = _pointInsideCircle(
        lat: s.lat,
        lon: s.lon,
        centerLat: centerLat,
        centerLon: centerLon,
        radiusM: radiusM,
      );
      final ok = calcInside == s.expectInside;
      print(
        '${i + 1}. ${s.label}: lat=${s.lat.toStringAsFixed(6)} lon=${s.lon.toStringAsFixed(6)} '
        'مسافة_من_المركز=${d.toStringAsFixed(1)} m — متوقع: ${s.expectInside ? "INSIDE" : "OUTSIDE"} — '
        'حساب_محلي: ${calcInside ? "INSIDE" : "OUTSIDE"} ${ok ? "✓" : "✗ تناقض"}',
      );
    }

    final gf = await postJson('/geofences', {
      'name': 'ELMO QA geofence notify',
      'area': circleArea,
      'attributes': <String, dynamic>{},
    });
    final gid = (gf['id'] as num).toInt();
    createdGeofenceId = gid;

    print('');
    print('═══ بعد الإنشاء على الخادم ═══');
    print('geofenceId (من الاستجابة)=$gid');
    if (debug) {
      print('[debug] جسم /geofences: ${_jsonPretty(gf)}');
    }

    await postJson('/permissions', {
      'deviceId': effectiveDeviceId,
      'geofenceId': gid,
    });
    print('POST /permissions device+geofence => OK');

    Future<int> makeNotif(String type) async {
      final m = await postJson('/notifications', {
        'type': type,
        'always': true,
        'notificators': 'web',
        'attributes': <String, dynamic>{},
      });
      final id = (m['id'] as num).toInt();
      createdNotificationIds.add(id);
      return id;
    }

    Future<void> perm(Map<String, dynamic> p) async {
      await postJson('/permissions', p);
    }

    var notificationGeofenceLinked = false;

    if (!skipNotifications) {
      final nEnter = await makeNotif('geofenceEnter');
      final nExit = await makeNotif('geofenceExit');
      print('notifications enter=$nEnter exit=$nExit');

      notificationGeofenceLinked = true;
      try {
        for (final n in [nEnter, nExit]) {
          await perm({'userId': userId, 'notificationId': n});
          await perm({'notificationId': n, 'geofenceId': gid});
          await perm({'notificationId': n, 'deviceId': effectiveDeviceId});
        }
        print('POST /permissions notification↔user/geofence/device => OK');
      } catch (e) {
        notificationGeofenceLinked = false;
        stderr.writeln('');
        stderr.writeln(
          '=== تنبيه: فشل ربط الإشعار بالسياج (notification ↔ geofence) ===',
        );
        stderr.writeln(
          'السبب غالباً من **خادم Traccar**: جداول غير مكتملة أو ترحيل ناقص.',
        );
        stderr.writeln('التفاصيل التقنية: $e');
        stderr.writeln('');
      }
    } else {
      notificationGeofenceLinked = true;
      print('تم تخطي إنشاء الإشعارات (GEONOTIF_SKIP_NOTIFICATIONS=1).');
    }

    var positionsSent = false;
    final runOsmAnd = notificationGeofenceLinked;

    if (runOsmAnd) {
      final motionStartUtc = DateTime.now().toUtc();
      _debugPrint(
        debug,
        'بداية حركة OsmAnd (UTC): ${motionStartUtc.toIso8601String()}',
      );

      var t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      try {
        for (var si = 0; si < motionSteps.length; si++) {
          final s = motionSteps[si];
          t += 20;
          await _sendOsmAndPosition(
            client: http,
            baseUrl: osmandBase,
            uniqueId: uniqueId,
            latitude: s.lat,
            longitude: s.lon,
            timestampSec: t,
          );
          print(
            'OsmAnd GET => ${s.label} lat=${s.lat.toStringAsFixed(6)} lon=${s.lon.toStringAsFixed(6)} t=$t OK',
          );
          await Future<void>.delayed(
            Duration(seconds: 3 + (si % 3)),
          );
        }
        positionsSent = true;
      } catch (e) {
        stderr.writeln(
          'تحذير: تعذر إرسال مواقع عبر OsmAnd HTTP ($e).',
        );
      }

      print('');
      print('انتظار 60 ثانية لمعالجة الخادم قبل /reports/events ...');
      await Future<void>.delayed(const Duration(seconds: 60));

      final motionEndUtc = DateTime.now().toUtc();
      _debugPrint(
        debug,
        'نهاية انتظار الحركة (UTC): ${motionEndUtc.toIso8601String()}',
      );

      final from = motionStartUtc
          .subtract(const Duration(minutes: 2))
          .toIso8601String();
      final to =
          motionEndUtc.add(const Duration(minutes: 2)).toIso8601String();

      print('');
      print('═══ GET /positions (جهاز الاختبار) ═══');
      List<dynamic> positionsList;
      try {
        positionsList = await getJsonList(
          '/positions?deviceId=$effectiveDeviceId&from=${Uri.encodeQueryComponent(from)}&to=${Uri.encodeQueryComponent(to)}',
        );
      } catch (e) {
        print('تحذير: فشل طلب /positions مع from/to — محاولة بدون فترة: $e');
        positionsList = await getJsonList('/positions');
        positionsList = positionsList.where((row) {
          if (row is! Map) return false;
          return (row['deviceId'] as num?)?.toInt() == effectiveDeviceId;
        }).toList();
      }

      print('عدد مواضع الجهاز في النتيجة: ${positionsList.length}');
      if (positionsList.isNotEmpty) {
        final parsed = positionsList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        parsed.sort((a, b) {
          final ta = DateTime.tryParse(a['fixTime']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final tb = DateTime.tryParse(b['fixTime']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
        final lastFive = parsed.length > 5 ? parsed.sublist(0, 5) : parsed;
        print('أحدث حتى 5 مواضع (مرتبة حسب fixTime تنازلياً):');
        for (final p in lastFive) {
          final pid = p['id'];
          final did = p['deviceId'];
          final lat = p['latitude'];
          final lon = p['longitude'];
          final fix = p['fixTime'] ?? p['deviceTime'];
          print(
            '  position id=$pid deviceId=$did lat=$lat lon=$lon fixTime=$fix',
          );
          if (debug) print(_jsonPretty(p));
        }

        final last = parsed.isNotEmpty ? parsed.first : null;
        if (last != null) {
          final lm = last;
          final plat = (lm['latitude'] as num?)?.toDouble();
          final plon = (lm['longitude'] as num?)?.toDouble();
          if (plat != null && plon != null) {
            final nearLastStep = motionSteps.last;
            final diffM =
                _haversineMeters(plat, plon, nearLastStep.lat, nearLastStep.lon);
            print(
              'آخر موضع: هل يقارب آخر نقطة مرسلة (${nearLastStep.label})؟ فرق ≈ ${diffM.toStringAsFixed(1)} m',
            );
          }
        }
      } else {
        print('لا توجد مواضع في الفترة — قد لا يكون OsmAnd قد وصل لنفس جهاز Traccar.');
      }

      print('');
      print('═══ GET /reports/events (نافذة موسّعة) ═══');
      print('from=$from');
      print('to=$to');

      final events = await getJsonList(
        '/reports/events?deviceId=$effectiveDeviceId&from=${Uri.encodeQueryComponent(from)}&to=${Uri.encodeQueryComponent(to)}',
      );

      print('إجمالي أحداث التقرير: ${events.length}');
      print('');
      print('═══ كل الأحداث الخام (دون فلترة) ═══');

      var enterCount = 0;
      var exitCount = 0;
      for (var i = 0; i < events.length; i++) {
        final e = events[i];
        if (e is! Map) {
          print('#$i: (غير Map) $e');
          continue;
        }
        final m = Map<String, dynamic>.from(e);
        final id = m['id'];
        final type = m['type'];
        final did = m['deviceId'];
        final gfid = m['geofenceId'];
        final et = m['eventTime'];
        final posId = m['positionId'];
        final attrs = m['attributes'];
        print(
          '#$i id=$id type=$type deviceId=$did geofenceId=$gfid eventTime=$et positionId=$posId',
        );
        if (attrs != null) {
          print('  attributes: ${_jsonPretty(attrs)}');
          if (attrs is Map && attrs['geofenceId'] != null) {
            print('  [ملحوظة] geofenceId داخل attributes: ${attrs['geofenceId']}');
          }
        }
        if (debug) print(_jsonPretty(m));

        final devId = _asInt(did);
        final rowGf = _asInt(gfid);
        int? attrGf;
        if (attrs is Map && attrs['geofenceId'] != null) {
          attrGf = _asInt(attrs['geofenceId']);
        }
        final matchesGf = rowGf == gid || attrGf == gid;

        if (devId == effectiveDeviceId) {
          if (type == 'geofenceEnter' && matchesGf) enterCount++;
          if (type == 'geofenceExit' && matchesGf) exitCount++;
        }
      }

      print('');
      print(
        'ملخص تطابق السياج $gid على هذا الجهاز: geofenceEnter=$enterCount geofenceExit=$exitCount',
      );

      final eventsOk = positionsSent && enterCount > 0 && exitCount > 0;

      final nids = List<int>.from(createdNotificationIds);
      createdGeofenceId = null;
      createdNotificationIds.clear();

      print('');
      print('— تنظيف الموارد —');
      for (final nid in nids.reversed) {
        await _deletePath(http, cookieJar, base, '/notifications/$nid');
        print('DELETE /notifications/$nid OK');
      }
      await _deletePath(http, cookieJar, base, '/geofences/$gid');
      print('DELETE /geofences/$gid OK');

      print('');
      if (!skipNotifications && !notificationGeofenceLinked) {
        print('نتيجة: فشل مسار الإشعارات — رمز 2');
        return 2;
      }
      if (!positionsSent) {
        print('نتيجة: تعذر إرسال OsmAnd — رمز 3');
        return 3;
      }
      if (!eventsOk) {
        print(
          'نتيجة: لم يُرصد Enter/Exit للسياج $gid في التقرير — رمز 4. '
          'راجع الطباعة الخام أعلاه، ومواضع الجهاز، وسجلات Traccar (معالجة السياج، بروتوكول osmand).',
        );
        return 4;
      }

      print(
        'SUCCESS: geofenceEnter و geofenceExit ثم التنظيف. (نافذة تقرير موسّعة + انتظار 60 ث)',
      );
      return 0;
    } else {
      print('تخطي إرسال المواقع: ربط الإشعارات غير مكتمل.');
      final nids = List<int>.from(createdNotificationIds);
      final gDel = createdGeofenceId;
      createdGeofenceId = null;
      createdNotificationIds.clear();
      for (final nid in nids.reversed) {
        await _deletePath(http, cookieJar, base, '/notifications/$nid');
        print('DELETE /notifications/$nid OK');
      }
      await _deletePath(http, cookieJar, base, '/geofences/$gDel');
      print('DELETE /geofences/$gDel OK');
      return 2;
    }
  } catch (e, st) {
    await cleanupOnError(e, st);
    return 1;
  } finally {
    client?.close(force: true);
  }
}

Future<void> main() async {
  exit(await _run());
}

String _deriveOsmAndBase(String apiBase) {
  var s = apiBase.trim();
  s = s.replaceAll(RegExp(r'/api/?$'), '');
  if (s.isEmpty) return apiBase;
  return s;
}

Future<void> _deletePath(
  HttpClient client,
  String cookieJar,
  String apiBase,
  String path,
) async {
  final root = apiBase.replaceAll(RegExp(r'/$'), '');
  final uri = Uri.parse('$root$path');
  final req = await client.openUrl('DELETE', uri);
  req.headers.set(HttpHeaders.acceptHeader, 'application/json');
  if (cookieJar.isNotEmpty) {
    req.headers.set(HttpHeaders.cookieHeader, cookieJar);
  }
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw HttpException('HTTP ${res.statusCode}: $text');
  }
  if (text.trim().isNotEmpty) {
    // قد يكون JSON
  }
}

Future<void> _sendOsmAndPosition({
  required HttpClient client,
  required String baseUrl,
  required String uniqueId,
  required double latitude,
  required double longitude,
  required int timestampSec,
}) async {
  final base = Uri.parse(baseUrl);
  var path = base.path;
  if (path.isEmpty || path == '/') {
    path = '/';
  }
  final uri = Uri(
    scheme: base.scheme.isEmpty ? 'https' : base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: path,
    queryParameters: <String, String>{
      'id': uniqueId,
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'timestamp': timestampSec.toString(),
      'valid': 'true',
    },
  );

  final req = await client.getUrl(uri);
  final res = await req.close();
  await res.drain<void>();
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw HttpException(
      'OsmAnd HTTP ${res.statusCode} لـ ${uri.scheme}://${uri.host}${uri.path}',
    );
  }
}
