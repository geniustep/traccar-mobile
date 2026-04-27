import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../shared/providers/traccar_providers.dart';
import 'router.dart';
import 'socket_event_listener.dart';

class ElmoApp extends ConsumerWidget {
  const ElmoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(socketAuthSyncProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'ELMO Fleet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(isArabic: isArabic),
      darkTheme: AppTheme.dark(isArabic: isArabic),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) =>
          SocketEventListener(child: child),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
