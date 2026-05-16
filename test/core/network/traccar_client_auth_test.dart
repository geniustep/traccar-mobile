import 'package:dio/dio.dart';
import 'package:elmogps/core/error/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('401 handling', () {
    test('AppException.fromStatusCode(401) is AuthException', () {
      final ex = AppException.fromStatusCode(401);
      expect(ex, isA<AuthException>());
    });

    test('DioException badResponse with 401 maps via fromStatusCode', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/alerts/'),
        response: Response(
          requestOptions: RequestOptions(path: '/alerts/'),
          statusCode: 401,
          data: 'Unauthorized',
        ),
        type: DioExceptionType.badResponse,
      );
      final ex = AppException.fromStatusCode(
        dioEx.response!.statusCode!,
      );
      expect(ex, isA<AuthException>());
    });
  });
}
