import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(String key) =>
      _strings[locale.languageCode]?[key] ?? _strings['en']![key] ?? key;

  // ── App ────────────────────────────────────────────────────────────────────
  String get appName => _t('appName');

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome => _t('navHome');
  String get navFleet => _t('navFleet');
  String get navMap => _t('navMap');
  String get navAlerts => _t('navAlerts');
  String get navProfile => _t('navProfile');

  // ── Settings ───────────────────────────────────────────────────────────────
  String get settingsTitle => _t('settingsTitle');
  String get sectionFleet => _t('sectionFleet');
  String get sectionPreferences => _t('sectionPreferences');
  String get sectionAccount => _t('sectionAccount');
  String get vehicles => _t('vehicles');
  String get liveMap => _t('liveMap');
  String get analytics => _t('analytics');
  String get notifications => _t('notifications');
  String get language => _t('language');
  String get appearance => _t('appearance');
  String get aboutElmo => _t('aboutElmo');
  String get signOut => _t('signOut');
  String get version => _t('version');
  String get editProfile => _t('editProfile');
  String get notificationsEnabled => _t('notificationsEnabled');
  String get notificationsSubtitle => _t('notificationsSubtitle');
  String get privacyPolicy => _t('privacyPolicy');
  String get helpSupport => _t('helpSupport');

  // ── Theme ──────────────────────────────────────────────────────────────────
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get themeSystem => _t('themeSystem');

  // ── Auth ───────────────────────────────────────────────────────────────────
  String get welcomeBack => _t('welcomeBack');
  String get signInSubtitle => _t('signInSubtitle');
  String get emailLabel => _t('emailLabel');
  String get passwordLabel => _t('passwordLabel');
  String get signInButton => _t('signInButton');

  // ── Dialog ─────────────────────────────────────────────────────────────────
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get signOutTitle => _t('signOutTitle');
  String get signOutMessage => _t('signOutMessage');

  // ── Dashboard ──────────────────────────────────────────────────────────────
  String get fleetOverview => _t('fleetOverview');
  String get goodMorning => _t('goodMorning');
  String get goodAfternoon => _t('goodAfternoon');
  String get goodEvening => _t('goodEvening');
  String get totalVehicles => _t('totalVehicles');
  String get moving => _t('moving');
  String get stopped => _t('stopped');
  String get offline => _t('offline');
  String get idle => _t('idle');
  String get quickActions => _t('quickActions');
  String get recentAlerts => _t('recentAlerts');
  String get fleetInsights => _t('fleetInsights');

  // ── Languages ──────────────────────────────────────────────────────────────
  String get langEnglish => _t('langEnglish');
  String get langArabic => _t('langArabic');
  String get langFrench => _t('langFrench');
  String get langSpanish => _t('langSpanish');
  String get selectLanguage => _t('selectLanguage');

  // ── Dashboard extras ───────────────────────────────────────────────────────
  String get distanceToday => _t('distanceToday');
  String get tripsToday => _t('tripsToday');
  String get alertsToday => _t('alertsToday');
  String get viewAll => _t('viewAll');
  String get trips => _t('trips');

  // ── Common ─────────────────────────────────────────────────────────────────
  String get loading => _t('loading');
  String get retry => _t('retry');
  String get noData => _t('noData');
  String get footerText => _t('footerText');
  String get fleetManager => _t('fleetManager');

  // ── Translations map ───────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appName': 'ELMO Fleet',
      // Navigation
      'navHome': 'Home',
      'navFleet': 'Fleet',
      'navMap': 'Map',
      'navAlerts': 'Alerts',
      'navProfile': 'Profile',
      // Settings
      'settingsTitle': 'Settings',
      'sectionFleet': 'Fleet',
      'sectionPreferences': 'Preferences',
      'sectionAccount': 'Account',
      'vehicles': 'Vehicles',
      'liveMap': 'Live Map',
      'analytics': 'Analytics',
      'notifications': 'Notifications',
      'language': 'Language',
      'appearance': 'Appearance',
      'aboutElmo': 'About ELMO',
      'signOut': 'Sign Out',
      'version': 'Version',
      'editProfile': 'Edit Profile',
      'notificationsEnabled': 'Push Notifications',
      'notificationsSubtitle': 'Receive real-time fleet alerts',
      'privacyPolicy': 'Privacy Policy',
      'helpSupport': 'Help & Support',
      // Theme
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'themeSystem': 'System',
      // Auth
      'welcomeBack': 'Welcome Back',
      'signInSubtitle': 'Sign in to your fleet',
      'emailLabel': 'Email Address',
      'passwordLabel': 'Password',
      'signInButton': 'Sign In',
      // Dialog
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'signOutTitle': 'Sign Out',
      'signOutMessage': 'Are you sure you want to sign out?',
      // Dashboard
      'fleetOverview': 'Fleet Overview',
      'goodMorning': 'Good Morning',
      'goodAfternoon': 'Good Afternoon',
      'goodEvening': 'Good Evening',
      'totalVehicles': 'Total Vehicles',
      'moving': 'Moving',
      'stopped': 'Stopped',
      'offline': 'Offline',
      'idle': 'Idle',
      'quickActions': 'Quick Actions',
      'recentAlerts': 'Recent Alerts',
      'fleetInsights': 'Fleet Insights',
      // Languages
      'langEnglish': 'English',
      'langArabic': 'Arabic',
      'langFrench': 'French',
      'langSpanish': 'Spanish',
      'selectLanguage': 'Select Language',
      // Dashboard extras
      'distanceToday': 'Distance Today',
      'tripsToday': 'Trips Today',
      'alertsToday': 'Alerts Today',
      'viewAll': 'View All',
      'trips': 'Trips',
      // Common
      'loading': 'Loading...',
      'retry': 'Retry',
      'noData': 'No data available',
      'footerText': 'ELMO Fleet Intelligence\n© 2025 All rights reserved',
      'fleetManager': 'Fleet Manager',
    },
    'ar': {
      'appName': 'ELMO للأسطول',
      // Navigation
      'navHome': 'الرئيسية',
      'navFleet': 'الأسطول',
      'navMap': 'الخريطة',
      'navAlerts': 'التنبيهات',
      'navProfile': 'الملف',
      // Settings
      'settingsTitle': 'الإعدادات',
      'sectionFleet': 'الأسطول',
      'sectionPreferences': 'التفضيلات',
      'sectionAccount': 'الحساب',
      'vehicles': 'المركبات',
      'liveMap': 'الخريطة المباشرة',
      'analytics': 'التحليلات',
      'notifications': 'الإشعارات',
      'language': 'اللغة',
      'appearance': 'المظهر',
      'aboutElmo': 'حول ELMO',
      'signOut': 'تسجيل الخروج',
      'version': 'الإصدار',
      'editProfile': 'تعديل الملف الشخصي',
      'notificationsEnabled': 'الإشعارات الفورية',
      'notificationsSubtitle': 'استقبل تنبيهات الأسطول في الوقت الفعلي',
      'privacyPolicy': 'سياسة الخصوصية',
      'helpSupport': 'المساعدة والدعم',
      // Theme
      'themeLight': 'فاتح',
      'themeDark': 'داكن',
      'themeSystem': 'النظام',
      // Auth
      'welcomeBack': 'مرحباً بعودتك',
      'signInSubtitle': 'سجّل دخولك إلى أسطولك',
      'emailLabel': 'البريد الإلكتروني',
      'passwordLabel': 'كلمة المرور',
      'signInButton': 'تسجيل الدخول',
      // Dialog
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'signOutTitle': 'تسجيل الخروج',
      'signOutMessage': 'هل أنت متأكد من تسجيل الخروج؟',
      // Dashboard
      'fleetOverview': 'نظرة عامة على الأسطول',
      'goodMorning': 'صباح الخير',
      'goodAfternoon': 'مساء الخير',
      'goodEvening': 'مساء النور',
      'totalVehicles': 'إجمالي المركبات',
      'moving': 'متحرك',
      'stopped': 'متوقف',
      'offline': 'غير متصل',
      'idle': 'خامل',
      'quickActions': 'الإجراءات السريعة',
      'recentAlerts': 'أحدث التنبيهات',
      'fleetInsights': 'رؤى الأسطول',
      // Languages
      'langEnglish': 'الإنجليزية',
      'langArabic': 'العربية',
      'langFrench': 'الفرنسية',
      'langSpanish': 'الإسبانية',
      'selectLanguage': 'اختر اللغة',
      // Dashboard extras
      'distanceToday': 'المسافة اليوم',
      'tripsToday': 'الرحلات اليوم',
      'alertsToday': 'التنبيهات اليوم',
      'viewAll': 'عرض الكل',
      'trips': 'الرحلات',
      // Common
      'loading': 'جارٍ التحميل...',
      'retry': 'إعادة المحاولة',
      'noData': 'لا توجد بيانات متاحة',
      'footerText': 'ELMO لذكاء الأسطول\n© 2025 جميع الحقوق محفوظة',
      'fleetManager': 'مدير الأسطول',
    },
    'fr': {
      'appName': 'ELMO Flotte',
      // Navigation
      'navHome': 'Accueil',
      'navFleet': 'Flotte',
      'navMap': 'Carte',
      'navAlerts': 'Alertes',
      'navProfile': 'Profil',
      // Settings
      'settingsTitle': 'Paramètres',
      'sectionFleet': 'Flotte',
      'sectionPreferences': 'Préférences',
      'sectionAccount': 'Compte',
      'vehicles': 'Véhicules',
      'liveMap': 'Carte en direct',
      'analytics': 'Analytique',
      'notifications': 'Notifications',
      'language': 'Langue',
      'appearance': 'Apparence',
      'aboutElmo': 'À propos d\'ELMO',
      'signOut': 'Se déconnecter',
      'version': 'Version',
      'editProfile': 'Modifier le profil',
      'notificationsEnabled': 'Notifications push',
      'notificationsSubtitle': 'Recevez des alertes en temps réel',
      'privacyPolicy': 'Politique de confidentialité',
      'helpSupport': 'Aide et support',
      // Theme
      'themeLight': 'Clair',
      'themeDark': 'Sombre',
      'themeSystem': 'Système',
      // Auth
      'welcomeBack': 'Bon retour',
      'signInSubtitle': 'Connectez-vous à votre flotte',
      'emailLabel': 'Adresse e-mail',
      'passwordLabel': 'Mot de passe',
      'signInButton': 'Se connecter',
      // Dialog
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'signOutTitle': 'Déconnexion',
      'signOutMessage': 'Êtes-vous sûr de vouloir vous déconnecter ?',
      // Dashboard
      'fleetOverview': 'Vue d\'ensemble',
      'goodMorning': 'Bonjour',
      'goodAfternoon': 'Bon après-midi',
      'goodEvening': 'Bonsoir',
      'totalVehicles': 'Total véhicules',
      'moving': 'En mouvement',
      'stopped': 'Arrêté',
      'offline': 'Hors ligne',
      'idle': 'Inactif',
      'quickActions': 'Actions rapides',
      'recentAlerts': 'Alertes récentes',
      'fleetInsights': 'Analyses de flotte',
      // Languages
      'langEnglish': 'Anglais',
      'langArabic': 'Arabe',
      'langFrench': 'Français',
      'langSpanish': 'Espagnol',
      'selectLanguage': 'Choisir la langue',
      // Dashboard extras
      'distanceToday': "Distance aujourd'hui",
      'tripsToday': "Trajets aujourd'hui",
      'alertsToday': "Alertes aujourd'hui",
      'viewAll': 'Voir tout',
      'trips': 'Trajets',
      // Common
      'loading': 'Chargement...',
      'retry': 'Réessayer',
      'noData': 'Aucune donnée disponible',
      'footerText': 'ELMO Intelligence de Flotte\n© 2025 Tous droits réservés',
      'fleetManager': 'Gestionnaire de flotte',
    },
    'es': {
      'appName': 'ELMO Flota',
      // Navigation
      'navHome': 'Inicio',
      'navFleet': 'Flota',
      'navMap': 'Mapa',
      'navAlerts': 'Alertas',
      'navProfile': 'Perfil',
      // Settings
      'settingsTitle': 'Configuración',
      'sectionFleet': 'Flota',
      'sectionPreferences': 'Preferencias',
      'sectionAccount': 'Cuenta',
      'vehicles': 'Vehículos',
      'liveMap': 'Mapa en vivo',
      'analytics': 'Analítica',
      'notifications': 'Notificaciones',
      'language': 'Idioma',
      'appearance': 'Apariencia',
      'aboutElmo': 'Acerca de ELMO',
      'signOut': 'Cerrar sesión',
      'version': 'Versión',
      'editProfile': 'Editar perfil',
      'notificationsEnabled': 'Notificaciones push',
      'notificationsSubtitle': 'Recibe alertas en tiempo real',
      'privacyPolicy': 'Política de privacidad',
      'helpSupport': 'Ayuda y soporte',
      // Theme
      'themeLight': 'Claro',
      'themeDark': 'Oscuro',
      'themeSystem': 'Sistema',
      // Auth
      'welcomeBack': 'Bienvenido',
      'signInSubtitle': 'Inicia sesión en tu flota',
      'emailLabel': 'Correo electrónico',
      'passwordLabel': 'Contraseña',
      'signInButton': 'Iniciar sesión',
      // Dialog
      'cancel': 'Cancelar',
      'confirm': 'Confirmar',
      'signOutTitle': 'Cerrar sesión',
      'signOutMessage': '¿Estás seguro de que quieres cerrar sesión?',
      // Dashboard
      'fleetOverview': 'Resumen de flota',
      'goodMorning': 'Buenos días',
      'goodAfternoon': 'Buenas tardes',
      'goodEvening': 'Buenas noches',
      'totalVehicles': 'Total de vehículos',
      'moving': 'En marcha',
      'stopped': 'Detenido',
      'offline': 'Sin conexión',
      'idle': 'Inactivo',
      'quickActions': 'Acciones rápidas',
      'recentAlerts': 'Alertas recientes',
      'fleetInsights': 'Análisis de flota',
      // Languages
      'langEnglish': 'Inglés',
      'langArabic': 'Árabe',
      'langFrench': 'Francés',
      'langSpanish': 'Español',
      'selectLanguage': 'Seleccionar idioma',
      // Dashboard extras
      'distanceToday': 'Distancia hoy',
      'tripsToday': 'Viajes hoy',
      'alertsToday': 'Alertas hoy',
      'viewAll': 'Ver todo',
      'trips': 'Viajes',
      // Common
      'loading': 'Cargando...',
      'retry': 'Reintentar',
      'noData': 'No hay datos disponibles',
      'footerText': 'ELMO Inteligencia de Flota\n© 2025 Todos los derechos reservados',
      'fleetManager': 'Gestor de flota',
    },
  };
}

// ── Extension ─────────────────────────────────────────────────────────────────
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// ── Delegate ──────────────────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar', 'fr', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
