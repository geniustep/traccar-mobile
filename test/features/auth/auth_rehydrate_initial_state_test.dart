import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/features/auth/presentation/providers/auth_provider.dart';

void main() {
  test('AuthState default for notifier constructor is loading', () {
    const initial = AuthState(isLoading: true);
    expect(initial.isLoading, isTrue);
    expect(initial.isAuthenticated, isFalse);
  });
}
