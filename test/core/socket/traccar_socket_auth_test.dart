import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/api/api_config.dart';
import 'package:elmogps/core/socket/traccar_socket_service.dart';

void main() {
  group('SocketAuthMode', () {
    test('has sessionCookieHeader, sessionQueryFallback, token, and none values', () {
      expect(SocketAuthMode.values.length, 4);
      expect(SocketAuthMode.sessionCookieHeader.name, 'sessionCookieHeader');
      expect(SocketAuthMode.sessionQueryFallback.name, 'sessionQueryFallback');
      expect(SocketAuthMode.token.name, 'token');
      expect(SocketAuthMode.none.name, 'none');
    });
  });

  group('WebSocket URL with token mode', () {
    test('token is appended as query parameter', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
        token: 'my_test_token',
      );
      expect(uri.toString(), contains('?token=my_test_token'));
      expect(uri.scheme, 'wss');
      expect(uri.host, 'api.elmogps.com');
      expect(uri.path, '/socket');
    });

    test('session cookie mode does not add token to URL', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
      );
      expect(uri.toString().contains('token='), isFalse);
    });
  });

  group('WebSocket URL never contains :0', () {
    test('from https base without port', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
      );
      expect(uri.toString().contains(':0'), isFalse);
    });

    test('from wss configured URL without port', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
        configuredSocketUrl: 'wss://api.elmogps.com/socket',
      );
      expect(uri.toString().contains(':0'), isFalse);
    });

    test('from explicit port 0', () {
      final base = Uri(
        scheme: 'https',
        host: 'api.elmogps.com',
        port: 0,
      );
      final uri = ApiConfig.buildSocketUri(base);
      expect(uri.toString().contains(':0'), isFalse);
    });
  });

  group('Production URL expectations', () {
    test('final URL is exactly wss://api.elmogps.com/socket', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
        configuredSocketUrl: 'wss://api.elmogps.com/socket',
      );
      expect(uri.toString(), 'wss://api.elmogps.com/socket');
    });

    test('dev URL preserves non-default port', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('http://10.0.2.2:8082'),
        path: '/api/socket',
      );
      expect(uri.toString(), 'ws://10.0.2.2:8082/api/socket');
      expect(uri.port, 8082);
    });
  });
}
