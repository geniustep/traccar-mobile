// ignore_for_file: avoid_print
/// اختبار شبه آلية لمرحلة Phase 5 (سائقون + صيانة + صلاحيات) على خادم Traccar حقيقي.
///
/// متغيرات بيئة (لا تُخزَّن في الكود):
/// - [TRACCAR_URL] — كما في سكربت السياج: لـ ELMOGPS غالباً بدون لاحقة `/api`
///   (مثل `https://api.elmogps.com`). يُزال الشرط المائل فقط.
/// - [TRACCAR_EMAIL] ، [TRACCAR_PASSWORD]
/// - [TEST_DEVICE_ID] — معرف جهاز Traccar الداخلي أو `uniqueId`
///
/// تشغيل: `dart run tool/traccar_phase5_qa.dart`
library traccar_phase5_qa;

import 'dart:convert';
import 'dart:io';

const String _kElmoPhone = 'elmoPhone';
const String _kElmoLicense = 'elmoLicenseNumber';
const String _kElmoLicenseExpiry = 'elmoLicenseExpiryDate';
const String _kElmoMaintDeviceId = 'elmoDeviceId';
const String _kElmoMaintType = 'elmoMaintenanceType';
const String _kElmoDueDate = 'elmoDueDate';
const String _kMaintCodeOil = 'oil_change';

String _normalizeApiBase(String raw) =>
    raw.trim().replaceAll(RegExp(r'/$'), '');

String _dateOnlyIso(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).toIso8601String().split('T').first;

/// يطابق [DriverLicenseStatus.fromExpiry] في التطبيق (مقارنة بالأيام UTC فقط).
String _licenseStatusLabel(DateTime? expiry, DateTime ref) {
  if (expiry == null) return 'unknown';
  final exp = DateTime.utc(expiry.year, expiry.month, expiry.day);
  final r = DateTime.utc(ref.year, ref.month, ref.day);
  if (exp.isBefore(r)) return 'expired';
  final delta = exp.difference(r).inDays;
  if (delta <= 30) return 'expiringSoon';
  return 'valid';
}

/// يطابق [ElmoMaintenanceSeverity.fromDueDateOnly].
String _maintDateSeverity(DateTime? due, DateTime ref) {
  if (due == null) return 'unknown';
  final dueUtc = DateTime.utc(due.year, due.month, due.day);
  final refUtc = DateTime.utc(ref.year, ref.month, ref.day);
  if (dueUtc.isBefore(refUtc)) return 'overdue';
  final delta = dueUtc.difference(refUtc).inDays;
  if (delta <= 30) return 'soon';
  return 'upcoming';
}

DateTime? _parseAttrDate(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  if (s.isEmpty) return null;
  if (s.contains('T')) return DateTime.tryParse(s)?.toUtc();
  return DateTime.tryParse('${s}T00:00:00Z');
}

Future<int> phase5ExitCode(List<String> args) async {
  final env = Platform.environment;
  final baseRaw =
      env['TRACCAR_URL'] ?? (args.isNotEmpty ? args.first : null);
  final email = env['TRACCAR_EMAIL'];
  final password = env['TRACCAR_PASSWORD'];
  final deviceRaw = env['TEST_DEVICE_ID'];

  if (baseRaw == null ||
      baseRaw.isEmpty ||
      email == null ||
      email.isEmpty ||
      password == null ||
      password.isEmpty ||
      deviceRaw == null ||
      deviceRaw.isEmpty) {
    stderr.writeln(
      'تعذّر التشغيل: عيّن TRACCAR_URL و TRACCAR_EMAIL و '
      'TRACCAR_PASSWORD و TEST_DEVICE_ID (أو مرِّر عنوان الأساس كوسيط أول).\n'
      'مثال PowerShell:\n'
      r'  $env:TRACCAR_URL="https://api.elmogps.com"'
      '\n'
      r'  $env:TRACCAR_EMAIL="..."'
      '\n'
      r'  $env:TRACCAR_PASSWORD="..."'
      '\n'
      r'  $env:TEST_DEVICE_ID="5"'
      '\n'
      '  dart run tool/traccar_phase5_qa.dart',
    );
    return 2;
  }

  final apiBase = _normalizeApiBase(baseRaw);
  final results = <String, bool>{};
  void ok(String id, bool v) {
    results[id] = v;
    print(v ? '[✓] $id' : '[✗] $id');
  }

  HttpClient? client;
  var cookieJar = '';
  final createdDriverIds = <int>[];
  final createdMaintenanceIds = <int>[];
  final permissionLinks = <List<int>>[]; // [driverId, deviceId]

  String combineSetCookie(List<String>? setCookies) {
    if (setCookies == null) return '';
    final buf = StringBuffer();
    for (final line in setCookies) {
      final part = line.split(';').first.trim();
      if (part.isNotEmpty) buf.write('$part; ');
    }
    return buf.toString();
  }

  Future<Map<String, dynamic>> jsonObj(HttpClientResponse r) async {
    final text = await r.transform(utf8.decoder).join();
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('HTTP ${r.statusCode}: $text');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return {};
    final dec = jsonDecode(trimmed);
    if (dec is Map<String, dynamic>) return dec;
    if (dec is Map) return Map<String, dynamic>.from(dec);
    throw FormatException('توقَّع كائناً: $trimmed');
  }

  Future<List<dynamic>> jsonList(HttpClientResponse r) async {
    final text = await r.transform(utf8.decoder).join();
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw HttpException('HTTP ${r.statusCode}: $text');
    }
    return jsonDecode(text) as List<dynamic>;
  }

  Future<HttpClientRequest> openReq(
    String method,
    String path, {
    bool jsonBody = false,
  }) async {
    final uri = Uri.parse('$apiBase$path');
    final req = await client!.openUrl(method, uri);
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
    final req = await openReq('POST', path, jsonBody: true);
    req.write(jsonEncode(body));
    final res = await req.close();
    final jar = combineSetCookie(res.headers['set-cookie']);
    if (jar.isNotEmpty) cookieJar = jar;
    return jsonObj(res);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final req = await openReq('PUT', path, jsonBody: true);
    req.write(jsonEncode(body));
    final res = await req.close();
    final jar = combineSetCookie(res.headers['set-cookie']);
    if (jar.isNotEmpty) cookieJar = jar;
    return jsonObj(res);
  }

  Future<void> deletePath(String path) async {
    final req = await openReq('DELETE', path);
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}: $text');
    }
  }

  Future<void> deleteJsonBody(
    String path,
    Map<String, dynamic> body,
  ) async {
    final req = await openReq('DELETE', path, jsonBody: true);
    req.write(jsonEncode(body));
    final res = await req.close();
    final txt = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}: $txt');
    }
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final req = await openReq('GET', path);
    final res = await req.close();
    final jar = combineSetCookie(res.headers['set-cookie']);
    if (jar.isNotEmpty) cookieJar = jar;
    return jsonObj(res);
  }

  Future<List<dynamic>> getList(String path) async {
    final req = await openReq('GET', path);
    final res = await req.close();
    final jar = combineSetCookie(res.headers['set-cookie']);
    if (jar.isNotEmpty) cookieJar = jar;
    return jsonList(res);
  }

  Future<void> cleanupQuiet() async {
    if (client == null) return;
    for (final mid in createdMaintenanceIds.reversed) {
      try {
        await deletePath('/maintenance/$mid');
        print('[تنظيف] حُذفت صيانة $mid');
      } catch (e) {
        print('[تنظيف] صيانة $mid: $e');
      }
    }
    createdMaintenanceIds.clear();
    for (final pair in permissionLinks.reversed) {
      try {
        await deleteJsonBody('/permissions', {
          'deviceId': pair[1],
          'driverId': pair[0],
        });
        print('[تنظيف] صلاحية driver=${pair[0]} device=${pair[1]}');
      } catch (e) {
        print('[تنظيف] صلاحية: $e');
      }
    }
    permissionLinks.clear();
    for (final did in createdDriverIds.reversed) {
      try {
        await deletePath('/drivers/$did');
        print('[تنظيف] حُذف سائق $did');
      } catch (e) {
        print('[تنظيف] سائق $did: $e');
      }
    }
    createdDriverIds.clear();
  }

  try {
    client = HttpClient();
    print('API base: $apiBase');

    final sessReq = await openReq('POST', '/session');
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
    await jsonObj(sessRes);
    ok('session_login', true);

    int effectiveDeviceId;
    final trimmedDev = deviceRaw.trim();
    final parsedDev = int.tryParse(trimmedDev);
    if (parsedDev != null) {
      final m = await getMap('/devices/$parsedDev');
      effectiveDeviceId = (m['id'] as num).toInt();
    } else {
      final devices = await getList('/devices');
      Map<String, dynamic>? found;
      for (final row in devices) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final uid = m['uniqueId']?.toString() ?? '';
        if (uid == trimmedDev) {
          found = m;
          break;
        }
      }
      if (found == null) {
        throw StateError('لا جهاز يطابق TEST_DEVICE_ID="$trimmedDev"');
      }
      effectiveDeviceId = (found['id'] as num).toInt();
    }
    print('جهاز الاختبار id=$effectiveDeviceId');
    ok('resolve_test_device', true);

    final now = DateTime.now().toUtc();
    final ts = now.millisecondsSinceEpoch;

    final dMain = await postJson('/drivers', {
      'name': 'QA Phase5 main $ts',
      'uniqueId': 'ELMO_QA_MAIN_$ts',
      'attributes': <String, dynamic>{},
    });
    final idMain = (dMain['id'] as num).toInt();
    createdDriverIds.add(idMain);

    await putJson('/drivers/$idMain', {
      'id': idMain,
      'name': 'QA Phase5 main patched $ts',
      'uniqueId': 'ELMO_QA_MAIN_$ts',
      'attributes': {
        _kElmoPhone: '+212600000001',
        _kElmoLicense: 'LIC-$ts',
        _kElmoLicenseExpiry: _dateOnlyIso(now.add(const Duration(days: 400))),
      },
    });
    final dMainFetched = await getMap('/drivers/$idMain');
    final attrsMain =
        Map<String, dynamic>.from(dMainFetched['attributes'] as Map? ?? {});
    ok(
      'driver_create_edit_phone_license_expiry',
      attrsMain[_kElmoPhone] != null &&
          attrsMain[_kElmoLicense] != null &&
          attrsMain[_kElmoLicenseExpiry] != null &&
          '${dMainFetched['name']}'.contains('patched'),
    );

    final expSoon = DateTime.utc(now.year, now.month, now.day)
        .add(const Duration(days: 20));
    final dSoon = await postJson('/drivers', {
      'name': 'QA license soon $ts',
      'uniqueId': 'ELMO_QA_SOON_$ts',
      'attributes': {_kElmoLicenseExpiry: _dateOnlyIso(expSoon)},
    });
    createdDriverIds.add((dSoon['id'] as num).toInt());
    final stSoon =
        _licenseStatusLabel(_parseAttrDate(_dateOnlyIso(expSoon)), now);
    ok('driver_license_expiring_soon_expected', stSoon == 'expiringSoon');

    final expPast =
        DateTime.utc(now.year, now.month, now.day)
            .subtract(const Duration(days: 5));
    final dPast = await postJson('/drivers', {
      'name': 'QA license expired $ts',
      'uniqueId': 'ELMO_QA_EXP_$ts',
      'attributes': {_kElmoLicenseExpiry: _dateOnlyIso(expPast)},
    });
    createdDriverIds.add((dPast['id'] as num).toInt());
    final stPast =
        _licenseStatusLabel(_parseAttrDate(_dateOnlyIso(expPast)), now);
    ok('driver_license_expired_expected', stPast == 'expired');

    await postJson('/permissions', {
      'deviceId': effectiveDeviceId,
      'driverId': idMain,
    });
    permissionLinks.add([idMain, effectiveDeviceId]);
    ok('driver_device_permission_post', true);
    ok(
      'driver_fetch_after_link',
      (await getMap('/drivers/$idMain'))['id'] != null,
    );
    ok('driver_linked_api_ok', true);

    Map<String, dynamic> maintPayload(String nameSuffix, DateTime due) => {
          'name': 'QA Maint $nameSuffix $ts',
          'type': 'mileage',
          'start': 0.0,
          'period': 999999.0,
          'attributes': {
            _kElmoMaintDeviceId: effectiveDeviceId,
            _kElmoMaintType: _kMaintCodeOil,
            _kElmoDueDate: _dateOnlyIso(due),
          },
        };

    final due60 = DateTime.utc(now.year, now.month, now.day)
        .add(const Duration(days: 60));
    final due15 = DateTime.utc(now.year, now.month, now.day)
        .add(const Duration(days: 15));
    final dueOld = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    final m1 = await postJson('/maintenance', maintPayload('up60', due60));
    final m2 = await postJson('/maintenance', maintPayload('soon15', due15));
    final m3 = await postJson('/maintenance', maintPayload('over', dueOld));

    final mid1 = (m1['id'] as num).toInt();
    final mid2 = (m2['id'] as num).toInt();
    final mid3 = (m3['id'] as num).toInt();
    createdMaintenanceIds.addAll([mid1, mid2, mid3]);

    final attrs1 =
        Map<String, dynamic>.from(m1['attributes'] as Map? ?? {});
    ok(
      'maintenance_upcoming_60d',
      _maintDateSeverity(_parseAttrDate(attrs1[_kElmoDueDate]), now) ==
          'upcoming',
    );
    final attrs2 =
        Map<String, dynamic>.from(m2['attributes'] as Map? ?? {});
    ok(
      'maintenance_soon_15d',
      _maintDateSeverity(_parseAttrDate(attrs2[_kElmoDueDate]), now) ==
          'soon',
    );
    final attrs3 =
        Map<String, dynamic>.from(m3['attributes'] as Map? ?? {});
    ok(
      'maintenance_overdue_past',
      _maintDateSeverity(_parseAttrDate(attrs3[_kElmoDueDate]), now) ==
          'overdue',
    );
    final devAttr = attrs1[_kElmoMaintDeviceId];
    ok(
      'maintenance_linked_device_id_matches',
      devAttr != null && (devAttr as num).toInt() == effectiveDeviceId,
    );

    await deletePath('/drivers/${createdDriverIds.removeLast()}');
    await deletePath('/drivers/${createdDriverIds.removeLast()}');
    ok('driver_delete_two_ok', true);

    await deletePath('/maintenance/$mid3');
    await deletePath('/maintenance/$mid2');
    await deletePath('/maintenance/$mid1');
    createdMaintenanceIds.clear();
    ok('maintenance_delete_all_three_ok', true);

    await deleteJsonBody('/permissions', {
      'deviceId': effectiveDeviceId,
      'driverId': idMain,
    });
    permissionLinks.clear();
    ok('permission_driver_device_removed', true);

    await deletePath('/drivers/$idMain');
    createdDriverIds.remove(idMain);
    ok('driver_main_deleted_ok', createdDriverIds.isEmpty);

    try {
      await getList('/geofences');
      ok('regression_geofences_list_http_ok', true);
    } catch (e) {
      ok('regression_geofences_list_http_ok', false);
      print('  geofences: $e');
    }

    try {
      await getList('/devices');
      ok('regression_devices_list_http_ok', true);
    } catch (e) {
      ok('regression_devices_list_http_ok', false);
      print('  devices: $e');
    }

    try {
      final from =
          now.subtract(const Duration(days: 1)).toUtc().toIso8601String();
      final tr = now.toUtc().toIso8601String();
      await getList(
        '/reports/route?deviceId=$effectiveDeviceId'
        '&from=${Uri.encodeQueryComponent(from)}'
        '&to=${Uri.encodeQueryComponent(tr)}',
      );
      ok('regression_reports_route_http_ok', true);
    } catch (e) {
      ok('regression_reports_route_http_ok', false);
      print('  reports/route: $e');
    }

    print('');
    print('— ملخص —');
    var failed = 0;
    for (final e in results.entries) {
      if (!e.value) failed++;
      print('  ${e.value ? '✓' : '✗'} ${e.key}');
    }
    print(failed == 0
        ? '\nجميع نقاط QA الشبكية لم تُسجَّل أي فشلاً فوريًّا.'
        : '\nفشل عدد الفحوص غير الموافقة: $failed');
    final code = failed == 0 ? 0 : 1;
    client.close(force: true);
    client = null;
    return code;
  } catch (e, st) {
    print('خطأ أثناء QA: $e');
    print(st);
    try {
      await cleanupQuiet();
    } catch (_) {}
    client?.close(force: true);
    return 3;
  }
}

Future<void> main(List<String> args) async => exit(await phase5ExitCode(args));
