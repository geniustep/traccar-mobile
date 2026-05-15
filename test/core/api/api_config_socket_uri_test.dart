import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/api/api_config.dart';

void main() {
  group('ApiConfig.buildSocketUri', () {
    test('production https → wss without port', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
      );
      expect(uri.toString(), 'wss://api.elmogps.com/socket');
      expect(uri.scheme, 'wss');
      expect(uri.host, 'api.elmogps.com');
      expect(uri.toString().contains(':0'), isFalse);
    });

    test('configured wss URL is preserved', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
        configuredSocketUrl: 'wss://api.elmogps.com/socket',
      );
      expect(uri.toString(), 'wss://api.elmogps.com/socket');
    });

    test('does NOT add :0 port', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
      );
      expect(uri.toString().contains(':0'), isFalse);
    });

    test('preserves real port (e.g. 8082 in dev)', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('http://10.0.2.2:8082'),
        path: '/api/socket',
      );
      expect(uri.scheme, 'ws');
      expect(uri.port, 8082);
      expect(uri.toString(), 'ws://10.0.2.2:8082/api/socket');
    });

    test('http base → ws scheme', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('http://localhost'),
      );
      expect(uri.scheme, 'ws');
    });

    test('https base → wss scheme', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://example.com'),
      );
      expect(uri.scheme, 'wss');
    });

    test('omits default port 443 for wss', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com:443'),
      );
      expect(uri.toString().contains(':443'), isFalse);
      expect(uri.toString(), 'wss://api.elmogps.com/socket');
    });

    test('omits default port 80 for ws', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('http://localhost:80'),
      );
      expect(uri.toString().contains(':80'), isFalse);
    });

    test('appends token query parameter', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
        token: 'abc123xyz',
      );
      expect(uri.queryParameters['token'], 'abc123xyz');
      expect(uri.toString(), contains('?token=abc123xyz'));
    });

    test('no token → no query params', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://api.elmogps.com'),
      );
      expect(uri.queryParameters, isEmpty);
      expect(uri.toString().contains('?'), isFalse);
    });

    test('configured socket URL with explicit path is kept', () {
      final uri = ApiConfig.buildSocketUri(
        Uri.parse('https://traccar.example.com'),
        configuredSocketUrl: 'wss://traccar.example.com/api/socket',
      );
      expect(uri.path, '/api/socket');
      expect(uri.scheme, 'wss');
    });

    test('handles URI parsed from string with port 0 gracefully', () {
      // Simulates Uri(scheme: 'https', host: 'api.elmogps.com', port: 0)
      final base = Uri(
        scheme: 'https',
        host: 'api.elmogps.com',
        port: 0,
        path: '/socket',
      );
      final uri = ApiConfig.buildSocketUri(base);
      expect(uri.toString().contains(':0'), isFalse);
      expect(uri.scheme, 'wss');
    });
  });
}
