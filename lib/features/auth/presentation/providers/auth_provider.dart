import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../shared/providers/core_providers.dart';

// ── Shared Prefs ─────────────────────────────────────────────────────────────

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// ── Repository ───────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  if (prefs == null) throw StateError('SharedPreferences not ready');
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.read(traccarClientProvider)),
    ref.read(secureStorageServiceProvider),
    prefs,
  );
});

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final cached = await _repository.getCachedUser();
      state = state.copyWith(
        isAuthenticated: true,
        user: cached,
        isLoading: false,
      );
      // Refresh user in background
      _refreshUser();
    } else {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> _refreshUser() async {
    try {
      final user = await _repository.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (user, _, __) = await _repository.login(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e, stack) {
      debugPrint('[Auth] Login failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: stack, label: '[Auth]');

      state = state.copyWith(
        isLoading: false,
        error: _friendlyMessage(e),
      );
      return false;
    }
  }

  /// Converts any thrown error into a user-readable message.
  static String _friendlyMessage(Object e) {
    // AppException thrown by getOrThrow() in data-sources
    if (e is AppException) return _fromAppException(e);

    // DioException from direct _client.dio calls (e.g. login).
    // ErrorInterceptor wraps the AppException into DioException.error.
    if (e is DioException) {
      if (e.error is AppException) {
        return _fromAppException(e.error as AppException);
      }
      return e.message ?? 'Connection error. Please try again.';
    }

    // Legacy NetworkException
    if (e is NetworkException) {
      return switch (e.code) {
        'NO_CONNECTION'      => 'No internet connection. Check your network.',
        'TIMEOUT'            => 'Connection timed out. Is the server reachable?',
        'CANCELLED'          => 'Request was cancelled.',
        'UNAUTHORIZED'       => 'Incorrect email or password.',
        'FORBIDDEN'          => 'Your account does not have access.',
        'NOT_FOUND'          => 'Endpoint not found. Check the API path.',
        'SERVER_ERROR'       => 'Server error. Please try again later.',
        'UNAVAILABLE'        => 'Service is temporarily unavailable.',
        _                    => e.message,
      };
    }

    // Fallback — strip Dart's default "Exception: " prefix
    final raw = e.toString();
    return raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
  }

  static String _fromAppException(AppException e) => switch (e.code) {
        'UNAUTHORIZED'  => 'Incorrect email or password.',
        'FORBIDDEN'     => 'Your account does not have access.',
        'NO_CONNECTION' => 'No internet connection. Check your network.',
        'TIMEOUT'       => 'Connection timed out. Is the server reachable?',
        'NOT_FOUND'     => 'Endpoint not found. Check the server configuration.',
        'SERVER_ERROR'  => 'Server error. Please try again later.',
        'CANCELLED'     => 'Request was cancelled.',
        _               => e.message,
      };

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});
