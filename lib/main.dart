import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Pre-warm SharedPreferences before the widget tree builds
  final container = ProviderContainer();
  try {
    await container.read(sharedPreferencesProvider.future);
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElmoApp(),
    ),
  );
}
