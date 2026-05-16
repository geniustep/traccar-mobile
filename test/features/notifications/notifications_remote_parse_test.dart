import 'package:elmogps/core/error/app_exception.dart';
import 'package:elmogps/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationsRemoteDataSource._parseMapList', () {
    test('empty/null input returns empty list', () {
      expect(NotificationsRemoteDataSource.parseMapListForTest(null), isEmpty);
      expect(NotificationsRemoteDataSource.parseMapListForTest([]), isEmpty);
    });

    test('non-list JSON throws ParseException not FormatException', () {
      expect(
        () => NotificationsRemoteDataSource.parseMapListForTest(
          <String, dynamic>{'error': 'unauthorized'},
        ),
        throwsA(isA<ParseException>()),
      );
    });
  });
}
