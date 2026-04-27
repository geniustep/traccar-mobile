import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null && ['en', 'ar', 'fr', 'es'].contains(saved)) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

/// Supported locales with metadata.
const supportedLocales = [
  _LocaleInfo(Locale('en'), 'English', 'English', '🇬🇧'),
  _LocaleInfo(Locale('ar'), 'العربية', 'Arabic', '🇸🇦'),
  _LocaleInfo(Locale('fr'), 'Français', 'French', '🇫🇷'),
  _LocaleInfo(Locale('es'), 'Español', 'Spanish', '🇪🇸'),
];

class _LocaleInfo {
  const _LocaleInfo(this.locale, this.nativeName, this.englishName, this.flag);
  final Locale locale;
  final String nativeName;
  final String englishName;
  final String flag;
}

/// Public view of locale metadata.
class LocaleInfo {
  const LocaleInfo({
    required this.locale,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });
  final Locale locale;
  final String nativeName;
  final String englishName;
  final String flag;
}

const List<LocaleInfo> appSupportedLocales = [
  LocaleInfo(
    locale: Locale('en'),
    nativeName: 'English',
    englishName: 'English',
    flag: '🇬🇧',
  ),
  LocaleInfo(
    locale: Locale('ar'),
    nativeName: 'العربية',
    englishName: 'Arabic',
    flag: '🇸🇦',
  ),
  LocaleInfo(
    locale: Locale('fr'),
    nativeName: 'Français',
    englishName: 'French',
    flag: '🇫🇷',
  ),
  LocaleInfo(
    locale: Locale('es'),
    nativeName: 'Español',
    englishName: 'Spanish',
    flag: '🇪🇸',
  ),
];
