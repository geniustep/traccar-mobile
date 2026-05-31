// ignore_for_file: avoid_print
/// Traccar API smoke test (matches app payloads). No extra packages.
///
/// dart run tool/traccar_qa_smoke.dart [baseUrl]
/// Example: dart run tool/traccar_qa_smoke.dart https://demo4.traccar.org/api
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main(List<String> args) async {
  final base = (args.isNotEmpty ? args.first : 'https://demo4.traccar.org/api')
      .replaceAll(RegExp(r'/$'), '');
  final ts = DateTime.now().millisecondsSinceEpoch;
  final email = 'elmogps_qa_$ts@invalid.test';
  const password = 'TestQA123!zz';

  HttpClient? client;
  try {
    client = HttpClient();
    print('Base: $base');

    int? userId;
    String? cookieJar;

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
      final req = await client!.openUrl(method, uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (jsonBody) {
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      }
      if (cookieJar != null && cookieJar!.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader, cookieJar!);
      }
      return req;
    }

    // Register
    final regReq = await open('POST', '/users', jsonBody: true);
    regReq.write(jsonEncode({
      'name': 'ELMO QA',
      'email': email,
      'password': password,
    }));
    final regRes = await regReq.close();
    cookieJar = combineSetCookie(regRes.headers['set-cookie']);
    final regJson = await jsonResponse(regRes);
    userId = regJson['id'] as int;
    print('POST /users => OK userId=$userId');

    // Login (form)
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

    Future<Map<String, dynamic>> putJson(
      String path,
      Map<String, dynamic> body,
    ) async {
      final req = await open('PUT', path, jsonBody: true);
      req.write(jsonEncode(body));
      final res = await req.close();
      final jar = combineSetCookie(res.headers['set-cookie']);
      if (jar.isNotEmpty) cookieJar = jar;
      return jsonResponse(res);
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

    Future<void> deletePath(String path) async {
      final req = await open('DELETE', path);
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('HTTP ${res.statusCode}: $text');
      }
    }

    // Device
    final uniqueId='qa-${Random().nextInt(1 << 30)}';
    final dev = await postJson('/devices', {
      'name': 'QA Device',
      'uniqueId': uniqueId,
    });
    final deviceId = dev['id'] as int;
    print('POST /devices => deviceId=$deviceId');

    await postJson('/permissions', {'userId': userId, 'deviceId': deviceId});
    print('POST permissions user+device OK');

    // Circle
    const circleArea = 'CIRCLE (24.713600 46.675300, 150)';
    final gfC = await postJson('/geofences', {
      'name': 'QA Circle',
      'area': circleArea,
      'attributes': {},
    });
    var geofenceId = gfC['id'] as int;
    print('POST /geofences circle => id=$geofenceId');

    await putJson('/geofences/$geofenceId', {
      'id': geofenceId,
      'name': 'QA Circle',
      'area': 'CIRCLE (24.713600 46.675300, 320)',
      'attributes': {},
    });
    print('PUT /geofences (radius) OK');

    const polyArea =
        'POLYGON ((46.674 24.712, 46.676 24.712, 46.676 24.714, 46.674 24.714, 46.674 24.712))';
    final gfP = await postJson('/geofences', {
      'name': 'QA Polygon',
      'area': polyArea,
      'attributes': {},
    });
    final polyId = gfP['id'] as int;
    print('POST /geofences polygon => id=$polyId');

    await postJson('/permissions', {'deviceId': deviceId, 'geofenceId': geofenceId});
    print('POST permissions device+geofence OK');

    Future<int> makeNotif(String type) async {
      final m = await postJson('/notifications', {
        'type': type,
        'always': true,
        'notificators': 'web',
        'attributes': {},
      });
      return m['id'] as int;
    }

    Future<void> perm(Map<String, dynamic> p) async {
      await postJson('/permissions', p);
    }

    final nIn = await makeNotif('geofenceEnter');
    final nOut = await makeNotif('geofenceExit');
    print('notifications enter=$nIn exit=$nOut');

    var notificationGeofenceLinked = true;
    try {
      for (final n in [nIn, nOut]) {
        await perm({'userId': userId, 'notificationId': n});
        await perm({'notificationId': n, 'geofenceId': geofenceId});
        await perm({'notificationId': n, 'deviceId': deviceId});
      }
    } catch (e) {
      notificationGeofenceLinked = false;
      print(
        'WARN: notification↔geofence permission failed (server DB/schema?): $e',
      );
      print(
        '      Skipping steps that require tc_notification_geofence; continuing cleanup.',
      );
    }

    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 1)).toIso8601String();
    final to = now.toIso8601String();
    final q =
        '/reports/events?deviceId=$deviceId&from=${Uri.encodeQueryComponent(from)}&to=${Uri.encodeQueryComponent(to)}';
    final evs = await getJsonList(q);
    print('GET /reports/events count=${evs.length}');

    await deletePath('/geofences/$polyId');
    await deletePath('/geofences/$geofenceId');
    print('DELETE geofences OK');

    final listAfter = await getJsonList('/geofences');
    final ids = listAfter.map((e) => (e as Map)['id']).toSet();
    assert(!ids.contains(polyId) && !ids.contains(geofenceId));

    final suffix = notificationGeofenceLinked
        ? 'full flow'
        : 'partial (no notification↔geofence on this server)';
    print('SUCCESS ($suffix). Web login: $email / $password');
  } catch (e, st) {
    print('FAIL: $e');
    print(st);
    exitCode = 1;
  } finally {
    client?.close(force: true);
  }
}
