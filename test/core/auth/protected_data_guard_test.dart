import 'package:elmogps/core/auth/protected_data_guard.dart';
import 'package:elmogps/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canLoadProtectedData', () {
    test('returns false when not authenticated', () {
      expect(
        canLoadProtectedData(const AuthState(isAuthenticated: false)),
        isFalse,
      );
    });

    test('returns false while auth is loading', () {
      expect(
        canLoadProtectedData(
          const AuthState(isAuthenticated: true, isLoading: true),
        ),
        isFalse,
      );
    });

    test('returns true when authenticated and not loading', () {
      expect(
        canLoadProtectedData(
          const AuthState(isAuthenticated: true, isLoading: false),
        ),
        isTrue,
      );
    });
  });
}
