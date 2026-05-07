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

  // ── Vehicles ───────────────────────────────────────────────────────────────
  String get vehicleList => _t('vehicleList');
  String get searchTooltip => _t('searchTooltip');
  String get refreshTooltip => _t('refreshTooltip');
  String get noVehicles => _t('noVehicles');
  String get noVehiclesRegistered => _t('noVehiclesRegistered');
  String get tryChangingFilters => _t('tryChangingFilters');
  String get loadingFleet => _t('loadingFleet');
  String get searchHint => _t('searchHint');
  String get filterAll => _t('filterAll');
  String get filterMoving => _t('filterMoving');
  String get filterStopped => _t('filterStopped');
  String get filterIdle => _t('filterIdle');
  String get filterOffline => _t('filterOffline');
  String get statusMovingPlural => _t('statusMovingPlural');
  String get statusStoppedPlural => _t('statusStoppedPlural');
  String get statusIdlePlural => _t('statusIdlePlural');
  String get statusOfflinePlural => _t('statusOfflinePlural');
  String totalFleetCount(int n) =>
      _t('totalFleetCount').replaceAll('{n}', '$n');

  // ── Alerts ─────────────────────────────────────────────────────────────────
  String get allAlerts => _t('allAlerts');
  String get smartAlerts => _t('smartAlerts');
  String get markAllRead => _t('markAllRead');
  String get noAlerts => _t('noAlerts');
  String get noAlertsMessage => _t('noAlertsMessage');
  String get noSmartAlerts => _t('noSmartAlerts');
  String get noSmartAlertsMessage => _t('noSmartAlertsMessage');
  String get loadingAlerts => _t('loadingAlerts');
  String get alertDetail => _t('alertDetail');
  String get markRead => _t('markRead');
  String get alertNotFound => _t('alertNotFound');
  String get vehicleLabel => _t('vehicleLabel');
  String get timeLabel => _t('timeLabel');
  String get locationLabel => _t('locationLabel');
  String get detailsLabel => _t('detailsLabel');

  // ── Analytics ──────────────────────────────────────────────────────────────
  String get weeklyReport => _t('weeklyReport');
  String get thisWeek => _t('thisWeek');
  String get weeklyDistance => _t('weeklyDistance');
  String get fleetKPIs => _t('fleetKPIs');
  String get highlightsLabel => _t('highlightsLabel');
  String get mostActiveVehicleLabel => _t('mostActiveVehicleLabel');
  String get leastEfficientVehicleLabel => _t('leastEfficientVehicleLabel');
  String get topAlertCategoryLabel => _t('topAlertCategoryLabel');
  String get fleetEfficiencyScore => _t('fleetEfficiencyScore');
  String get excellentPerformance => _t('excellentPerformance');
  String get goodPerformance => _t('goodPerformance');
  String get needsAttention => _t('needsAttention');
  String get totalDistance => _t('totalDistance');
  String get totalTripsLabel => _t('totalTripsLabel');
  String get idleTimeLabel => _t('idleTimeLabel');
  String get overspeedEvents => _t('overspeedEvents');
  String get loadingAnalytics => _t('loadingAnalytics');
  String weekOfDate(String date) =>
      _t('weekOf').replaceAll('{date}', date);

  // ── Trips ──────────────────────────────────────────────────────────────────
  String get tripHistory => _t('tripHistory');
  String get filterByDate => _t('filterByDate');
  String get noTrips => _t('noTrips');
  String get noTripsMessage => _t('noTripsMessage');
  String get ongoingTrip => _t('ongoingTrip');
  String get distanceLabel => _t('distanceLabel');
  String get durationLabel => _t('durationLabel');
  String get maxSpeedLabel => _t('maxSpeedLabel');
  String get loadingTrips => _t('loadingTrips');

  // ── Notifications ──────────────────────────────────────────────────────────
  String get noNotifications => _t('noNotifications');
  String get allCaughtUp => _t('allCaughtUp');
  String get failedToLoadNotifications => _t('failedToLoadNotifications');
  String get loadingNotifications => _t('loadingNotifications');

  // ── Commands ───────────────────────────────────────────────────────────────
  String get commandsTitle => _t('commandsTitle');
  String get commandHistoryTooltip => _t('commandHistoryTooltip');
  String get noCommandsAvailable => _t('noCommandsAvailable');
  String get noCommandsMessage => _t('noCommandsMessage');
  String get commandHistoryTitle => _t('commandHistoryTitle');
  String get clearHistory => _t('clearHistory');
  String get noCommandsSent => _t('noCommandsSent');
  String get noCommandsSentMessage => _t('noCommandsSentMessage');
  String get confirmClearTitle => _t('confirmClearTitle');
  String get confirmClearMessage => _t('confirmClearMessage');
  String get clearLabel => _t('clearLabel');
  String get statusSuccess => _t('statusSuccess');
  String get statusFailed => _t('statusFailed');
  String get statusTimeout => _t('statusTimeout');
  String get statusPending => _t('statusPending');
  String get statusQueued => _t('statusQueued');
  String get statusRejected => _t('statusRejected');
  String availableOf(int available, int total) =>
      _t('availableOf')
          .replaceAll('{available}', '$available')
          .replaceAll('{total}', '$total');
  String errorLoadingData(String e) =>
      _t('errorLoadingData').replaceAll('{error}', e);

  // ── Vehicle Detail ─────────────────────────────────────────────────────────
  String get statusLabel => _t('statusLabel');
  String get telemetryRealTime => _t('telemetryRealTime');
  String get ignitionLabel => _t('ignitionLabel');
  String get motionLabel => _t('motionLabel');
  String get speedLabel => _t('speedLabel');
  String get fuelLabel => _t('fuelLabel');
  String get batteryVoltageLabel => _t('batteryVoltageLabel');
  String get brakingLabel => _t('brakingLabel');
  String get hardBrakeLabel => _t('hardBrakeLabel');
  String get normalLabel => _t('normalLabel');
  String get currentLocation => _t('currentLocation');
  String get trackVehicle => _t('trackVehicle');
  String get recentTrips => _t('recentTrips');
  String get allTrips => _t('allTrips');
  String get driverLabel => _t('driverLabel');
  String get coordinatesLabel => _t('coordinatesLabel');
  String get lastUpdateLabel => _t('lastUpdateLabel');
  String get noTripsToday => _t('noTripsToday');
  String get noAlertsVehicle => _t('noAlertsVehicle');
  String get loadingVehicle => _t('loadingVehicle');
  String get deviceInfo => _t('deviceInfo');
  String get deviceModelLabel => _t('deviceModelLabel');
  String get deviceIdLabel => _t('deviceIdLabel');
  String get devicePhoneLabel => _t('devicePhoneLabel');
  String get positionDetails => _t('positionDetails');
  String get altitudeLabel => _t('altitudeLabel');
  String get courseLabel => _t('courseLabel');
  String get odometerLabel => _t('odometerLabel');
  String get accuracyLabel => _t('accuracyLabel');

  // ── Map screens ────────────────────────────────────────────────────────────
  String get mapLoadingFleet => _t('mapLoadingFleet');
  String get mapLoadError => _t('mapLoadError');
  String get zoomIn => _t('zoomIn');
  String get zoomOut => _t('zoomOut');
  String get fitBounds => _t('fitBounds');
  String get engineLabel => _t('engineLabel');
  String get ignitionOnLabel => _t('ignitionOnLabel');
  String get ignitionOffLabel => _t('ignitionOffLabel');
  String get liveTrack => _t('liveTrack');
  String get centerMap => _t('centerMap');
  String get loadingVehicleLocation => _t('loadingVehicleLocation');
  String get followLabel => _t('followLabel');
  String get freeLabel => _t('freeLabel');
  String get routeLabel => _t('routeLabel');
  String get vehicleDetails => _t('vehicleDetails');
  String get todayRouteLabel => _t('todayRouteLabel');
  String get locationUnavailable => _t('locationUnavailable');
  String get updateLocationFailed => _t('updateLocationFailed');
  String fleetOnlineCount(int online, int total, int moving) =>
      _t('fleetOnlineCount')
          .replaceAll('{online}', '$online')
          .replaceAll('{total}', '$total')
          .replaceAll('{moving}', '$moving');
  String routePointsCount(int n) =>
      _t('routePointsCount').replaceAll('{n}', '$n');
  String routeDistanceKm(String km) =>
      _t('routeDistanceKm').replaceAll('{km}', km);
  String get routeDeparture     => _t('routeDeparture');
  String get routeArrival       => _t('routeArrival');
  String get avgSpeedLabel      => _t('avgSpeedLabel');
  String get noRouteForDate     => _t('noRouteForDate');
  String get selectDateLabel    => _t('selectDateLabel');
  String get todayLabel         => _t('todayLabel');
  String get routeMaxSpeedPoint  => _t('routeMaxSpeedPoint');
  String get recentreRouteLabel  => _t('recentreRouteLabel');
  String get fromLabel           => _t('fromLabel');
  String get toLabel             => _t('toLabel');
  String get timeRangeLabel      => _t('timeRangeLabel');
  String get pickDateTimeHint    => _t('pickDateTimeHint');

  // ── Reports ────────────────────────────────────────────────────────────────
  String get reportsTitle         => _t('reportsTitle');
  String get navReports           => _t('navReports');
  String get reportsSummary       => _t('reportsSummary');
  String get reportsRoute         => _t('reportsRoute');
  String get reportsTrips         => _t('reportsTrips');
  String get reportsStops         => _t('reportsStops');
  String get reportsEvents        => _t('reportsEvents');
  String get generateReport       => _t('generateReport');
  String get selectVehicle        => _t('selectVehicle');
  String get selectVehicleHint    => _t('selectVehicleHint');
  String get periodToday          => _t('periodToday');
  String get periodYesterday      => _t('periodYesterday');
  String get periodThisWeek       => _t('periodThisWeek');
  String get periodThisMonth      => _t('periodThisMonth');
  String get periodCustom         => _t('periodCustom');
  String get noReportAvailable    => _t('noReportAvailable');
  String get errorLoadingReport   => _t('errorLoadingReport');
  String get loadingReport        => _t('loadingReport');
  String get totalDistanceLabel   => _t('totalDistanceLabel');
  String get engineTimeLabel      => _t('engineTimeLabel');
  String get stopDurationLabel    => _t('stopDurationLabel');
  String get fuelConsumedLabel    => _t('fuelConsumedLabel');
  String get viewOnMap            => _t('viewOnMap');
  String get exportPdf            => _t('exportPdf');
  String get shareReport          => _t('shareReport');
  String get comingSoon           => _t('comingSoon');
  String get noTripsReport        => _t('noTripsReport');
  String get noStopsReport        => _t('noStopsReport');
  String get noEventsReport       => _t('noEventsReport');
  String get noRouteReport        => _t('noRouteReport');
  String get loadingSummary       => _t('loadingSummary');
  String get loadingRoute         => _t('loadingRoute');
  String get loadingStops         => _t('loadingStops');
  String get loadingEvents        => _t('loadingEvents');
  String get errorLoadingRoute    => _t('errorLoadingRoute');
  String get errorLoadingTrips    => _t('errorLoadingTrips');
  String get errorLoadingStops    => _t('errorLoadingStops');
  String get errorLoadingEvents   => _t('errorLoadingEvents');
  String get noRouteDataTitle     => _t('noRouteDataTitle');
  String get noTripsDataTitle     => _t('noTripsDataTitle');
  String get noStopsDataTitle     => _t('noStopsDataTitle');
  String get noEventsDataTitle    => _t('noEventsDataTitle');
  String get noDataTitle          => _t('noDataTitle');
  String get reportGenerateHintSummary  => _t('reportGenerateHintSummary');
  String get reportGenerateHintRoute    => _t('reportGenerateHintRoute');
  String get reportGenerateHintTrips    => _t('reportGenerateHintTrips');
  String get reportGenerateHintStops    => _t('reportGenerateHintStops');
  String get reportGenerateHintEvents   => _t('reportGenerateHintEvents');
  String get noVehicleSelectedTitle     => _t('noVehicleSelectedTitle');
  String get analysedPeriod       => _t('analysedPeriod');
  String get periodStartLabel     => _t('periodStartLabel');
  String get periodEndLabel       => _t('periodEndLabel');
  String get totalDurationLabel   => _t('totalDurationLabel');
  String get maxSpeedKpiLabel     => _t('maxSpeedKpiLabel');
  String get avgSpeedKpiLabel     => _t('avgSpeedKpiLabel');
  String get gpsPointsLabel       => _t('gpsPointsLabel');
  String get gpsTraceLabel        => _t('gpsTraceLabel');
  String get selectVehicleDropdownHint  => _t('selectVehicleDropdownHint');
  String get selectVehicleSheetTitle    => _t('selectVehicleSheetTitle');
  String get routeMaxSpeedShort   => _t('routeMaxSpeedShort');
  String get routeAvgSpeedShort   => _t('routeAvgSpeedShort');
  String get routePointsShort     => _t('routePointsShort');
  String routeGpsPointsInfo(int total, int drawn) =>
      _t('routeGpsPointsInfo')
          .replaceAll('{total}', '$total')
          .replaceAll('{drawn}', '$drawn');

  // ── Replay ─────────────────────────────────────────────────────────────────
  String get replayRoute              => _t('replayRoute');
  String get replayPlay               => _t('replayPlay');
  String get replayPause              => _t('replayPause');
  String get replayRestart            => _t('replayRestart');
  String get replaySpeed              => _t('replaySpeed');
  String get replayCurrentSpeed       => _t('replayCurrentSpeed');
  String get replayCurrentTime        => _t('replayCurrentTime');
  String get replayProgress           => _t('replayProgress');
  String get loadingReplay            => _t('loadingReplay');
  String get errorLoadingReplay       => _t('errorLoadingReplay');
  String get notEnoughDataForReplay   => _t('notEnoughDataForReplay');
  String get routeCompleted           => _t('routeCompleted');
  String get viewReplay               => _t('viewReplay');

  // ── Speed Chart ────────────────────────────────────────────────────────────
  String get speedChartTitle          => _t('speedChartTitle');
  String get speedChartMax            => _t('speedChartMax');
  String get speedChartAvg            => _t('speedChartAvg');
  String get speedChartGpsPoints      => _t('speedChartGpsPoints');
  String get noSpeedData              => _t('noSpeedData');
  String get viewSpeedChart           => _t('viewSpeedChart');

  // ── PDF / Share ─────────────────────────────────────────────────────────────
  String get exportPdfLabel     => _t('exportPdfLabel');
  String get shareReportLabel   => _t('shareReportLabel');
  String get printLabel         => _t('printLabel');
  String get generatingPdf      => _t('generatingPdf');
  String get pdfGenerated       => _t('pdfGenerated');
  String get pdfError           => _t('pdfError');
  String get shareAsPdf         => _t('shareAsPdf');
  String get shareAsText        => _t('shareAsText');
  String get reportGeneratedBy  => _t('reportGeneratedBy');
  String get reportGeneratedOn  => _t('reportGeneratedOn');

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
      // Vehicles
      'vehicleList': 'Vehicle List',
      'searchTooltip': 'Search',
      'refreshTooltip': 'Refresh',
      'noVehicles': 'No vehicles',
      'noVehiclesRegistered': 'No vehicles registered.',
      'tryChangingFilters': 'Try changing the search or filter criteria.',
      'loadingFleet': 'Loading fleet…',
      'searchHint': 'Search by name or plate…',
      'filterAll': 'All',
      'filterMoving': 'Moving',
      'filterStopped': 'Stopped',
      'filterIdle': 'Idle',
      'filterOffline': 'Offline',
      'statusMovingPlural': 'Moving',
      'statusStoppedPlural': 'Stopped',
      'statusIdlePlural': 'Idle',
      'statusOfflinePlural': 'Offline',
      'totalFleetCount': 'Total fleet: {n} vehicle(s)',
      // Alerts
      'allAlerts': 'All Alerts',
      'smartAlerts': 'Smart Alerts',
      'markAllRead': 'Mark all read',
      'noAlerts': 'No alerts',
      'noAlertsMessage': 'Your fleet has no active alerts.',
      'noSmartAlerts': 'No smart alerts',
      'noSmartAlertsMessage': 'Critical patterns will appear here.',
      'loadingAlerts': 'Loading alerts…',
      'alertDetail': 'Alert Detail',
      'markRead': 'Mark read',
      'alertNotFound': 'Alert not found',
      'vehicleLabel': 'Vehicle',
      'timeLabel': 'Time',
      'locationLabel': 'Location',
      'detailsLabel': 'Details',
      // Analytics
      'weeklyReport': 'Weekly Report',
      'weekOf': 'Week of {date}',
      'thisWeek': 'This Week',
      'weeklyDistance': 'Weekly Distance',
      'fleetKPIs': 'Fleet KPIs',
      'highlightsLabel': 'Highlights',
      'mostActiveVehicleLabel': 'Most active vehicle',
      'leastEfficientVehicleLabel': 'Least efficient vehicle',
      'topAlertCategoryLabel': 'Top alert category',
      'fleetEfficiencyScore': 'Fleet Efficiency Score',
      'excellentPerformance': 'Excellent performance',
      'goodPerformance': 'Good, room for improvement',
      'needsAttention': 'Needs attention',
      'totalDistance': 'Total Distance',
      'totalTripsLabel': 'Total Trips',
      'idleTimeLabel': 'Idle Time',
      'overspeedEvents': 'Overspeed Events',
      'loadingAnalytics': 'Loading analytics…',
      // Trips
      'tripHistory': 'Trip History',
      'filterByDate': 'Filter by date',
      'noTrips': 'No trips recorded',
      'noTripsMessage': 'Trip history will appear here.',
      'ongoingTrip': 'Ongoing',
      'distanceLabel': 'Distance',
      'durationLabel': 'Duration',
      'maxSpeedLabel': 'Max speed',
      'loadingTrips': 'Loading trips…',
      // Notifications
      'noNotifications': 'No notifications',
      'allCaughtUp': "You're all caught up!",
      'failedToLoadNotifications': 'Failed to load notifications.',
      'loadingNotifications': 'Loading notifications…',
      // Commands
      'commandsTitle': 'Commands',
      'commandHistoryTooltip': 'Command history',
      'noCommandsAvailable': 'No commands available',
      'noCommandsMessage':
          'This model has no commands\naccessible with your access level.',
      'commandHistoryTitle': 'History',
      'clearHistory': 'Clear history',
      'noCommandsSent': 'No commands sent',
      'noCommandsSentMessage':
          'History will appear here after\nsending the first command.',
      'confirmClearTitle': 'Clear History',
      'confirmClearMessage':
          'All command logs will be permanently deleted.',
      'clearLabel': 'Clear',
      'statusSuccess': 'Success',
      'statusFailed': 'Failed',
      'statusTimeout': 'Timeout',
      'statusPending': 'Pending',
      'statusQueued': 'Queued',
      'statusRejected': 'Rejected',
      'availableOf': '{available}/{total} available',
      'errorLoadingData': 'Error: {error}',
      // Vehicle Detail
      'statusLabel': 'Status',
      'telemetryRealTime': 'Real-time Telemetry',
      'ignitionLabel': 'Ignition',
      'motionLabel': 'Motion',
      'speedLabel': 'Speed',
      'fuelLabel': 'Fuel',
      'batteryVoltageLabel': 'Battery',
      'brakingLabel': 'Braking',
      'hardBrakeLabel': 'Hard',
      'normalLabel': 'OK',
      'currentLocation': 'Current Location',
      'trackVehicle': 'Track Vehicle',
      'recentTrips': 'Recent Trips',
      'allTrips': 'All Trips',
      'driverLabel': 'Driver',
      'coordinatesLabel': 'Coordinates',
      'lastUpdateLabel': 'Last Update',
      'noTripsToday': 'No trips recorded today.',
      'noAlertsVehicle': 'No alerts for this vehicle.',
      'loadingVehicle': 'Loading vehicle…',
      'deviceInfo': 'Device Info',
      'deviceModelLabel': 'Model',
      'deviceIdLabel': 'Device ID',
      'devicePhoneLabel': 'Phone',
      'positionDetails': 'Position Details',
      'altitudeLabel': 'Altitude',
      'courseLabel': 'Direction',
      'odometerLabel': 'Odometer',
      'accuracyLabel': 'Accuracy',
      // Maps
      'mapLoadingFleet': 'Loading map…',
      'mapLoadError': 'Failed to load vehicle data',
      'zoomIn': 'Zoom in',
      'zoomOut': 'Zoom out',
      'fitBounds': 'Fit all',
      'engineLabel': 'Engine',
      'ignitionOnLabel': 'On',
      'ignitionOffLabel': 'Off',
      'liveTrack': 'Live Track',
      'centerMap': 'Center',
      'loadingVehicleLocation': 'Loading vehicle location…',
      'followLabel': 'Follow',
      'freeLabel': 'Free',
      'routeLabel': 'Route',
      'vehicleDetails': 'Vehicle Details',
      'todayRouteLabel': "Today's Route",
      'locationUnavailable': 'Unavailable',
      'updateLocationFailed': 'Failed to update location',
      'fleetOnlineCount': '{online}/{total} online · {moving} moving',
      'routePointsCount': '{n} pts',
      'routeDistanceKm': 'Route: {km} km',
      'routeDeparture': 'Departure',
      'routeArrival': 'Arrival',
      'avgSpeedLabel': 'Avg. speed',
      'noRouteForDate': 'No route found for this date.',
      'selectDateLabel': 'Select date',
      'todayLabel': 'Today',
      'routeMaxSpeedPoint': 'Max speed',
      'recentreRouteLabel': 'Fit route',
      'fromLabel': 'From',
      'toLabel': 'To',
      'timeRangeLabel': 'Time range',
      'pickDateTimeHint': 'Tap to change',
      // Reports
      'reportsTitle': 'Reports',
      'navReports': 'Reports',
      'reportsSummary': 'Summary',
      'reportsRoute': 'Route',
      'reportsTrips': 'Trips',
      'reportsStops': 'Stops',
      'reportsEvents': 'Events',
      'generateReport': 'Generate Report',
      'selectVehicle': 'Select vehicle',
      'selectVehicleHint': 'Select a vehicle to generate the report.',
      'periodToday': 'Today',
      'periodYesterday': 'Yesterday',
      'periodThisWeek': 'This week',
      'periodThisMonth': 'This month',
      'periodCustom': 'Custom',
      'noReportAvailable': 'No report available for this period.',
      'errorLoadingReport': 'Error loading report.',
      'loadingReport': 'Loading report…',
      'totalDistanceLabel': 'Total distance',
      'engineTimeLabel': 'Engine time',
      'stopDurationLabel': 'Stop duration',
      'fuelConsumedLabel': 'Fuel consumed',
      'viewOnMap': 'View on map',
      'exportPdf': 'Export PDF',
      'shareReport': 'Share',
      'comingSoon': 'Coming soon',
      'noTripsReport': 'No trips recorded for this period.',
      'noStopsReport': 'No stops recorded for this period.',
      'noEventsReport': 'No events recorded for this period.',
      'noRouteReport': 'No GPS trace available for this period.',
      'loadingSummary': 'Loading summary…',
      'loadingRoute': 'Loading route…',
      'loadingStops': 'Loading stops…',
      'loadingEvents': 'Loading events…',
      'errorLoadingRoute': 'Error loading route.',
      'errorLoadingTrips': 'Error loading trips.',
      'errorLoadingStops': 'Error loading stops.',
      'errorLoadingEvents': 'Error loading events.',
      'noRouteDataTitle': 'No route',
      'noTripsDataTitle': 'No trips',
      'noStopsDataTitle': 'No stops',
      'noEventsDataTitle': 'No events',
      'noDataTitle': 'No data',
      'reportGenerateHintSummary': 'Select a vehicle and a period,\nthen tap «Generate report».',
      'reportGenerateHintRoute': 'Generate the report to see the GPS route.',
      'reportGenerateHintTrips': 'Generate the report to see trips.',
      'reportGenerateHintStops': 'Generate the report to see stops.',
      'reportGenerateHintEvents': 'Generate the report to see events.',
      'noVehicleSelectedTitle': 'No vehicle selected',
      'analysedPeriod': 'Analysed period',
      'periodStartLabel': 'Start',
      'periodEndLabel': 'End',
      'totalDurationLabel': 'Total duration',
      'maxSpeedKpiLabel': 'Max speed',
      'avgSpeedKpiLabel': 'Avg speed',
      'gpsPointsLabel': 'GPS points',
      'gpsTraceLabel': 'GPS trace',
      'selectVehicleDropdownHint': 'Select a vehicle…',
      'selectVehicleSheetTitle': 'Select a vehicle',
      'routeMaxSpeedShort': 'Max spd',
      'routeAvgSpeedShort': 'Avg spd',
      'routePointsShort': 'Points',
      'routeGpsPointsInfo': '{total} GPS pts · {drawn} pts displayed',
      // Replay
      'replayRoute': 'Replay route',
      'replayPlay': 'Play',
      'replayPause': 'Pause',
      'replayRestart': 'Restart',
      'replaySpeed': 'Playback speed',
      'replayCurrentSpeed': 'Current speed',
      'replayCurrentTime': 'Current time',
      'replayProgress': 'Progress',
      'loadingReplay': 'Loading replay…',
      'errorLoadingReplay': 'Error loading replay.',
      'notEnoughDataForReplay': 'Not enough GPS data for replay.',
      'routeCompleted': 'Route completed',
      'viewReplay': 'View replay',
      // Speed chart
      'speedChartTitle': 'Speed chart',
      'speedChartMax': 'Max speed',
      'speedChartAvg': 'Average speed',
      'speedChartGpsPoints': 'GPS points',
      'noSpeedData': 'No speed data available.',
      'viewSpeedChart': 'View speed chart',
      // PDF / Share
      'exportPdfLabel': 'Export PDF',
      'shareReportLabel': 'Share report',
      'printLabel': 'Print',
      'generatingPdf': 'Generating PDF…',
      'pdfGenerated': 'PDF ready',
      'pdfError': 'PDF generation failed',
      'shareAsPdf': 'Share as PDF',
      'shareAsText': 'Share as text (WhatsApp/SMS)',
      'reportGeneratedBy': 'Generated by ELMOGPS',
      'reportGeneratedOn': 'Generated on',
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
      // Vehicles
      'vehicleList': 'لائحة المركبات',
      'searchTooltip': 'بحث',
      'refreshTooltip': 'تحديث',
      'noVehicles': 'لا توجد مركبات',
      'noVehiclesRegistered': 'لا توجد مركبات مسجلة.',
      'tryChangingFilters': 'جرّب تغيير معايير البحث أو الفلتر.',
      'loadingFleet': 'جار تحميل الأسطول…',
      'searchHint': 'البحث بالاسم أو رقم اللوحة…',
      'filterAll': 'الكل',
      'filterMoving': 'متحرك',
      'filterStopped': 'متوقف',
      'filterIdle': 'خامل',
      'filterOffline': 'مقطوع',
      'statusMovingPlural': 'متحركة',
      'statusStoppedPlural': 'متوقفة',
      'statusIdlePlural': 'خاملة',
      'statusOfflinePlural': 'مقطوعة',
      'totalFleetCount': 'إجمالي الأسطول: {n} مركبة',
      // Alerts
      'allAlerts': 'جميع التنبيهات',
      'smartAlerts': 'تنبيهات ذكية',
      'markAllRead': 'تعيين الكل كمقروء',
      'noAlerts': 'لا تنبيهات',
      'noAlertsMessage': 'لا تنبيهات نشطة في أسطولك.',
      'noSmartAlerts': 'لا تنبيهات ذكية',
      'noSmartAlertsMessage': 'ستظهر هنا الأنماط الحرجة.',
      'loadingAlerts': 'جارٍ تحميل التنبيهات…',
      'alertDetail': 'تفاصيل التنبيه',
      'markRead': 'تعيين كمقروء',
      'alertNotFound': 'التنبيه غير موجود',
      'vehicleLabel': 'المركبة',
      'timeLabel': 'الوقت',
      'locationLabel': 'الموقع',
      'detailsLabel': 'التفاصيل',
      // Analytics
      'weeklyReport': 'التقرير الأسبوعي',
      'weekOf': 'أسبوع {date}',
      'thisWeek': 'هذا الأسبوع',
      'weeklyDistance': 'المسافة الأسبوعية',
      'fleetKPIs': 'مؤشرات الأسطول',
      'highlightsLabel': 'أبرز النقاط',
      'mostActiveVehicleLabel': 'أكثر مركبة نشاطاً',
      'leastEfficientVehicleLabel': 'أقل مركبة كفاءة',
      'topAlertCategoryLabel': 'أعلى فئة تنبيهات',
      'fleetEfficiencyScore': 'نقاط كفاءة الأسطول',
      'excellentPerformance': 'أداء ممتاز',
      'goodPerformance': 'جيد، هناك مجال للتحسين',
      'needsAttention': 'يحتاج انتباهاً',
      'totalDistance': 'المسافة الإجمالية',
      'totalTripsLabel': 'إجمالي الرحلات',
      'idleTimeLabel': 'وقت الخمول',
      'overspeedEvents': 'أحداث تجاوز السرعة',
      'loadingAnalytics': 'جارٍ تحميل التحليلات…',
      // Trips
      'tripHistory': 'سجل الرحلات',
      'filterByDate': 'تصفية بالتاريخ',
      'noTrips': 'لا توجد رحلات مسجلة',
      'noTripsMessage': 'سيظهر سجل الرحلات هنا.',
      'ongoingTrip': 'جارية',
      'distanceLabel': 'المسافة',
      'durationLabel': 'المدة',
      'maxSpeedLabel': 'السرعة القصوى',
      'loadingTrips': 'جارٍ تحميل الرحلات…',
      // Notifications
      'noNotifications': 'لا إشعارات',
      'allCaughtUp': 'أنت على اطلاع بكل شيء!',
      'failedToLoadNotifications': 'فشل تحميل الإشعارات.',
      'loadingNotifications': 'جارٍ تحميل الإشعارات…',
      // Commands
      'commandsTitle': 'الأوامر',
      'commandHistoryTooltip': 'سجل الأوامر',
      'noCommandsAvailable': 'لا توجد أوامر متاحة',
      'noCommandsMessage': 'لا توجد أوامر لهذا الجهاز\nبمستوى وصولك الحالي.',
      'commandHistoryTitle': 'السجل',
      'clearHistory': 'مسح السجل',
      'noCommandsSent': 'لم يُرسل أي أمر',
      'noCommandsSentMessage': 'سيظهر السجل هنا بعد\nإرسال أول أمر.',
      'confirmClearTitle': 'مسح السجل',
      'confirmClearMessage': 'سيتم حذف جميع سجلات الأوامر بشكل دائم.',
      'clearLabel': 'مسح',
      'statusSuccess': 'ناجح',
      'statusFailed': 'فشل',
      'statusTimeout': 'انتهى الوقت',
      'statusPending': 'قيد الانتظار',
      'statusQueued': 'في الطابور',
      'statusRejected': 'مرفوض',
      'availableOf': '{available}/{total} متاح',
      'errorLoadingData': 'خطأ: {error}',
      // Vehicle Detail
      'statusLabel': 'الحالة',
      'telemetryRealTime': 'قياسات مباشرة',
      'ignitionLabel': 'الإشعال',
      'motionLabel': 'الحركة',
      'speedLabel': 'السرعة',
      'fuelLabel': 'الوقود',
      'batteryVoltageLabel': 'البطارية',
      'brakingLabel': 'الكبح',
      'hardBrakeLabel': 'متشدد',
      'normalLabel': 'طبيعي',
      'currentLocation': 'الموقع الحالي',
      'trackVehicle': 'تتبع المركبة',
      'recentTrips': 'أحدث الرحلات',
      'allTrips': 'جميع الرحلات',
      'driverLabel': 'السائق',
      'coordinatesLabel': 'الإحداثيات',
      'lastUpdateLabel': 'آخر تحديث',
      'noTripsToday': 'لا رحلات مسجلة اليوم.',
      'noAlertsVehicle': 'لا تنبيهات لهذه المركبة.',
      'loadingVehicle': 'جار تحميل المركبة…',
      'deviceInfo': 'معلومات الجهاز',
      'deviceModelLabel': 'الطراز',
      'deviceIdLabel': 'معرّف الجهاز',
      'devicePhoneLabel': 'الهاتف',
      'positionDetails': 'تفاصيل الموقع',
      'altitudeLabel': 'الارتفاع',
      'courseLabel': 'الاتجاه',
      'odometerLabel': 'عداد المسافة',
      'accuracyLabel': 'الدقة',
      // Maps
      'mapLoadingFleet': 'جارٍ تحميل الخريطة…',
      'mapLoadError': 'تعذّر تحميل بيانات المركبات',
      'zoomIn': 'تكبير',
      'zoomOut': 'تصغير',
      'fitBounds': 'ضبط العرض',
      'engineLabel': 'المحرك',
      'ignitionOnLabel': 'مشتعل',
      'ignitionOffLabel': 'مطفأ',
      'liveTrack': 'تتبع مباشر',
      'centerMap': 'توسيط',
      'loadingVehicleLocation': 'جارٍ تحميل موقع المركبة…',
      'followLabel': 'متابعة',
      'freeLabel': 'حر',
      'routeLabel': 'المسار',
      'vehicleDetails': 'تفاصيل المركبة',
      'todayRouteLabel': 'مسار اليوم',
      'locationUnavailable': 'غير متاح',
      'updateLocationFailed': 'تعذّر تحديث الموقع',
      'fleetOnlineCount': '{online}/{total} متصل · {moving} متحرك',
      'routePointsCount': '{n} نقطة',
      'routeDistanceKm': 'المسار: {km} كم',
      'routeDeparture': 'المغادرة',
      'routeArrival': 'الوصول',
      'avgSpeedLabel': 'متوسط السرعة',
      'noRouteForDate': 'لا يوجد مسار لهذا اليوم.',
      'selectDateLabel': 'اختر تاريخاً',
      'todayLabel': 'اليوم',
      'routeMaxSpeedPoint': 'أعلى سرعة',
      'recentreRouteLabel': 'إطار المسار',
      'fromLabel': 'من',
      'toLabel': 'إلى',
      'timeRangeLabel': 'النطاق الزمني',
      'pickDateTimeHint': 'اضغط للتغيير',
      // Reports
      'reportsTitle': 'التقارير',
      'navReports': 'التقارير',
      'reportsSummary': 'الملخص',
      'reportsRoute': 'المسار',
      'reportsTrips': 'الرحلات',
      'reportsStops': 'التوقفات',
      'reportsEvents': 'الأحداث',
      'generateReport': 'توليد التقرير',
      'selectVehicle': 'اختر مركبة',
      'selectVehicleHint': 'اختر مركبة لتوليد التقرير.',
      'periodToday': 'اليوم',
      'periodYesterday': 'أمس',
      'periodThisWeek': 'هذا الأسبوع',
      'periodThisMonth': 'هذا الشهر',
      'periodCustom': 'مخصص',
      'noReportAvailable': 'لا يوجد تقرير لهذه الفترة.',
      'errorLoadingReport': 'خطأ في تحميل التقرير.',
      'loadingReport': 'جارٍ تحميل التقرير…',
      'totalDistanceLabel': 'المسافة الإجمالية',
      'engineTimeLabel': 'وقت المحرك',
      'stopDurationLabel': 'مدة التوقف',
      'fuelConsumedLabel': 'الوقود المستهلك',
      'viewOnMap': 'عرض على الخريطة',
      'exportPdf': 'تصدير PDF',
      'shareReport': 'مشاركة',
      'comingSoon': 'قريباً',
      'noTripsReport': 'لا رحلات مسجلة لهذه الفترة.',
      'noStopsReport': 'لا توقفات مسجلة لهذه الفترة.',
      'noEventsReport': 'لا أحداث مسجلة لهذه الفترة.',
      'noRouteReport': 'لا يوجد مسار GPS لهذه الفترة.',
      'loadingSummary': 'جارٍ تحميل الملخص…',
      'loadingRoute': 'جارٍ تحميل المسار…',
      'loadingStops': 'جارٍ تحميل التوقفات…',
      'loadingEvents': 'جارٍ تحميل الأحداث…',
      'errorLoadingRoute': 'خطأ في تحميل المسار.',
      'errorLoadingTrips': 'خطأ في تحميل الرحلات.',
      'errorLoadingStops': 'خطأ في تحميل التوقفات.',
      'errorLoadingEvents': 'خطأ في تحميل الأحداث.',
      'noRouteDataTitle': 'لا مسار',
      'noTripsDataTitle': 'لا رحلات',
      'noStopsDataTitle': 'لا توقفات',
      'noEventsDataTitle': 'لا أحداث',
      'noDataTitle': 'لا بيانات',
      'reportGenerateHintSummary': 'اختر مركبة وفترة زمنية،\nثم اضغط «توليد التقرير».',
      'reportGenerateHintRoute': 'ولّد التقرير لرؤية مسار GPS.',
      'reportGenerateHintTrips': 'ولّد التقرير لرؤية الرحلات.',
      'reportGenerateHintStops': 'ولّد التقرير لرؤية التوقفات.',
      'reportGenerateHintEvents': 'ولّد التقرير لرؤية الأحداث.',
      'noVehicleSelectedTitle': 'لم تُختر مركبة',
      'analysedPeriod': 'الفترة المحللة',
      'periodStartLabel': 'البداية',
      'periodEndLabel': 'النهاية',
      'totalDurationLabel': 'المدة الإجمالية',
      'maxSpeedKpiLabel': 'أقصى سرعة',
      'avgSpeedKpiLabel': 'متوسط السرعة',
      'gpsPointsLabel': 'نقاط GPS',
      'gpsTraceLabel': 'مسار GPS',
      'selectVehicleDropdownHint': 'اختر مركبة…',
      'selectVehicleSheetTitle': 'اختر مركبة',
      'routeMaxSpeedShort': 'أقصى سرعة',
      'routeAvgSpeedShort': 'متوسط',
      'routePointsShort': 'نقاط',
      'routeGpsPointsInfo': '{total} نقطة GPS · {drawn} نقطة معروضة',
      // Replay
      'replayRoute': 'إعادة تشغيل المسار',
      'replayPlay': 'تشغيل',
      'replayPause': 'إيقاف مؤقت',
      'replayRestart': 'إعادة البدء',
      'replaySpeed': 'سرعة التشغيل',
      'replayCurrentSpeed': 'السرعة الحالية',
      'replayCurrentTime': 'الوقت الحالي',
      'replayProgress': 'التقدم',
      'loadingReplay': 'جارٍ تحميل إعادة التشغيل…',
      'errorLoadingReplay': 'حدث خطأ أثناء تحميل إعادة التشغيل.',
      'notEnoughDataForReplay': 'بيانات GPS غير كافية لإعادة التشغيل.',
      'routeCompleted': 'انتهى المسار',
      'viewReplay': 'عرض إعادة التشغيل',
      // Speed chart
      'speedChartTitle': 'رسم السرعة',
      'speedChartMax': 'السرعة القصوى',
      'speedChartAvg': 'السرعة المتوسطة',
      'speedChartGpsPoints': 'نقاط GPS',
      'noSpeedData': 'لا توجد بيانات سرعة متاحة.',
      'viewSpeedChart': 'عرض رسم السرعة',
      // PDF / Share
      'exportPdfLabel': 'تصدير PDF',
      'shareReportLabel': 'مشاركة التقرير',
      'printLabel': 'طباعة',
      'generatingPdf': 'جارٍ إنشاء PDF…',
      'pdfGenerated': 'جاهز PDF',
      'pdfError': 'فشل إنشاء PDF',
      'shareAsPdf': 'مشاركة كـ PDF',
      'shareAsText': 'مشاركة كنص (واتساب / SMS)',
      'reportGeneratedBy': 'أُنشئ بواسطة ELMOGPS',
      'reportGeneratedOn': 'أُنشئ في',
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
      'aboutElmo': "À propos d'ELMO",
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
      'fleetOverview': "Vue d'ensemble",
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
      // Vehicles
      'vehicleList': 'Liste des véhicules',
      'searchTooltip': 'Rechercher',
      'refreshTooltip': 'Actualiser',
      'noVehicles': 'Aucun véhicule',
      'noVehiclesRegistered': 'Aucun véhicule enregistré.',
      'tryChangingFilters':
          'Essayez de modifier les critères de recherche ou de filtre.',
      'loadingFleet': 'Chargement de la flotte…',
      'searchHint': 'Rechercher par nom ou plaque…',
      'filterAll': 'Tout',
      'filterMoving': 'En mouvement',
      'filterStopped': 'Arrêté',
      'filterIdle': 'Inactif',
      'filterOffline': 'Hors ligne',
      'statusMovingPlural': 'En mouvement',
      'statusStoppedPlural': 'Arrêtés',
      'statusIdlePlural': 'Inactifs',
      'statusOfflinePlural': 'Hors ligne',
      'totalFleetCount': 'Flotte totale : {n} véhicule(s)',
      // Alerts
      'allAlerts': 'Toutes les alertes',
      'smartAlerts': 'Alertes intelligentes',
      'markAllRead': 'Marquer tout lu',
      'noAlerts': 'Aucune alerte',
      'noAlertsMessage': "Votre flotte n'a aucune alerte active.",
      'noSmartAlerts': 'Aucune alerte intelligente',
      'noSmartAlertsMessage': 'Les schémas critiques apparaîtront ici.',
      'loadingAlerts': 'Chargement des alertes…',
      'alertDetail': "Détail de l'alerte",
      'markRead': 'Marquer lu',
      'alertNotFound': 'Alerte introuvable',
      'vehicleLabel': 'Véhicule',
      'timeLabel': 'Heure',
      'locationLabel': 'Emplacement',
      'detailsLabel': 'Détails',
      // Analytics
      'weeklyReport': 'Rapport hebdomadaire',
      'weekOf': 'Semaine du {date}',
      'thisWeek': 'Cette semaine',
      'weeklyDistance': 'Distance hebdomadaire',
      'fleetKPIs': 'KPIs de la flotte',
      'highlightsLabel': 'Points forts',
      'mostActiveVehicleLabel': 'Véhicule le plus actif',
      'leastEfficientVehicleLabel': 'Véhicule le moins efficace',
      'topAlertCategoryLabel': "Catégorie d'alerte principale",
      'fleetEfficiencyScore': "Score d'efficacité de la flotte",
      'excellentPerformance': 'Excellente performance',
      'goodPerformance': 'Bon, des améliorations possibles',
      'needsAttention': 'Nécessite attention',
      'totalDistance': 'Distance totale',
      'totalTripsLabel': 'Trajets totaux',
      'idleTimeLabel': "Temps d'inactivité",
      'overspeedEvents': 'Événements de survitesse',
      'loadingAnalytics': 'Chargement des analyses…',
      // Trips
      'tripHistory': 'Historique des trajets',
      'filterByDate': 'Filtrer par date',
      'noTrips': 'Aucun trajet enregistré',
      'noTripsMessage': "L'historique des trajets apparaîtra ici.",
      'ongoingTrip': 'En cours',
      'distanceLabel': 'Distance',
      'durationLabel': 'Durée',
      'maxSpeedLabel': 'Vitesse max',
      'loadingTrips': 'Chargement des trajets…',
      // Notifications
      'noNotifications': 'Aucune notification',
      'allCaughtUp': 'Vous êtes à jour !',
      'failedToLoadNotifications':
          'Impossible de charger les notifications.',
      'loadingNotifications': 'Chargement des notifications…',
      // Commands
      'commandsTitle': 'Commandes',
      'commandHistoryTooltip': 'Historique des commandes',
      'noCommandsAvailable': 'Aucune commande disponible',
      'noCommandsMessage':
          "Ce modèle ne dispose d'aucune commande\naccessible avec votre niveau d'accès.",
      'commandHistoryTitle': 'Historique',
      'clearHistory': "Effacer l'historique",
      'noCommandsSent': 'Aucune commande envoyée',
      'noCommandsSentMessage':
          "L'historique apparaîtra ici après\nl'envoi de la première commande.",
      'confirmClearTitle': "Effacer l'historique",
      'confirmClearMessage':
          'Tous les journaux de commandes seront supprimés définitivement.',
      'clearLabel': 'Effacer',
      'statusSuccess': 'Succès',
      'statusFailed': 'Échec',
      'statusTimeout': 'Timeout',
      'statusPending': 'En attente',
      'statusQueued': 'En file',
      'statusRejected': 'Rejeté',
      'availableOf': '{available}/{total} disponible(s)',
      'errorLoadingData': 'Erreur de chargement: {error}',
      // Vehicle Detail
      'statusLabel': 'Statut',
      'telemetryRealTime': 'Télémétrie en direct',
      'ignitionLabel': 'Allumage',
      'motionLabel': 'Mouvement',
      'speedLabel': 'Vitesse',
      'fuelLabel': 'Carburant',
      'batteryVoltageLabel': 'Batterie',
      'brakingLabel': 'Freinage',
      'hardBrakeLabel': 'Brusque',
      'normalLabel': 'Normal',
      'currentLocation': 'Emplacement actuel',
      'trackVehicle': 'Suivre le véhicule',
      'recentTrips': 'Trajets récents',
      'allTrips': 'Tous les trajets',
      'driverLabel': 'Conducteur',
      'coordinatesLabel': 'Coordonnées',
      'lastUpdateLabel': 'Dernière MAJ',
      'noTripsToday': "Aucun trajet enregistré aujourd'hui.",
      'noAlertsVehicle': 'Aucune alerte pour ce véhicule.',
      'loadingVehicle': 'Chargement du véhicule…',
      'deviceInfo': 'Infos appareil',
      'deviceModelLabel': 'Modèle',
      'deviceIdLabel': 'ID appareil',
      'devicePhoneLabel': 'Téléphone',
      'positionDetails': 'Détails de position',
      'altitudeLabel': 'Altitude',
      'courseLabel': 'Direction',
      'odometerLabel': 'Compteur km',
      'accuracyLabel': 'Précision',
      // Maps
      'mapLoadingFleet': 'Chargement de la carte…',
      'mapLoadError': 'Impossible de charger les véhicules',
      'zoomIn': 'Zoom avant',
      'zoomOut': 'Zoom arrière',
      'fitBounds': 'Ajuster vue',
      'engineLabel': 'Moteur',
      'ignitionOnLabel': 'Allumé',
      'ignitionOffLabel': 'Éteint',
      'liveTrack': 'Suivi en direct',
      'centerMap': 'Centrer',
      'loadingVehicleLocation': 'Chargement de la position…',
      'followLabel': 'Suivre',
      'freeLabel': 'Libre',
      'routeLabel': 'Itinéraire',
      'vehicleDetails': 'Détails du véhicule',
      'todayRouteLabel': 'Itinéraire du jour',
      'locationUnavailable': 'Indisponible',
      'updateLocationFailed': 'Échec de mise à jour',
      'fleetOnlineCount': '{online}/{total} en ligne · {moving} en mouvement',
      'routePointsCount': '{n} pts',
      'routeDistanceKm': 'Itinéraire: {km} km',
      'routeDeparture': 'Départ',
      'routeArrival': 'Arrivée',
      'avgSpeedLabel': 'Vit. moy.',
      'noRouteForDate': 'Aucun trajet trouvé pour cette date.',
      'selectDateLabel': 'Choisir la date',
      'todayLabel': "Aujourd'hui",
      'routeMaxSpeedPoint': 'Vitesse max',
      'recentreRouteLabel': 'Recentrer',
      'fromLabel': 'De',
      'toLabel': 'À',
      'timeRangeLabel': 'Plage horaire',
      'pickDateTimeHint': 'Appuyer pour modifier',
      // Rapports
      'reportsTitle': 'Rapports',
      'navReports': 'Rapports',
      'reportsSummary': 'Résumé',
      'reportsRoute': 'Route',
      'reportsTrips': 'Trajets',
      'reportsStops': 'Arrêts',
      'reportsEvents': 'Événements',
      'generateReport': 'Générer le rapport',
      'selectVehicle': 'Sélectionner un véhicule',
      'selectVehicleHint': 'Sélectionnez un véhicule pour générer le rapport.',
      'periodToday': "Aujourd'hui",
      'periodYesterday': 'Hier',
      'periodThisWeek': 'Cette semaine',
      'periodThisMonth': 'Ce mois',
      'periodCustom': 'Personnalisé',
      'noReportAvailable': 'Aucun rapport disponible pour cette période.',
      'errorLoadingReport': 'Erreur lors du chargement du rapport.',
      'loadingReport': 'Chargement du rapport…',
      'totalDistanceLabel': 'Distance totale',
      'engineTimeLabel': 'Temps moteur',
      'stopDurationLabel': "Durée d'arrêt",
      'fuelConsumedLabel': 'Carburant consommé',
      'viewOnMap': 'Voir sur la carte',
      'exportPdf': 'Exporter PDF',
      'shareReport': 'Partager',
      'comingSoon': 'Disponible prochainement',
      'noTripsReport': 'Aucun trajet disponible pour cette période.',
      'noStopsReport': 'Aucun arrêt enregistré pour cette période.',
      'noEventsReport': 'Aucun événement enregistré pour cette période.',
      'noRouteReport': 'Aucun tracé GPS disponible pour cette période.',
      'loadingSummary': 'Chargement du résumé…',
      'loadingRoute': 'Chargement du tracé…',
      'loadingStops': 'Chargement des arrêts…',
      'loadingEvents': 'Chargement des événements…',
      'errorLoadingRoute': 'Erreur lors du chargement du tracé.',
      'errorLoadingTrips': 'Erreur lors du chargement des trajets.',
      'errorLoadingStops': 'Erreur lors du chargement des arrêts.',
      'errorLoadingEvents': 'Erreur lors du chargement des événements.',
      'noRouteDataTitle': 'Aucun tracé',
      'noTripsDataTitle': 'Aucun trajet',
      'noStopsDataTitle': 'Aucun arrêt',
      'noEventsDataTitle': 'Aucun événement',
      'noDataTitle': 'Aucune donnée',
      'reportGenerateHintSummary': 'Sélectionnez un véhicule et une période,\npuis appuyez sur « Générer le rapport ».',
      'reportGenerateHintRoute': 'Générez le rapport pour voir le tracé GPS.',
      'reportGenerateHintTrips': 'Générez le rapport pour voir les trajets.',
      'reportGenerateHintStops': 'Générez le rapport pour voir les arrêts.',
      'reportGenerateHintEvents': 'Générez le rapport pour voir les événements.',
      'noVehicleSelectedTitle': 'Aucun véhicule sélectionné',
      'analysedPeriod': 'Période analysée',
      'periodStartLabel': 'Début',
      'periodEndLabel': 'Fin',
      'totalDurationLabel': 'Durée totale',
      'maxSpeedKpiLabel': 'Vitesse maximale',
      'avgSpeedKpiLabel': 'Vitesse moyenne',
      'gpsPointsLabel': 'Points GPS',
      'gpsTraceLabel': 'Tracé GPS',
      'selectVehicleDropdownHint': 'Sélectionnez un véhicule…',
      'selectVehicleSheetTitle': 'Sélectionner un véhicule',
      'routeMaxSpeedShort': 'Vit. max',
      'routeAvgSpeedShort': 'Vit. moy',
      'routePointsShort': 'Points',
      'routeGpsPointsInfo': '{total} pts GPS · {drawn} pts affichés',
      // Replay
      'replayRoute': 'Rejouer le trajet',
      'replayPlay': 'Lecture',
      'replayPause': 'Pause',
      'replayRestart': 'Redémarrer',
      'replaySpeed': 'Vitesse de lecture',
      'replayCurrentSpeed': 'Vitesse actuelle',
      'replayCurrentTime': 'Heure actuelle',
      'replayProgress': 'Progression',
      'loadingReplay': 'Chargement du replay…',
      'errorLoadingReplay': 'Erreur lors du chargement du replay.',
      'notEnoughDataForReplay': 'Données GPS insuffisantes pour le replay.',
      'routeCompleted': 'Trajet terminé',
      'viewReplay': 'Voir replay',
      // Speed chart
      'speedChartTitle': 'Graphique de vitesse',
      'speedChartMax': 'Vitesse maximale',
      'speedChartAvg': 'Vitesse moyenne',
      'speedChartGpsPoints': 'Points GPS',
      'noSpeedData': 'Aucune donnée de vitesse disponible.',
      'viewSpeedChart': 'Voir graphique vitesse',
      // PDF / Partage
      'exportPdfLabel': 'Exporter PDF',
      'shareReportLabel': 'Partager le rapport',
      'printLabel': 'Imprimer',
      'generatingPdf': 'Génération du PDF…',
      'pdfGenerated': 'PDF prêt',
      'pdfError': 'Erreur de génération PDF',
      'shareAsPdf': 'Partager en PDF',
      'shareAsText': 'Partager en texte (WhatsApp/SMS)',
      'reportGeneratedBy': 'Généré par ELMOGPS',
      'reportGeneratedOn': 'Généré le',
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
      'footerText':
          'ELMO Inteligencia de Flota\n© 2025 Todos los derechos reservados',
      'fleetManager': 'Gestor de flota',
      // Vehicles
      'vehicleList': 'Lista de vehículos',
      'searchTooltip': 'Buscar',
      'refreshTooltip': 'Actualizar',
      'noVehicles': 'Sin vehículos',
      'noVehiclesRegistered': 'Sin vehículos registrados.',
      'tryChangingFilters':
          'Prueba a cambiar los criterios de búsqueda o filtro.',
      'loadingFleet': 'Cargando flota…',
      'searchHint': 'Buscar por nombre o matrícula…',
      'filterAll': 'Todo',
      'filterMoving': 'En movimiento',
      'filterStopped': 'Detenido',
      'filterIdle': 'Inactivo',
      'filterOffline': 'Sin conexión',
      'statusMovingPlural': 'En movimiento',
      'statusStoppedPlural': 'Detenidos',
      'statusIdlePlural': 'Inactivos',
      'statusOfflinePlural': 'Sin conexión',
      'totalFleetCount': 'Flota total: {n} vehículo(s)',
      // Alerts
      'allAlerts': 'Todas las alertas',
      'smartAlerts': 'Alertas inteligentes',
      'markAllRead': 'Marcar todo leído',
      'noAlerts': 'Sin alertas',
      'noAlertsMessage': 'Tu flota no tiene alertas activas.',
      'noSmartAlerts': 'Sin alertas inteligentes',
      'noSmartAlertsMessage': 'Los patrones críticos aparecerán aquí.',
      'loadingAlerts': 'Cargando alertas…',
      'alertDetail': 'Detalle de alerta',
      'markRead': 'Marcar leído',
      'alertNotFound': 'Alerta no encontrada',
      'vehicleLabel': 'Vehículo',
      'timeLabel': 'Hora',
      'locationLabel': 'Ubicación',
      'detailsLabel': 'Detalles',
      // Analytics
      'weeklyReport': 'Informe semanal',
      'weekOf': 'Semana del {date}',
      'thisWeek': 'Esta semana',
      'weeklyDistance': 'Distancia semanal',
      'fleetKPIs': 'KPIs de la flota',
      'highlightsLabel': 'Destacados',
      'mostActiveVehicleLabel': 'Vehículo más activo',
      'leastEfficientVehicleLabel': 'Vehículo menos eficiente',
      'topAlertCategoryLabel': 'Categoría de alerta principal',
      'fleetEfficiencyScore': 'Puntuación de eficiencia de la flota',
      'excellentPerformance': 'Excelente rendimiento',
      'goodPerformance': 'Bien, hay margen de mejora',
      'needsAttention': 'Necesita atención',
      'totalDistance': 'Distancia total',
      'totalTripsLabel': 'Viajes totales',
      'idleTimeLabel': 'Tiempo de inactividad',
      'overspeedEvents': 'Eventos de exceso de velocidad',
      'loadingAnalytics': 'Cargando análisis…',
      // Trips
      'tripHistory': 'Historial de viajes',
      'filterByDate': 'Filtrar por fecha',
      'noTrips': 'Sin viajes registrados',
      'noTripsMessage': 'El historial de viajes aparecerá aquí.',
      'ongoingTrip': 'En curso',
      'distanceLabel': 'Distancia',
      'durationLabel': 'Duración',
      'maxSpeedLabel': 'Vel. máxima',
      'loadingTrips': 'Cargando viajes…',
      // Notifications
      'noNotifications': 'Sin notificaciones',
      'allCaughtUp': '¡Estás al día!',
      'failedToLoadNotifications': 'Error al cargar las notificaciones.',
      'loadingNotifications': 'Cargando notificaciones…',
      // Commands
      'commandsTitle': 'Comandos',
      'commandHistoryTooltip': 'Historial de comandos',
      'noCommandsAvailable': 'Sin comandos disponibles',
      'noCommandsMessage':
          'Este modelo no tiene comandos\naccesibles con su nivel de acceso.',
      'commandHistoryTitle': 'Historial',
      'clearHistory': 'Borrar historial',
      'noCommandsSent': 'Sin comandos enviados',
      'noCommandsSentMessage':
          'El historial aparecerá aquí tras\nenviar el primer comando.',
      'confirmClearTitle': 'Borrar historial',
      'confirmClearMessage':
          'Todos los registros de comandos serán eliminados permanentemente.',
      'clearLabel': 'Borrar',
      'statusSuccess': 'Éxito',
      'statusFailed': 'Fallido',
      'statusTimeout': 'Timeout',
      'statusPending': 'Pendiente',
      'statusQueued': 'En cola',
      'statusRejected': 'Rechazado',
      'availableOf': '{available}/{total} disponible(s)',
      'errorLoadingData': 'Error: {error}',
      // Vehicle Detail
      'statusLabel': 'Estado',
      'telemetryRealTime': 'Telemetría en tiempo real',
      'ignitionLabel': 'Encendido',
      'motionLabel': 'Movimiento',
      'speedLabel': 'Velocidad',
      'fuelLabel': 'Combustible',
      'batteryVoltageLabel': 'Batería',
      'brakingLabel': 'Frenado',
      'hardBrakeLabel': 'Brusco',
      'normalLabel': 'Normal',
      'currentLocation': 'Ubicación actual',
      'trackVehicle': 'Rastrear vehículo',
      'recentTrips': 'Viajes recientes',
      'allTrips': 'Todos los viajes',
      'driverLabel': 'Conductor',
      'coordinatesLabel': 'Coordenadas',
      'lastUpdateLabel': 'Última actualización',
      'noTripsToday': 'Sin viajes registrados hoy.',
      'noAlertsVehicle': 'Sin alertas para este vehículo.',
      'loadingVehicle': 'Cargando vehículo…',
      'deviceInfo': 'Info del dispositivo',
      'deviceModelLabel': 'Modelo',
      'deviceIdLabel': 'ID dispositivo',
      'devicePhoneLabel': 'Teléfono',
      'positionDetails': 'Detalles de posición',
      'altitudeLabel': 'Altitud',
      'courseLabel': 'Dirección',
      'odometerLabel': 'Cuentakilómetros',
      'accuracyLabel': 'Precisión',
      // Maps
      'mapLoadingFleet': 'Cargando mapa…',
      'mapLoadError': 'Error al cargar vehículos',
      'zoomIn': 'Acercar',
      'zoomOut': 'Alejar',
      'fitBounds': 'Ajustar vista',
      'engineLabel': 'Motor',
      'ignitionOnLabel': 'Encendido',
      'ignitionOffLabel': 'Apagado',
      'liveTrack': 'Seguimiento directo',
      'centerMap': 'Centrar',
      'loadingVehicleLocation': 'Cargando ubicación…',
      'followLabel': 'Seguir',
      'freeLabel': 'Libre',
      'routeLabel': 'Ruta',
      'vehicleDetails': 'Detalles del vehículo',
      'todayRouteLabel': 'Ruta de hoy',
      'locationUnavailable': 'No disponible',
      'updateLocationFailed': 'Error de actualización',
      'fleetOnlineCount': '{online}/{total} en línea · {moving} en marcha',
      'routePointsCount': '{n} puntos',
      'routeDistanceKm': 'Ruta: {km} km',
      'routeDeparture': 'Salida',
      'routeArrival': 'Llegada',
      'avgSpeedLabel': 'Vel. media',
      'noRouteForDate': 'Sin ruta para esta fecha.',
      'selectDateLabel': 'Seleccionar fecha',
      'todayLabel': 'Hoy',
      'routeMaxSpeedPoint': 'Vel. máxima',
      'recentreRouteLabel': 'Centrar ruta',
      'fromLabel': 'Desde',
      'toLabel': 'Hasta',
      'timeRangeLabel': 'Rango horario',
      'pickDateTimeHint': 'Toque para cambiar',
      // Reports
      'reportsTitle': 'Informes',
      'navReports': 'Informes',
      'reportsSummary': 'Resumen',
      'reportsRoute': 'Ruta',
      'reportsTrips': 'Viajes',
      'reportsStops': 'Paradas',
      'reportsEvents': 'Eventos',
      'generateReport': 'Generar informe',
      'selectVehicle': 'Seleccionar vehículo',
      'selectVehicleHint': 'Seleccione un vehículo para generar el informe.',
      'periodToday': 'Hoy',
      'periodYesterday': 'Ayer',
      'periodThisWeek': 'Esta semana',
      'periodThisMonth': 'Este mes',
      'periodCustom': 'Personalizado',
      'noReportAvailable': 'No hay informe disponible para este período.',
      'errorLoadingReport': 'Error al cargar el informe.',
      'loadingReport': 'Cargando informe…',
      'totalDistanceLabel': 'Distancia total',
      'engineTimeLabel': 'Tiempo de motor',
      'stopDurationLabel': 'Duración de parada',
      'fuelConsumedLabel': 'Combustible consumido',
      'viewOnMap': 'Ver en mapa',
      'exportPdf': 'Exportar PDF',
      'shareReport': 'Compartir',
      'comingSoon': 'Próximamente',
      'noTripsReport': 'No hay viajes disponibles para este período.',
      'noStopsReport': 'No hay paradas registradas para este período.',
      'noEventsReport': 'No hay eventos registrados para este período.',
      'noRouteReport': 'No hay traza GPS disponible para este período.',
      'loadingSummary': 'Cargando resumen…',
      'loadingRoute': 'Cargando traza…',
      'loadingStops': 'Cargando paradas…',
      'loadingEvents': 'Cargando eventos…',
      'errorLoadingRoute': 'Error al cargar la traza.',
      'errorLoadingTrips': 'Error al cargar los viajes.',
      'errorLoadingStops': 'Error al cargar las paradas.',
      'errorLoadingEvents': 'Error al cargar los eventos.',
      'noRouteDataTitle': 'Sin traza',
      'noTripsDataTitle': 'Sin viajes',
      'noStopsDataTitle': 'Sin paradas',
      'noEventsDataTitle': 'Sin eventos',
      'noDataTitle': 'Sin datos',
      'reportGenerateHintSummary': 'Selecciona un vehículo y un período,\nluego pulsa «Generar informe».',
      'reportGenerateHintRoute': 'Genera el informe para ver la traza GPS.',
      'reportGenerateHintTrips': 'Genera el informe para ver los viajes.',
      'reportGenerateHintStops': 'Genera el informe para ver las paradas.',
      'reportGenerateHintEvents': 'Genera el informe para ver los eventos.',
      'noVehicleSelectedTitle': 'Ningún vehículo seleccionado',
      'analysedPeriod': 'Período analizado',
      'periodStartLabel': 'Inicio',
      'periodEndLabel': 'Fin',
      'totalDurationLabel': 'Duración total',
      'maxSpeedKpiLabel': 'Velocidad máxima',
      'avgSpeedKpiLabel': 'Vel. media',
      'gpsPointsLabel': 'Puntos GPS',
      'gpsTraceLabel': 'Traza GPS',
      'selectVehicleDropdownHint': 'Seleccione un vehículo…',
      'selectVehicleSheetTitle': 'Seleccionar un vehículo',
      'routeMaxSpeedShort': 'Vel. máx',
      'routeAvgSpeedShort': 'Vel. med',
      'routePointsShort': 'Puntos',
      'routeGpsPointsInfo': '{total} pts GPS · {drawn} pts mostrados',
      // Replay
      'replayRoute': 'Reproducir ruta',
      'replayPlay': 'Reproducir',
      'replayPause': 'Pausa',
      'replayRestart': 'Reiniciar',
      'replaySpeed': 'Velocidad de reproducción',
      'replayCurrentSpeed': 'Velocidad actual',
      'replayCurrentTime': 'Hora actual',
      'replayProgress': 'Progreso',
      'loadingReplay': 'Cargando reproducción…',
      'errorLoadingReplay': 'Error al cargar la reproducción.',
      'notEnoughDataForReplay': 'Datos GPS insuficientes para reproducir la ruta.',
      'routeCompleted': 'Ruta finalizada',
      'viewReplay': 'Ver replay',
      // Speed chart
      'speedChartTitle': 'Gráfico de velocidad',
      'speedChartMax': 'Velocidad máxima',
      'speedChartAvg': 'Velocidad media',
      'speedChartGpsPoints': 'Puntos GPS',
      'noSpeedData': 'No hay datos de velocidad disponibles.',
      'viewSpeedChart': 'Ver gráfico de velocidad',
      // PDF / Compartir
      'exportPdfLabel': 'Exportar PDF',
      'shareReportLabel': 'Compartir informe',
      'printLabel': 'Imprimir',
      'generatingPdf': 'Generando PDF…',
      'pdfGenerated': 'PDF listo',
      'pdfError': 'Error al generar PDF',
      'shareAsPdf': 'Compartir como PDF',
      'shareAsText': 'Compartir como texto (WhatsApp/SMS)',
      'reportGeneratedBy': 'Generado por ELMOGPS',
      'reportGeneratedOn': 'Generado el',
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
