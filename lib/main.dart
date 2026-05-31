import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'shared/providers/core_providers.dart' show sharedPreferencesProvider;
import 'shared/providers/traccar_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  for (final locale in ['en', 'ar', 'fr', 'es']) {
    await initializeDateFormatting(locale);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  final container = ProviderContainer(
    overrides: [
      traccarSocketServiceProvider.overrideWith(
        (ref) => ref.read(concreteSocketServiceProvider),
      ),
    ],
  );
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
