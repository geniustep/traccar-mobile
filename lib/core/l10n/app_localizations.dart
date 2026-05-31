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
  String get aboutFleetTrackingSubtitle => _t('aboutFleetTrackingSubtitle');
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
  String get noVehiclesInFilter => _t('noVehiclesInFilter');
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
  String get lastKnownData => _t('lastKnownData');

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
  String get cmdConfirmRequired => _t('cmdConfirmRequired');
  String get cmdCriticalAction => _t('cmdCriticalAction');
  String get cmdConfirmSendMessage => _t('cmdConfirmSendMessage');
  String get cmdCriticalWarningDefault => _t('cmdCriticalWarningDefault');
  String get cmdTypeToConfirm => _t('cmdTypeToConfirm');
  String get cmdExecuteCommand => _t('cmdExecuteCommand');
  String get cmdDeviceOnline => _t('cmdDeviceOnline');
  String get cmdDeviceOffline => _t('cmdDeviceOffline');
  String get cmdLastUpdate => _t('cmdLastUpdate');
  String get cmdVehicleStopped => _t('cmdVehicleStopped');
  String get cmdSentSuccess => _t('cmdSentSuccess');
  String get cmdSentFailed => _t('cmdSentFailed');
  String get cmdQueuedMessage => _t('cmdQueuedMessage');
  String get cmdErrorSavedNotFound => _t('cmdErrorSavedNotFound');
  String get cmdErrorUnsupported => _t('cmdErrorUnsupported');
  String get cmdErrorTimeout => _t('cmdErrorTimeout');
  String get cmdErrorUnauthorized => _t('cmdErrorUnauthorized');
  String get cmdErrorForbidden => _t('cmdErrorForbidden');
  String get cmdErrorNoConnection => _t('cmdErrorNoConnection');
  String get cmdErrorBadRequest => _t('cmdErrorBadRequest');
  String get cmdErrorServer => _t('cmdErrorServer');
  String get cmdErrorUnexpected => _t('cmdErrorUnexpected');
  String get cmdConfirmWord => _t('cmdConfirmWord');
  String get cmdLoadFailed => _t('cmdLoadFailed');
  String get cmdRetry => _t('cmdRetry');
  String get vehicle => _t('vehicle');

  // ── Command Logs Screen ─────────────────────────────────────────────────────
  String get commandHistory => _t('commandHistory');
  String get commandHistoryEmpty => _t('commandHistoryEmpty');
  String get clearHistoryConfirmMessage => _t('clearHistoryConfirmMessage');
  String get delete => _t('delete');
  String get generalInfo => _t('generalInfo');
  String get command => _t('command');
  String get systemType => _t('systemType');
  String get category => _t('category');
  String get risk => _t('risk');
  String get method => _t('method');
  String get date => _t('date');
  String get sentBy => _t('sentBy');
  String get userId => _t('userId');
  String get executionContext => _t('executionContext');
  String get connectionStatus => _t('connectionStatus');
  String get online => _t('online');
  String get speed => _t('speed');
  String get device => _t('device');
  String get errorMessage => _t('errorMessage');
  String get message => _t('message');
  String get technicalData => _t('technicalData');
  String get technicalReason => _t('technicalReason');
  String get sentAttributes => _t('sentAttributes');
  String get rawResponse => _t('rawResponse');
  String get copy => _t('copy');
  String get noTechnicalData => _t('noTechnicalData');

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
  String get todaySummaryTitle => _t('todaySummaryTitle');
  String get engineHoursLabel => _t('engineHoursLabel');
  String get vehicleActionsTitle => _t('vehicleActionsTitle');
  String get technicalInfoTitle => _t('technicalInfoTitle');
  String get noSummaryData => _t('noSummaryData');
  String get noAlertsForVehicle => _t('noAlertsForVehicle');
  String get alertsLoadError => _t('alertsLoadError');
  String get tripsLoadError => _t('tripsLoadError');

  // ── Report entry bottom sheet ─────────────────────────────────────────
  String get reportSheetTitle => _t('reportSheetTitle');
  String get selectReportType => _t('selectReportType');
  String get selectPeriod => _t('selectPeriod');
  String get startDateLabel => _t('startDateLabel');
  String get endDateLabel => _t('endDateLabel');
  String get invalidDateRange => _t('invalidDateRange');
  String get generateVehicleReport => _t('generateVehicleReport');

  // ── Replay entry bottom sheet ─────────────────────────────────────────
  String get replaySheetTitle => _t('replaySheetTitle');
  String get selectReplayPeriod => _t('selectReplayPeriod');
  String get startReplay => _t('startReplay');
  String get replayRangeTooLong => _t('replayRangeTooLong');
  String get noReplayDataForPeriod => _t('noReplayDataForPeriod');

  // ── Report PDF / share ──────────────────────────────────────────────
  String reportPdfSubject(String name) => '${_t('reportPdfSubjectPrefix')} — $name';
  String reportPdfTitle(String name) => '${_t('reportPdfTitlePrefix')} — $name';

  String get todayRouteLabel => _t('todayRouteLabel');
  String get mapSearchVehicleHint => _t('mapSearchVehicleHint');
  String get filterAlertsMap => _t('filterAlertsMap');
  String get mapEmptyFilteredState => _t('mapEmptyFilteredState');
  String get mapNoVehiclesEmpty => _t('mapNoVehiclesEmpty');
  String get liveFollowRunningLabel => _t('liveFollowRunningLabel');
  String get resumeVehicleFollow => _t('resumeVehicleFollow');
  String get mapLayersTitle => _t('mapLayersTitle');
  String get mapLayerAlerts => _t('mapLayerAlerts');
  String get mapLayerRoutesToday => _t('mapLayerRoutesToday');
  String get mapTypeNormal => _t('mapTypeNormal');
  String get mapTypeSatellite => _t('mapTypeSatellite');
  String get mapTypeTerrain => _t('mapTypeTerrain');
  String get mapVehicleListTitle => _t('mapVehicleListTitle');
  String get uniqueIdShortLabel => _t('uniqueIdShortLabel');
  String get mapLayersButton => _t('mapLayersButton');
  String get filterVehicles => _t('filterVehicles');
  String get chooseVehicles => _t('chooseVehicles');
  String get chooseVehiclesHint => _t('chooseVehiclesHint');
  String get showAllVehicles => _t('showAllVehicles');
  String get showAllVehiclesOnMap => _t('showAllVehiclesOnMap');
  String get showVehicleOnMap => _t('showVehicleOnMap');
  String showSelectedVehiclesOnMap(int count) =>
      _t('showSelectedVehiclesOnMap').replaceAll('{count}', '$count');
  String get clearSelection => _t('clearSelection');
  String selectedVehiclesCount(int count) =>
      _t('selectedVehiclesCount').replaceAll('{count}', '$count');
  String get mapFilterSearchHint => _t('mapFilterSearchHint');
  String get onlineOnlyFilter => _t('onlineOnlyFilter');
  String get movingOnlyFilter => _t('movingOnlyFilter');
  String vehiclesShownCount(int count) =>
      _t('vehiclesShownCount').replaceAll('{count}', '$count');
  String get clearMapFilter => _t('clearMapFilter');
  String get noVehiclesMatchFilter => _t('noVehiclesMatchFilter');
  String get selectVehiclesTitle => _t('selectVehiclesTitle');
  String get mapFilterActiveLabel => _t('mapFilterActiveLabel');
  String get mapFilterZeroVisible => _t('mapFilterZeroVisible');
  String get selectMultipleVehiclesHint => _t('selectMultipleVehiclesHint');
  String vehiclesSelectedCount(int count) =>
      _t('vehiclesSelectedCount').replaceAll('{count}', '$count');
  String matchingVehiclesCount(int count) =>
      _t('matchingVehiclesCount').replaceAll('{count}', '$count');
  String get noMatchingVehicles => _t('noMatchingVehicles');
  String get vehicleComparisonTitle => _t('vehicleComparisonTitle');
  String get compareVehicles => _t('compareVehicles');
  String compareVehiclesCount(int count) =>
      _t('compareVehiclesCount').replaceAll('{count}', '$count');
  String comparedVehiclesCount(int count) =>
      _t('comparedVehiclesCount').replaceAll('{count}', '$count');
  String get selectAtLeastTwoVehicles => _t('selectAtLeastTwoVehicles');
  String get todayComparison => _t('todayComparison');
  String get stopsToday => _t('stopsToday');
  String get maxSpeed => _t('maxSpeed');
  String get averageSpeed => _t('averageSpeed');
  String get stopDuration => _t('stopDuration');
  String get lastUpdate => _t('lastUpdate');
  String get highestDistance => _t('highestDistance');
  String get highestAlerts => _t('highestAlerts');
  String get highestStopDuration => _t('highestStopDuration');
  String get mostRecentUpdate => _t('mostRecentUpdate');
  String get removeFromComparison => _t('removeFromComparison');
  String get noComparisonData => _t('noComparisonData');
  String get comparisonLoadFailed => _t('comparisonLoadFailed');
  String get comparisonLoading => _t('comparisonLoading');
  String get comparisonLoadingAnalyzing => _t('comparisonLoadingAnalyzing');
  String get backToMap => _t('backToMap');
  String get multiVehicleReplayTitle => _t('multiVehicleReplayTitle');
  String get replaySelectedVehicles => _t('replaySelectedVehicles');
  String replayVehiclesCount(int count) =>
      _t('replayVehiclesCount').replaceAll('{count}', '$count');
  String get replayComparedVehicles => _t('replayComparedVehicles');
  String get selectAtLeastTwoVehiclesReplay =>
      _t('selectAtLeastTwoVehiclesReplay');
  String get multiReplayLimitMessage => _t('multiReplayLimitMessage');
  String get multiReplayLoading => _t('multiReplayLoading');
  String get multiReplayNoData => _t('multiReplayNoData');
  String get multiReplayLoadFailed => _t('multiReplayLoadFailed');
  String get multiReplayAutoFollow => _t('multiReplayAutoFollow');
  String get multiReplayActiveVehicle => _t('multiReplayActiveVehicle');
  String get multiReplayVisibleVehicles => _t('multiReplayVisibleVehicles');
  String get multiReplayHide => _t('multiReplayHide');
  String get multiReplayShow => _t('multiReplayShow');
  String get multiReplayNoVisibleVehicles => _t('multiReplayNoVisibleVehicles');
  String get multiReplaySpeedColors => _t('multiReplaySpeedColors');
  String get multiReplayNoFixAtTime => _t('multiReplayNoFixAtTime');
  String get multiReplayComparison => _t('multiReplayComparison');
  String get multiReplaySummary => _t('multiReplaySummary');
  String get multiReplayMovingTime => _t('multiReplayMovingTime');
  String get multiReplayStoppedTime => _t('multiReplayStoppedTime');
  String get multiReplayInsufficientData => _t('multiReplayInsufficientData');
  String get multiReplayHiddenVehicle => _t('multiReplayHiddenVehicle');
  String get multiReplayKpiLoadedNote => _t('multiReplayKpiLoadedNote');
  String get multiReplayDistanceApproxNote => _t('multiReplayDistanceApproxNote');
  String get multiReplayRouteStart => _t('multiReplayRouteStart');
  String get multiReplayRouteEnd => _t('multiReplayRouteEnd');
  String get multiReplayInsightLongestStop => _t('multiReplayInsightLongestStop');
  String get multiReplayInsightHighestSpeed => _t('multiReplayInsightHighestSpeed');
  String get multiReplayInsightMostOverspeed => _t('multiReplayInsightMostOverspeed');
  String get multiReplayInsightFirstMovement => _t('multiReplayInsightFirstMovement');
  String get multiReplayInsightEarliestEnd => _t('multiReplayInsightEarliestEnd');
  String get routeDataUnavailable => _t('routeDataUnavailable');
  String get hideVehicle => _t('hideVehicle');
  String get showVehicle => _t('showVehicle');
  String get replayToday => _t('replayToday');
  String get chooseReplayDate => _t('chooseReplayDate');
  String get replayMultiVehicles => _t('replayMultiVehicles');
  String get stopsCountLabel => _t('stopsCountLabel');
  String get alertsTodayLabel => _t('alertsTodayLabel');
  String get alertsForVehicle => _t('alertsForVehicle');
  String alertsForVehicleName(String name) =>
      _t('alertsForVehicleName').replaceAll('{name}', name);
  String get tripDateFilter => _t('tripDateFilter');
  String get clearDateFilter => _t('clearDateFilter');
  String get centerFleetTooltip => _t('centerFleetTooltip');
  String fleetSummaryBar(int online, int total, int moving, int idle) =>
      _t('fleetSummaryBar')
          .replaceAll('{online}', '$online')
          .replaceAll('{total}', '$total')
          .replaceAll('{moving}', '$moving')
          .replaceAll('{idle}', '$idle');
  String get locationUnavailable => _t('locationUnavailable');
  String get noLivePosition => _t('noLivePosition');
  String get positionMayBeOutdated => _t('positionMayBeOutdated');
  String get lastPositionIsOld => _t('lastPositionIsOld');
  String get currentAddress => _t('currentAddress');
  String get liveTracking => _t('liveTracking');
  String get liveTrackingActive => _t('liveTrackingActive');
  String get trackingDataStale => _t('trackingDataStale');
  String get trackingReconnecting => _t('trackingReconnecting');
  String get trackingOffline => _t('trackingOffline');
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

  // ── Route Intelligence threshold preview (Phase 6G, read-only) ─────────────
  String routeIntelSpeedKmh(String v) =>
      _t('routeIntelSpeedKmh').replaceAll('{v}', v);
  String routeIntelMinutesShort(int n) =>
      _t('routeIntelMinutesShort').replaceAll('{n}', '$n');
  String get routeIntelPreviewTitle => _t('routeIntelPreviewTitle');
  String get routeIntelPreviewReadOnlyHint =>
      _t('routeIntelPreviewReadOnlyHint');
  String get routeIntelPreviewLoadingLayers =>
      _t('routeIntelPreviewLoadingLayers');
  String get routeIntelPreviewGroupLoadError =>
      _t('routeIntelPreviewGroupLoadError');
  String get routeIntelSettingsPreviewSection =>
      _t('routeIntelSettingsPreviewSection');
  String get routeIntelOverspeedThreshold =>
      _t('routeIntelOverspeedThreshold');
  String get routeIntelStopEnter => _t('routeIntelStopEnter');
  String get routeIntelStopExit => _t('routeIntelStopExit');
  String get routeIntelMinStopDuration => _t('routeIntelMinStopDuration');
  String get routeIntelDetectStops => _t('routeIntelDetectStops');
  String get routeIntelDetectOverspeed => _t('routeIntelDetectOverspeed');
  String get routeIntelDetectIgnition => _t('routeIntelDetectIgnition');
  String get routeIntelSourceDevice => _t('routeIntelSourceDevice');
  String get routeIntelSourceGroup => _t('routeIntelSourceGroup');
  String get routeIntelSourceUser => _t('routeIntelSourceUser');
  String get routeIntelSourceLocal => _t('routeIntelSourceLocal');
  String get routeIntelSourceDefault => _t('routeIntelSourceDefault');
  String get routeIntelEnabled => _t('routeIntelEnabled');
  String get routeIntelDisabled => _t('routeIntelDisabled');
  String get routeIntelLocalEditorTitle => _t('routeIntelLocalEditorTitle');
  String get routeIntelLocalParamsHeading => _t('routeIntelLocalParamsHeading');
  String get routeIntelSave => _t('routeIntelSave');
  String get routeIntelResetLocalPrefsSettings =>
      _t('routeIntelResetLocalPrefsSettings');
  String get routeIntelSavedSnack => _t('routeIntelSavedSnack');
  String get routeIntelResetSnack => _t('routeIntelResetSnack');
  String get routeIntelInvalidValue => _t('routeIntelInvalidValue');
  String get routeIntelLocalOnlyCentralWarning =>
      _t('routeIntelLocalOnlyCentralWarning');

  // ── Route Intelligence vehicle central edit (Phase 6K) ─────────────────────
  String get routeIntelVehicleEditTitle => _t('routeIntelVehicleEditTitle');
  String get routeIntelVehicleEditSubtitle =>
      _t('routeIntelVehicleEditSubtitle');
  String get routeIntelVehicleEditButton => _t('routeIntelVehicleEditButton');
  String get routeIntelVehicleSave => _t('routeIntelVehicleSave');
  String get routeIntelVehicleReset => _t('routeIntelVehicleReset');
  String get routeIntelVehicleSaved => _t('routeIntelVehicleSaved');
  String get routeIntelVehicleResetDone => _t('routeIntelVehicleResetDone');
  String get routeIntelVehicleSaveError => _t('routeIntelVehicleSaveError');
  String get routeIntelVehicleResetError => _t('routeIntelVehicleResetError');
  String get routeIntelVehicleOnlyHint => _t('routeIntelVehicleOnlyHint');
  String get routeIntelVehicleNoPermissionHint =>
      _t('routeIntelVehicleNoPermissionHint');
  String get routeIntelVehicleResetConfirmMessage =>
      _t('routeIntelVehicleResetConfirmMessage');

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

  String get routeEventsTimelineTitle => _t('routeEventsTimelineTitle');
  String get routeEventsNoneDetected => _t('routeEventsNoneDetected');
  String get routeEventsSeeMore => _t('routeEventsSeeMore');
  String get routeEventsSeeLess => _t('routeEventsSeeLess');
  String get routeEventFilterAll => _t('routeEventFilterAll');
  String get routeEventFilterStops => _t('routeEventFilterStops');
  String get routeEventFilterOverspeed => _t('routeEventFilterOverspeed');
  String get routeEventFilterIgnition => _t('routeEventFilterIgnition');
  String get routeEventsFilterNoMatches => _t('routeEventsFilterNoMatches');

  // ── Trip segmentation (Phase 8) ─────────────────────────────────────────────
  String get tripsTitle => _t('tripsTitle');
  String get tripLabel => _t('tripLabel');
  String tripTitle(int n) => _t('tripTitle').replaceAll('{n}', '$n');
  String get tripStart => _t('tripStart');
  String get tripEnd => _t('tripEnd');
  String get tripDuration => _t('tripDuration');
  String get tripDistance => _t('tripDistance');
  String tripStopsCount(int n) => _t('tripStopsCount').replaceAll('{n}', '$n');
  String tripOverspeedCount(int n) =>
      _t('tripOverspeedCount').replaceAll('{n}', '$n');
  String get tripMaxSpeed => _t('tripMaxSpeed');
  String get tripReplay => _t('tripReplay');
  String get tripViewOnMap => _t('tripViewOnMap');
  String get tripsNoneDetected => _t('tripsNoneDetected');
  String get tripShort => _t('tripShort');
  String get tripKm => _t('tripKm');
  String get tripMin => _t('tripMin');
  String tripTimeArrow(String from, String to) => _t('tripTimeArrow')
      .replaceAll('{from}', from)
      .replaceAll('{to}', to);
  String get tripKmUnit => _t('tripKmUnit');
  String tripIgnitionSummary(int onCount, int offCount) => _t('tripIgnitionSummary')
      .replaceAll('{on}', '$onCount')
      .replaceAll('{off}', '$offCount');

  // ── Trip behavior score (Phase 9B) ─────────────────────────────────────────
  String get driverScoreLabel => _t('driverScoreLabel');
  String get driverScoreExcellent => _t('driverScoreExcellent');
  String get driverScoreGood => _t('driverScoreGood');
  String get driverScoreModerate => _t('driverScoreModerate');
  String get driverScoreHighRisk => _t('driverScoreHighRisk');
  String get driverScoreUnknown => _t('driverScoreUnknown');
  String get driverScoreNotScorable => _t('driverScoreNotScorable');
  String get driverScoreTripTooShort => _t('driverScoreTripTooShort');

  // ── Daily / period behavior score UI (Phase 9E) ─────────────────────────────
  String get dailyScoreTitle => _t('dailyScoreTitle');
  String get dailyScorePeriodTitle => _t('dailyScorePeriodTitle');
  String get dailyScoreNotScorable => _t('dailyScoreNotScorable');
  String get dailyScoreInsufficientData => _t('dailyScoreInsufficientData');
  String dailyScoreTripCount(int n) =>
      _t('dailyScoreTripCount').replaceAll('{n}', '$n');
  String dailyScoreScorableTrips(int scored, int total) => _t('dailyScoreScorableTrips')
      .replaceAll('{scored}', '$scored')
      .replaceAll('{total}', '$total');
  String dailyScoreTotalDistance(String km) =>
      _t('dailyScoreTotalDistance').replaceAll('{km}', km);
  String dailyScoreOverspeed(int n) =>
      _t('dailyScoreOverspeed').replaceAll('{n}', '$n');
  String dailyScoreStops(int n) =>
      _t('dailyScoreStops').replaceAll('{n}', '$n');
  String dailyScoreBestTrip(String name) =>
      _t('dailyScoreBestTrip').replaceAll('{name}', name);
  String dailyScoreWorstTrip(String name) =>
      _t('dailyScoreWorstTrip').replaceAll('{name}', name);
  String get dailyScoreNoTrips => _t('dailyScoreNoTrips');
  String get dailyScoreDetailsTitle => _t('dailyScoreDetailsTitle');
  String get dailyScoreEvaluatedTrips => _t('dailyScoreEvaluatedTrips');
  String get dailyScoreUnscoredTrips => _t('dailyScoreUnscoredTrips');
  String get dailyScoreTotalDuration => _t('dailyScoreTotalDuration');
  String get dailyScoreTotalStopDuration => _t('dailyScoreTotalStopDuration');
  String get dailyScoreUnscoredExcludedHint => _t('dailyScoreUnscoredExcludedHint');
  String get dailyScoreNoEvaluatedTrips => _t('dailyScoreNoEvaluatedTrips');
  String get dailyScoreTapForDetails => _t('dailyScoreTapForDetails');
  String get dailyScoreBestTripLabel => _t('dailyScoreBestTripLabel');
  String get dailyScoreWorstTripLabel => _t('dailyScoreWorstTripLabel');

  // ── Fleet intelligence dashboard (Phase 10B) ───────────────────────────────
  String get fleetIntelTitle => _t('fleetIntelTitle');
  String get fleetIntelSubtitle => _t('fleetIntelSubtitle');
  String get fleetIntelScore => _t('fleetIntelScore');
  String get fleetIntelNotScorable => _t('fleetIntelNotScorable');
  String get fleetIntelInsufficientData => _t('fleetIntelInsufficientData');
  String get fleetIntelVehicles => _t('fleetIntelVehicles');
  String get fleetIntelActiveVehicles => _t('fleetIntelActiveVehicles');
  String get fleetIntelInactiveVehicles => _t('fleetIntelInactiveVehicles');
  String get fleetIntelTrips => _t('fleetIntelTrips');
  String get fleetIntelDistance => _t('fleetIntelDistance');
  String get fleetIntelOverspeed => _t('fleetIntelOverspeed');
  String get fleetIntelStops => _t('fleetIntelStops');
  String get fleetIntelBestVehicle => _t('fleetIntelBestVehicle');
  String get fleetIntelWorstVehicle => _t('fleetIntelWorstVehicle');
  String get fleetIntelMostActiveVehicle => _t('fleetIntelMostActiveVehicle');
  String get fleetIntelMostOverspeedVehicle => _t('fleetIntelMostOverspeedVehicle');
  String get fleetIntelMostStoppedVehicle => _t('fleetIntelMostStoppedVehicle');
  String get fleetIntelNeedsAttention => _t('fleetIntelNeedsAttention');
  String get fleetIntelRiskDistribution => _t('fleetIntelRiskDistribution');
  String get fleetIntelNoData => _t('fleetIntelNoData');
  String get fleetIntelLoading => _t('fleetIntelLoading');
  String get fleetIntelError => _t('fleetIntelError');
  String get fleetIntelToday => _t('fleetIntelToday');
  String get fleetIntelYesterday => _t('fleetIntelYesterday');
  String get fleetIntelLast7Days => _t('fleetIntelLast7Days');
  String get fleetIntelNoTripsInPeriod => _t('fleetIntelNoTripsInPeriod');
  String fleetIntelVehicleFallback(String id) =>
      _t('fleetIntelVehicleFallback').replaceAll('{id}', id);
  String fleetIntelDrivingDuration(String value) =>
      _t('fleetIntelDrivingDuration').replaceAll('{value}', value);
  String fleetIntelStopDuration(String value) =>
      _t('fleetIntelStopDuration').replaceAll('{value}', value);
  String fleetIntelSampleNote(int included, int total, int cap) => _t('fleetIntelSampleNote')
      .replaceAll('{included}', '$included')
      .replaceAll('{total}', '$total')
      .replaceAll('{cap}', '$cap');
  String get fleetIntelOpenTrackingTooltip => _t('fleetIntelOpenTrackingTooltip');
  String get fleetIntelDrivingTime => _t('fleetIntelDrivingTime');
  String get fleetIntelPartialRoutes => _t('fleetIntelPartialRoutes');
  String get fleetIntelCustomPeriod => _t('fleetIntelCustomPeriod');
  String get fleetIntelRefresh => _t('fleetIntelRefresh');
  String fleetIntelUpdatedAt(String time) =>
      _t('fleetIntelUpdatedAt').replaceAll('{time}', time);
  String get fleetIntelPartialData => _t('fleetIntelPartialData');
  String fleetIntelAnalyzedVehicles(int analyzed, int total) =>
      _t('fleetIntelAnalyzedVehicles')
          .replaceAll('{analyzed}', '$analyzed')
          .replaceAll('{total}', '$total');
  String fleetIntelLimitedToVehicles(int cap) =>
      _t('fleetIntelLimitedToVehicles').replaceAll('{cap}', '$cap');

  String get fleetAttentionTitle => _t('fleetAttentionTitle');
  String get fleetAttentionNone => _t('fleetAttentionNone');
  String get fleetAttentionHighRisk => _t('fleetAttentionHighRisk');
  String get fleetAttentionLowScore => _t('fleetAttentionLowScore');
  String get fleetAttentionManyOverspeed => _t('fleetAttentionManyOverspeed');
  String get fleetAttentionManyStops => _t('fleetAttentionManyStops');
  String get fleetAttentionInactive => _t('fleetAttentionInactive');
  String get fleetAttentionInsufficientData =>
      _t('fleetAttentionInsufficientData');
  String get fleetAttentionOpenVehicle => _t('fleetAttentionOpenVehicle');
  String get fleetAttentionDetailsTitle => _t('fleetAttentionDetailsTitle');
  String get fleetAttentionScore => _t('fleetAttentionScore');
  String get fleetAttentionReasons => _t('fleetAttentionReasons');
  String get fleetAttentionTrips => _t('fleetAttentionTrips');
  String get fleetAttentionDistance => _t('fleetAttentionDistance');
  String get fleetAttentionOverspeed => _t('fleetAttentionOverspeed');
  String get fleetAttentionStops => _t('fleetAttentionStops');
  String get fleetAttentionOpenMap => _t('fleetAttentionOpenMap');
  String get fleetAttentionOpenTrips => _t('fleetAttentionOpenTrips');
  String get fleetAttentionNoScore => _t('fleetAttentionNoScore');

  // ── Trip behavior score details (Phase 9C) ─────────────────────────────────
  String get driverScoreDetailsTitle => _t('driverScoreDetailsTitle');
  String get driverScoreTripScoredYes => _t('driverScoreTripScoredYes');
  String get driverScoreTripScoredNo => _t('driverScoreTripScoredNo');
  String driverScoreFinalScore(String value) =>
      _t('driverScoreFinalScore').replaceAll('{value}', value);

  String get driverScoreSpeedPenalty => _t('driverScoreSpeedPenalty');
  String get driverScoreStopPenalty => _t('driverScoreStopPenalty');
  String get driverScoreIgnitionPenalty => _t('driverScoreIgnitionPenalty');
  String get driverScoreEfficiencyPenalty => _t('driverScoreEfficiencyPenalty');
  String get driverScoreFactorsTitle => _t('driverScoreFactorsTitle');
  String get driverScoreReasonOverspeed => _t('driverScoreReasonOverspeed');
  String get driverScoreReasonHeavyOverspeed =>
      _t('driverScoreReasonHeavyOverspeed');
  String get driverScoreReasonLongStops => _t('driverScoreReasonLongStops');
  String get driverScoreReasonExcessiveStops =>
      _t('driverScoreReasonExcessiveStops');
  String get driverScoreReasonIgnitionTransitions =>
      _t('driverScoreReasonIgnitionTransitions');
  String get driverScoreReasonLowEfficiency =>
      _t('driverScoreReasonLowEfficiency');
  String get driverScoreReasonCleanTrip => _t('driverScoreReasonCleanTrip');
  String get driverScoreReasonShortTrip => _t('driverScoreReasonShortTrip');
  String get driverScoreReliableEnough => _t('driverScoreReliableEnough');
  String get driverScoreNotReliableEnough => _t('driverScoreNotReliableEnough');
  String get driverScoreSteadyDriving => _t('driverScoreSteadyDriving');
  String get driverScoreSeverityLow => _t('driverScoreSeverityLow');
  String get driverScoreSeverityMedium => _t('driverScoreSeverityMedium');
  String get driverScoreSeverityHigh => _t('driverScoreSeverityHigh');
  String get driverScoreFactorOther => _t('driverScoreFactorOther');

  String driverScoreBaseScore(String value) =>
      _t('driverScoreBaseScore').replaceAll('{value}', value);
  String driverScoreTotalPenalty(String value) =>
      _t('driverScoreTotalPenalty').replaceAll('{value}', value);
  String driverScorePenaltyLine(String name, String points) =>
      _t('driverScorePenaltyLine')
          .replaceAll('{name}', name)
          .replaceAll('{points}', points);
  String driverScoreFactorOccurrences(int n) =>
      _t('driverScoreFactorOccurrences').replaceAll('{n}', '$n');

  String get routeEventDetailsTitle => _t('routeEventDetailsTitle');
  String get routeEventDetailsStop => _t('routeEventDetailsStop');
  String get routeEventDetailsOverspeed => _t('routeEventDetailsOverspeed');
  String get routeEventDetailsIgnitionOn => _t('routeEventDetailsIgnitionOn');
  String get routeEventDetailsIgnitionOff => _t('routeEventDetailsIgnitionOff');
  String get routeEventDetailsStartTime => _t('routeEventDetailsStartTime');
  String get routeEventDetailsEndTime => _t('routeEventDetailsEndTime');
  String get routeEventDetailsDuration => _t('routeEventDetailsDuration');
  String get routeEventDetailsTime => _t('routeEventDetailsTime');
  String get routeEventDetailsMaxSpeed => _t('routeEventDetailsMaxSpeed');
  String get routeEventDetailsLocation => _t('routeEventDetailsLocation');
  String get routeEventDetailsRecenter => _t('routeEventDetailsRecenter');

  // ── Replay ─────────────────────────────────────────────────────────────────
  String get replayRoute              => _t('replayRoute');
  String get replayPlay               => _t('replayPlay');
  String get replayPause              => _t('replayPause');
  String get replayRestart            => _t('replayRestart');
  String get replaySpeed              => _t('replaySpeed');
  String get replaySpeedShort         => _t('replaySpeedShort');
  String get replayCurrentPoint       => _t('replayCurrentPoint');
  String get replayCompletedChip      => _t('replayCompletedChip');
  String get replayMoreActions        => _t('replayMoreActions');
  String get replayCurrentSpeed       => _t('replayCurrentSpeed');
  String get replayCurrentTime        => _t('replayCurrentTime');
  String get replayRecenter           => _t('replayRecenter');
  String get replayVehicleHidden      => _t('replayVehicleHidden');
  String get replayVehicleNoData      => _t('replayVehicleNoData');
  String get replayVehicleActive      => _t('replayVehicleActive');
  String get replayPlaying            => _t('replayPlaying');
  String get replayPaused             => _t('replayPaused');
  String get replayShowLabels         => _t('replayShowLabels');
  String get replayHideLabels         => _t('replayHideLabels');
  String get replayMapLegend          => _t('replayMapLegend');
  String replayPointsCount(int count) =>
      _t('replayPointsCount').replaceAll('{count}', '$count');
  String get replayProgress           => _t('replayProgress');
  String get loadingReplay            => _t('loadingReplay');
  String get errorLoadingReplay       => _t('errorLoadingReplay');
  String get notEnoughDataForReplay   => _t('notEnoughDataForReplay');
  String get routeCompleted           => _t('routeCompleted');
  String get viewReplay               => _t('viewReplay');
  String get replayMissingGpsData     => _t('replayMissingGpsData');
  String get replayMissingData        => _t('replayMissingData');
  String replayGapsDetected(int count) =>
      _t('replayGapsDetected').replaceAll('{count}', '$count');
  String get replayGapStartLabel      => _t('replayGapStartLabel');
  String get replayGapEndLabel        => _t('replayGapEndLabel');
  String get replayGapDurationLabel   => _t('replayGapDurationLabel');
  String get replayGapsSheetTitle     => _t('replayGapsSheetTitle');
  String get replaySnapshotTitle      => _t('replaySnapshotTitle');
  String get replaySnapshotTime       => _t('replaySnapshotTime');
  String get replaySnapshotSpeed      => _t('replaySnapshotSpeed');
  String get replaySnapshotAddress    => _t('replaySnapshotAddress');
  String get replaySnapshotCoordinates => _t('replaySnapshotCoordinates');
  String get replaySnapshotDirection  => _t('replaySnapshotDirection');
  String get replaySnapshotIgnition   => _t('replaySnapshotIgnition');
  String get replaySnapshotEngineOn   => _t('replaySnapshotEngineOn');
  String get replaySnapshotEngineOff  => _t('replaySnapshotEngineOff');
  String get replaySnapshotDetails    => _t('replaySnapshotDetails');
  String get replaySensorsTitle       => _t('replaySensorsTitle');
  String get replaySensorFuel         => _t('replaySensorFuel');
  String get replaySensorBattery      => _t('replaySensorBattery');
  String get replaySensorGsm          => _t('replaySensorGsm');
  String get replaySensorSatellites   => _t('replaySensorSatellites');
  String get replaySensorAccuracy     => _t('replaySensorAccuracy');
  String get replaySensorDriver       => _t('replaySensorDriver');
  String get replaySensorUnavailable  => _t('replaySensorUnavailable');
  String get replayAfterDataGap       => _t('replayAfterDataGap');
  String get routeEventFilterDataGaps => _t('routeEventFilterDataGaps');
  String get routeTimelineStart       => _t('routeTimelineStart');
  String get routeTimelineEnd         => _t('routeTimelineEnd');
  String replayTimelineSummaryStops(int count) =>
      _t('replayTimelineSummaryStops').replaceAll('{count}', '$count');
  String replayTimelineSummaryOverspeed(int count) =>
      _t('replayTimelineSummaryOverspeed').replaceAll('{count}', '$count');
  String replayTimelineSummaryDataGaps(int count) =>
      _t('replayTimelineSummaryDataGaps').replaceAll('{count}', '$count');
  String replayTimelineSummaryIgnition(int count) =>
      _t('replayTimelineSummaryIgnition').replaceAll('{count}', '$count');
  String get routeEventFilterAlerts => _t('routeEventFilterAlerts');
  String get replayExternalEvent => _t('replayExternalEvent');
  String get replayExternalAlert => _t('replayExternalAlert');
  String get replayExternalMaintenance => _t('replayExternalMaintenance');
  String get replayNoAlertsInPeriod => _t('replayNoAlertsInPeriod');
  String get replayEventDetailsType => _t('replayEventDetailsType');
  String get replayEventDetailsDescription => _t('replayEventDetailsDescription');
  String get replayExternalPositionUnavailable =>
      _t('replayExternalPositionUnavailable');
  String get replayStepPrevious => _t('replayStepPrevious');
  String get replayStepNext => _t('replayStepNext');

  // ── Speed Chart ────────────────────────────────────────────────────────────
  String get speedChartTitle          => _t('speedChartTitle');
  String get speedChartMax            => _t('speedChartMax');
  String get speedChartAvg            => _t('speedChartAvg');
  String get speedChartGpsPoints      => _t('speedChartGpsPoints');
  String get noSpeedData              => _t('noSpeedData');
  String get viewSpeedChart           => _t('viewSpeedChart');

  // ── Geofences ─────────────────────────────────────────────────────────────
  String get geofencesTitle => _t('geofencesTitle');
  String get geofencesAdd => _t('geofencesAdd');
  String get geofenceEdit => _t('geofenceEdit');
  String get geofenceDelete => _t('geofenceDelete');
  String get geofenceNameLabel => _t('geofenceNameLabel');
  String get geofenceTypeLabel => _t('geofenceTypeLabel');
  String get geofenceTypeCircle => _t('geofenceTypeCircle');
  String get geofenceTypePolygon => _t('geofenceTypePolygon');
  String get geofenceRadius => _t('geofenceRadius');
  String get geofenceLinkedVehicles => _t('geofenceLinkedVehicles');
  String get geofenceAlertSectionTitle => _t('geofenceAlertSectionTitle');
  String get geofenceZoneEntry => _t('geofenceZoneEntry');
  String get geofenceZoneExit => _t('geofenceZoneExit');
  String get geofenceShowOnMap => _t('geofenceShowOnMap');
  String get geofenceTapMapCenter => _t('geofenceTapMapCenter');
  String get geofencePolygonMinPoints => _t('geofencePolygonMinPoints');
  String get geofenceCreated => _t('geofenceCreated');
  String get geofenceUpdated => _t('geofenceUpdated');
  String get geofenceDeleted => _t('geofenceDeleted');
  String get geofenceLoadError => _t('geofenceLoadError');
  String get geofenceAlertStatusOn => _t('geofenceAlertStatusOn');
  String get geofenceAlertStatusOff => _t('geofenceAlertStatusOff');
  String get geofenceSearchHint => _t('geofenceSearchHint');
  String get geofenceFilterAllTypes => _t('geofenceFilterAllTypes');
  String get geofenceDeleteTitle => _t('geofenceDeleteTitle');
  String get geofenceDeleteMessage => _t('geofenceDeleteMessage');
  String geofenceDeleteWarningWithVehicles(int n) =>
      _t('geofenceDeleteWarningWithVehicles').replaceAll('{n}', '$n');
  String get geofencesEmptyTitle => _t('geofencesEmptyTitle');
  String get geofencesEmptyMessage => _t('geofencesEmptyMessage');
  String get geofenceColorLabel => _t('geofenceColorLabel');
  String get geofenceTapMapCenterHint => _t('geofenceTapMapCenterHint');
  String get geofencePolygonTapHint => _t('geofencePolygonTapHint');
  String get geofencePolygonUndoLast => _t('geofencePolygonUndoLast');
  String get geofenceNotifyEnter => _t('geofenceNotifyEnter');
  String get geofenceNotifyExit => _t('geofenceNotifyExit');
  String get geofenceNotifyBoth => _t('geofenceNotifyBoth');
  String get geofenceNoVehiclesLinked => _t('geofenceNoVehiclesLinked');
  String geofenceVehiclesSelectedCount(int n) =>
      _t('geofenceVehiclesSelectedCount').replaceAll('{n}', '$n');
  String get geofenceVehiclesClear => _t('geofenceVehiclesClear');
  String get geofenceDetailsTitle => _t('geofenceDetailsTitle');
  String get geofenceNotFound => _t('geofenceNotFound');

  // ── الأسطيل — السائقون والصيانة (مرحلة ٥) ─────────────────────────────────────
  String get driversTitle => _t('driversTitle');
  String get driversAdd => _t('driversAdd');
  String get driversEdit => _t('driversEdit');
  String get driversDelete => _t('driversDelete');
  String get driversSearchHint => _t('driversSearchHint');
  String get driversEmptyTitle => _t('driversEmptyTitle');
  String get driversEmptyMessage => _t('driversEmptyMessage');
  String get driverDetailTitle => _t('driverDetailTitle');
  String get driverNameLabel => _t('driverNameLabel');
  String get driverCodeLabel => _t('driverCodeLabel');
  String get driverPhoneLabel => _t('driverPhoneLabel');
  String get drivingLicenseLabel => _t('drivingLicenseLabel');
  String get licenseExpiryLabel => _t('licenseExpiryLabel');
  String get driversLinkedVehicles => _t('driversLinkedVehicles');
  String get driverNotesLabel => _t('driverNotesLabel');
  String get driversSave => _t('driversSave');
  String get driversDeleteConfirmTitle => _t('driversDeleteConfirmTitle');
  String get driversDeleteConfirmBody => _t('driversDeleteConfirmBody');
  String get driversLoadError => _t('driversLoadError');
  String get driversSelectVehiclesHint => _t('driversSelectVehiclesHint');

  String get licenseStatusUnknown => _t('licenseStatusUnknown');
  String get licenseStatusValid => _t('licenseStatusValid');
  String get licenseStatusSoon => _t('licenseStatusSoon');
  String get licenseStatusExpired => _t('licenseStatusExpired');

  String get maintenanceTitle => _t('maintenanceTitle');
  String get maintenanceAdd => _t('maintenanceAdd');
  String get maintenanceEdit => _t('maintenanceEdit');
  String get maintenanceDelete => _t('maintenanceDelete');
  String get maintenanceDetailTitle => _t('maintenanceDetailTitle');
  String get maintenanceSearchHint => _t('maintenanceSearchHint');
  String get maintenanceFilterAll => _t('maintenanceFilterAll');
  String get maintenanceFilterVehicle => _t('maintenanceFilterVehicle');
  String get maintenanceLoadError => _t('maintenanceLoadError');
  String get maintenanceEmptyTitle => _t('maintenanceEmptyTitle');
  String get maintenanceEmptyMessage => _t('maintenanceEmptyMessage');
  String get maintenanceTypeLabelField => _t('maintenanceTypeLabelField');
  String get maintenanceDueDateLabel => _t('maintenanceDueDateLabel');
  String get maintenanceDueOdometerLabel => _t('maintenanceDueOdometerLabel');
  String get maintenanceMarkCompletedHint => _t('maintenanceMarkCompletedHint');
  String get maintenanceDeleteConfirmTitle =>
      _t('maintenanceDeleteConfirmTitle');
  String get maintenanceDeleteConfirmBody =>
      _t('maintenanceDeleteConfirmBody');

  String get maintStatusUnknown => _t('maintStatusUnknown');
  String get maintStatusCompleted => _t('maintStatusCompleted');
  String get maintStatusUpcoming => _t('maintStatusUpcoming');
  String get maintStatusSoon => _t('maintStatusSoon');
  String get maintStatusOverdue => _t('maintStatusOverdue');

  String maintenanceTypeLocalized(String code) {
    final clean =
        code.trim().isEmpty ? 'other' : code.trim();
    final key = 'maintType_$clean';
    final loc = _strings[locale.languageCode]?[key];
    if (loc != null) return loc;
    final en = _strings['en']?[key];
    if (en != null) return en;
    return clean.replaceAll('_', ' ');
  }

  String get fleetCardNoDriver => _t('fleetCardNoDriver');
  String fleetCardDriverAssigned(String name) =>
      _t('fleetCardDriverAssigned').replaceAll('{name}', name);
  String get fleetCardNoMaintenance => _t('fleetCardNoMaintenance');
  String fleetCardMaintenanceSnippet(String snippet) =>
      _t('fleetCardMaintenanceSnippet').replaceAll('{snippet}', snippet);
  String fleetCardSummaryStoppedFor(String duration) =>
      _t('fleetCardSummaryStoppedFor').replaceAll('{duration}', duration);
  String fleetCardSummaryIdleFor(String duration) =>
      _t('fleetCardSummaryIdleFor').replaceAll('{duration}', duration);
  String fleetCardSummaryEngineOffFor(String duration) =>
      _t('fleetCardSummaryEngineOffFor').replaceAll('{duration}', duration);
  String fleetCardLastMovement(String time) =>
      _t('fleetCardLastMovement').replaceAll('{time}', time);
  String fleetCardLastIgnition(String time) =>
      _t('fleetCardLastIgnition').replaceAll('{time}', time);
  String fleetCardEngineOffSince(String duration) =>
      _t('fleetCardEngineOffSince').replaceAll('{duration}', duration);
  String fleetCardLastPosition(String address) =>
      _t('fleetCardLastPosition').replaceAll('{address}', address);
  String fleetCardLastData(String time) =>
      _t('fleetCardLastData').replaceAll('{time}', time);
  String get fleetCardAlertNoRecentData => _t('fleetCardAlertNoRecentData');
  String fleetCardAlertOfflineLong(String duration) =>
      _t('fleetCardAlertOfflineLong').replaceAll('{duration}', duration);
  String fleetCardAlertOfflineSince(String time) =>
      _t('fleetCardAlertOfflineSince').replaceAll('{time}', time);
  String fleetCardAlertStaleData(String time) =>
      _t('fleetCardAlertStaleData').replaceAll('{time}', time);
  String fleetCardAlertLowBattery(String voltage) =>
      _t('fleetCardAlertLowBattery').replaceAll('{voltage}', voltage);
  String fleetCardAlertBatteryAttention(String voltage) =>
      _t('fleetCardAlertBatteryAttention').replaceAll('{voltage}', voltage);
  String fleetCardAlertLowFuel(String level) =>
      _t('fleetCardAlertLowFuel').replaceAll('{level}', level);
  String get relativeJustNow => _t('relativeJustNow');
  String relativeMinutesAgo(int n) =>
      _t('relativeMinutesAgo').replaceAll('{n}', '$n');
  String relativeHoursAgo(int n) =>
      _t('relativeHoursAgo').replaceAll('{n}', '$n');
  String relativeDaysAgo(int n) =>
      _t('relativeDaysAgo').replaceAll('{n}', '$n');
  String relativeYesterdayAt(String time) =>
      _t('relativeYesterdayAt').replaceAll('{time}', time);
  String relativeDateAt(String date, String time) => _t('relativeDateAt')
      .replaceAll('{date}', date)
      .replaceAll('{time}', time);
  String get fleetStatsLastSyncNow => _t('fleetStatsLastSyncNow');

  String get fleetSectionDocuments => _t('fleetSectionDocuments');
  String get fleetDocInsuranceLabel => _t('fleetDocInsuranceLabel');
  String get fleetDocInspectionLabel => _t('fleetDocInspectionLabel');

  String get fleetAlertMaintSoonTitle => _t('fleetAlertMaintSoonTitle');
  String fleetAlertMaintSoonDesc(String vehicle, String task) =>
      _t('fleetAlertMaintSoonDesc')
          .replaceAll('{vehicle}', vehicle)
          .replaceAll('{task}', task);
  String get fleetAlertMaintOverdueTitle =>
      _t('fleetAlertMaintOverdueTitle');
  String fleetAlertMaintOverdueDesc(String vehicle, String task) =>
      _t('fleetAlertMaintOverdueDesc')
          .replaceAll('{vehicle}', vehicle)
          .replaceAll('{task}', task);
  String get fleetAlertInsuranceSoonTitle =>
      _t('fleetAlertInsuranceSoonTitle');
  String fleetAlertInsuranceSoonDesc(String vehicle) =>
      _t('fleetAlertInsuranceSoonDesc').replaceAll('{vehicle}', vehicle);
  String get fleetAlertInsuranceExpiredTitle =>
      _t('fleetAlertInsuranceExpiredTitle');
  String fleetAlertInsuranceExpiredDesc(String vehicle) =>
      _t('fleetAlertInsuranceExpiredDesc').replaceAll('{vehicle}', vehicle);
  String get fleetAlertTechSoonTitle => _t('fleetAlertTechSoonTitle');
  String fleetAlertTechSoonDesc(String vehicle) =>
      _t('fleetAlertTechSoonDesc').replaceAll('{vehicle}', vehicle);
  String get fleetAlertTechExpiredTitle => _t('fleetAlertTechExpiredTitle');
  String fleetAlertTechExpiredDesc(String vehicle) =>
      _t('fleetAlertTechExpiredDesc').replaceAll('{vehicle}', vehicle);
  String get fleetAlertLicenseSoonTitle => _t('fleetAlertLicenseSoonTitle');
  String fleetAlertLicenseSoonDesc(String name) =>
      _t('fleetAlertLicenseSoonDesc').replaceAll('{name}', name);
  String get fleetAlertLicenseExpiredTitle =>
      _t('fleetAlertLicenseExpiredTitle');
  String fleetAlertLicenseExpiredDesc(String name) =>
      _t('fleetAlertLicenseExpiredDesc').replaceAll('{name}', name);

  String get reportFleetMaintenanceSoon => _t('reportFleetMaintenanceSoon');
  String get reportFleetDriversSoon => _t('reportFleetDriversSoon');

  String get validationRequired => _t('validationRequired');

  /// Localised label for report / alert rows; [fallback] is usually French CSV from server.
  String reportEventTypeDisplay(String type, String fallback) => switch (type) {
        'geofenceEnter' => _t('geofenceZoneEntry'),
        'geofenceExit' => _t('geofenceZoneExit'),
        _ => fallback,
      };

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

  // ── Fleet Intelligence / Admin Dashboard (Phase 6) ────────────────────────
  String get fleetIntelligenceTitle => _t('fleetIntelligenceTitle');
  String get fleetIntelligenceDashboardSubtitle =>
      _t('fleetIntelligenceDashboardSubtitle');
  String get vehiclesOnline => _t('vehiclesOnline');
  String get kpiDriversTotal => _t('kpiDriversTotal');
  String get kpiDriversActive => _t('kpiDriversActive');
  String get maintenanceOverdueVehicles => _t('maintenanceOverdueVehicles');
  String get insufficientData => _t('insufficientData');
  String get companyManagement => _t('companyManagement');
  String get distributors => _t('distributors');
  String get companyManagementHint => _t('companyManagementHint');
  String get utilizationScore => _t('utilizationScore');
  String get mostActiveVehicles => _t('mostActiveVehicles');
  String get leastActiveVehicles => _t('leastActiveVehicles');
  String get driversToWatch => _t('driversToWatch');
  String get vehicleActivitySection => _t('vehicleActivitySection');
  String get driverRankingSection => _t('driverRankingSection');
  String get maintenanceOverviewSection => _t('maintenanceOverviewSection');
  String get alertsOverviewSection => _t('alertsOverviewSection');
  String get vehicleUtilizationSection => _t('vehicleUtilizationSection');
  String get maintenanceUpcomingCount => _t('maintenanceUpcomingCount');
  String get maintenanceSoonCount => _t('maintenanceSoonCount');
  String get maintenanceOverdueCount => _t('maintenanceOverdueCount');
  String get nextMaintenances => _t('nextMaintenances');
  String get alertsTotalPeriod => _t('alertsTotalPeriod');
  String get alertsOverspeed => _t('alertsOverspeed');
  String get alertsGeofence => _t('alertsGeofence');
  String get alertsOnlineOffline => _t('alertsOnlineOffline');
  String get lastImportantEvents => _t('lastImportantEvents');
  String get periodTotalDistance => _t('periodTotalDistance');
  String get vehiclesActiveInPeriod => _t('vehiclesActiveInPeriod');
  String get fleetIntelLiveStatusHint => _t('fleetIntelLiveStatusHint');
  String get exportDashboardReport => _t('exportDashboardReport');
  String get driverRankEstimatedNote => _t('driverRankEstimatedNote');
  String get notAvailable => _t('notAvailable');
  String get fleetStatusProblem => _t('fleetStatusProblem');
  String get adminDashboardLoadError => _t('adminDashboardLoadError');
  String get adminDashboardTripsPartialError =>
      _t('adminDashboardTripsPartialError');
  String get licenseAttentionTitle => _t('licenseAttentionTitle');

  // ── Admin Dashboard premium copy (Phase 6.3) ───────────────────────────────
  String get dashboardConnectionLive => _t('dashboardConnectionLive');
  String get dashboardConnectionReconnecting =>
      _t('dashboardConnectionReconnecting');
  String get dashboardConnectionOverview => _t('dashboardConnectionOverview');
  String get dashboardConnectionDegraded =>
      _t('dashboardConnectionDegraded');
  String get dashboardConnectionLiveReconnecting =>
      _t('dashboardConnectionLiveReconnecting');
  String get dashboardConnectionOffline =>
      _t('dashboardConnectionOffline');
  String get dashboardConnectionServerUnavailable =>
      _t('dashboardConnectionServerUnavailable');
  String get dashboardConnectionSessionExpired =>
      _t('dashboardConnectionSessionExpired');
  String get dashboardConnectionChecking =>
      _t('dashboardConnectionChecking');
  String get dashboardSyncInProgress => _t('dashboardSyncInProgress');
  String get dashboardDistanceQuietHint => _t('dashboardDistanceQuietHint');
  String get dashboardNoActivityToday => _t('dashboardNoActivityToday');
  String get dashboardNoActivityPeriod => _t('dashboardNoActivityPeriod');
  String get dashboardViewFullFleet => _t('dashboardViewFullFleet');
  String get dashboardNoUrgentMaintenance => _t('dashboardNoUrgentMaintenance');
  String get dashboardNoImportantAlerts => _t('dashboardNoImportantAlerts');
  String get dashboardImportantAlertsLabel =>
      _t('dashboardImportantAlertsLabel');
  String get dashboardVehicleActivityEmpty =>
      _t('dashboardVehicleActivityEmpty');

  String fleetEventTypeLabel(String type) => switch (type) {
        'deviceOverspeed' => _t('fleetEvtOverspeed'),
        'geofenceEnter' => _t('fleetEvtGeofenceIn'),
        'geofenceExit' => _t('fleetEvtGeofenceOut'),
        'deviceOffline' => _t('fleetEvtOffline'),
        'deviceOnline' => _t('fleetEvtOnline'),
        'alarm' => _t('fleetEvtAlarm'),
        'ignitionOn' => _t('fleetEvtIgnitionOn'),
        'ignitionOff' => _t('fleetEvtIgnitionOff'),
        'maintenance' => _t('fleetEvtMaintenance'),
        _ => type,
      };

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
      'aboutFleetTrackingSubtitle':
          'Smart fleet GPS tracking on the ELMOGPS platform.',
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
      'noVehiclesInFilter': 'No vehicles in this filter',
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
      'lastKnownData': 'Last known data',
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
      'cmdConfirmRequired': 'Confirmation required',
      'cmdCriticalAction': 'Critical action',
      'cmdConfirmSendMessage': 'You are about to send',
      'cmdCriticalWarningDefault': 'This action may affect vehicle safety and the driver. Make sure execution is safe.',
      'cmdTypeToConfirm': 'To confirm, type:',
      'cmdExecuteCommand': 'Execute command',
      'cmdDeviceOnline': 'Device online',
      'cmdDeviceOffline': 'Device offline',
      'cmdLastUpdate': 'Last update:',
      'cmdVehicleStopped': 'Stopped',
      'cmdSentSuccess': 'sent successfully.',
      'cmdSentFailed': 'failed',
      'cmdQueuedMessage': 'The command has been queued and will be executed when the device reconnects.',
      'cmdErrorSavedNotFound': 'No saved command found for this device. A technician must configure it first.',
      'cmdErrorUnsupported': 'This command is not supported by this device.',
      'cmdErrorTimeout': 'Connection timed out. Check your connection and try again.',
      'cmdErrorUnauthorized': 'Session expired. Please log in again.',
      'cmdErrorForbidden': 'You do not have permission for this operation.',
      'cmdErrorNoConnection': 'No internet connection. Check your network and try again.',
      'cmdErrorBadRequest': 'The command could not be processed. Check parameters and try again.',
      'cmdErrorServer': 'Server error. Please try again in a moment.',
      'cmdErrorUnexpected': 'An unexpected error occurred. Try again or contact support.',
      'cmdConfirmWord': 'CONFIRM',
      'cmdLoadFailed': 'Failed to load commands',
      'cmdRetry': 'Retry',
      'vehicle': 'Vehicle',
      // Command Logs Screen
      'commandHistory': 'History',
      'commandHistoryEmpty': 'History will appear here after\nsending the first command.',
      'clearHistoryConfirmMessage': 'All command logs will be permanently deleted.',
      'delete': 'Delete',
      'generalInfo': 'General information',
      'command': 'Command',
      'systemType': 'System type',
      'category': 'Category',
      'risk': 'Risk',
      'method': 'Method',
      'date': 'Date',
      'sentBy': 'Sent by',
      'userId': 'User ID',
      'executionContext': 'Execution context',
      'connectionStatus': 'Connection status',
      'online': 'Online',
      'speed': 'Speed',
      'device': 'Device',
      'errorMessage': 'Error message',
      'message': 'Message',
      'technicalData': 'Technical data (Technician/Admin)',
      'technicalReason': 'Technical reason',
      'sentAttributes': 'Sent attributes',
      'rawResponse': 'Raw response',
      'copy': 'Copy',
      'noTechnicalData': 'No technical data available.',
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
      'routeIntelSpeedKmh': '{v} km/h',
      'routeIntelMinutesShort': '{n} min',
      'routeIntelPreviewTitle': 'Route analysis settings',
      'routeIntelPreviewReadOnlyHint':
          'Read-only preview. Values are merged from your account, device, and group where applicable.',
      'routeIntelPreviewLoadingLayers': 'Loading some settings layers…',
      'routeIntelPreviewGroupLoadError':
          'Could not load group defaults; preview may be incomplete.',
      'routeIntelSettingsPreviewSection': 'Route analysis (preview)',
      'routeIntelOverspeedThreshold': 'Overspeed threshold',
      'routeIntelStopEnter': 'Stop enter speed',
      'routeIntelStopExit': 'Stop exit speed',
      'routeIntelMinStopDuration': 'Minimum stop duration',
      'routeIntelDetectStops': 'Detect stops',
      'routeIntelDetectOverspeed': 'Detect overspeed',
      'routeIntelDetectIgnition': 'Detect ignition',
      'routeIntelSourceDevice': 'Device',
      'routeIntelSourceGroup': 'Group',
      'routeIntelSourceUser': 'User',
      'routeIntelSourceLocal': 'Local',
      'routeIntelSourceDefault': 'Default',
      'routeIntelEnabled': 'Enabled',
      'routeIntelDisabled': 'Disabled',
      'routeIntelLocalEditorTitle': 'Edit local thresholds',
      'routeIntelLocalParamsHeading': 'Local parameters',
      'routeIntelSave': 'Save',
      'routeIntelResetLocalPrefsSettings': 'Reset local settings',
      'routeIntelSavedSnack': 'Saved',
      'routeIntelResetSnack': 'Reset',
      'routeIntelInvalidValue': 'Invalid value',
      'routeIntelLocalOnlyCentralWarning':
          'These settings are stored locally on this device. They do not modify the central ELMOGPS configuration.',
      'routeIntelVehicleEditTitle': 'Edit vehicle thresholds',
      'routeIntelVehicleEditSubtitle':
          'Saved to this vehicle’s central configuration on the platform.',
      'routeIntelVehicleEditButton': 'Edit vehicle thresholds',
      'routeIntelVehicleSave': 'Save',
      'routeIntelVehicleReset': 'Reset vehicle thresholds',
      'routeIntelVehicleSaved': 'Vehicle settings saved.',
      'routeIntelVehicleResetDone': 'Vehicle settings reset.',
      'routeIntelVehicleSaveError':
          'Could not save settings. Please try again.',
      'routeIntelVehicleResetError':
          'Could not reset settings. Please try again.',
      'routeIntelVehicleOnlyHint':
          'These settings apply only to this vehicle.',
      'routeIntelVehicleNoPermissionHint':
          'You can view route analysis settings; only eligible roles can change central vehicle configuration.',
      'routeIntelVehicleResetConfirmMessage':
          'Remove only this vehicle’s route analysis overrides on the platform. Fleet, account, and local settings stay unchanged.',
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
      'todaySummaryTitle': "Today's Activity",
      'engineHoursLabel': 'Engine hours',
      'vehicleActionsTitle': 'Actions',
      'technicalInfoTitle': 'Technical Details',
      'noSummaryData': 'No activity data available for today.',
      'noAlertsForVehicle': 'No alerts for this vehicle.',
      'alertsLoadError': 'Could not load alerts.',
      'tripsLoadError': 'Could not load trips.',
      'reportSheetTitle': 'Generate Vehicle Report',
      'selectReportType': 'Report type',
      'selectPeriod': 'Period',
      'startDateLabel': 'Start date',
      'endDateLabel': 'End date',
      'invalidDateRange': 'Start date must be before end date.',
      'generateVehicleReport': 'Generate',
      'replaySheetTitle': 'Replay Vehicle Route',
      'selectReplayPeriod': 'Select period',
      'startReplay': 'Start Replay',
      'replayRangeTooLong': 'Range exceeds 24 hours. Replay may be slow with large data.',
      'noReplayDataForPeriod': 'No route data available for this period.',
      'reportPdfSubjectPrefix': 'ELMOGPS Report',
      'reportPdfTitlePrefix': 'Report',
      'todayRouteLabel': "Today's Route",
      'mapSearchVehicleHint': 'Search vehicle, plate, ID…',
      'filterAlertsMap': 'Alerts',
      'mapEmptyFilteredState': 'No vehicles in this state right now.',
      'mapNoVehiclesEmpty': 'No vehicles to show right now.',
      'liveFollowRunningLabel': 'Following live…',
      'resumeVehicleFollow': 'Resume follow',
      'mapLayersTitle': 'Map layers',
      'mapLayerAlerts': 'Show alerts on map',
      'mapLayerRoutesToday': "Today's route trace",
      'mapTypeNormal': 'Default map',
      'mapTypeSatellite': 'Satellite',
      'mapTypeTerrain': 'Terrain',
      'mapVehicleListTitle': 'Fleet list',
      'uniqueIdShortLabel': 'Device ID',
      'mapLayersButton': 'Layers',
      'filterVehicles': 'Filter vehicles',
      'chooseVehicles': 'Choose vehicles',
      'chooseVehiclesHint': 'Select one or more vehicles to show on the map',
      'showAllVehicles': 'Show all vehicles',
      'showAllVehiclesOnMap': 'Show all vehicles on map',
      'showVehicleOnMap': 'Show vehicle on map',
      'showSelectedVehiclesOnMap': 'Show {count} vehicles on map',
      'clearSelection': 'Clear selection',
      'selectedVehiclesCount': '{count} selected',
      'mapFilterSearchHint': 'Search by name, plate, or ID…',
      'onlineOnlyFilter': 'Online only',
      'movingOnlyFilter': 'Moving only',
      'vehiclesShownCount': '{count} vehicles shown',
      'clearMapFilter': 'Clear filter',
      'noVehiclesMatchFilter': 'No vehicles match this filter.',
      'selectVehiclesTitle': 'Select vehicles',
      'mapFilterActiveLabel': 'Filter active',
      'mapFilterZeroVisible': 'No vehicles visible — adjust filter',
      'selectMultipleVehiclesHint': 'Select one or more vehicles to show on the map',
      'vehiclesSelectedCount': '{count} vehicles selected',
      'matchingVehiclesCount': '{count} matching vehicles',
      'noMatchingVehicles': 'No vehicles match your search',
      'vehicleComparisonTitle': 'Vehicle comparison',
      'compareVehicles': 'Compare vehicles',
      'compareVehiclesCount': 'Compare {count} vehicles',
      'comparedVehiclesCount': '{count} vehicles compared',
      'selectAtLeastTwoVehicles': 'Select at least two vehicles to compare.',
      'todayComparison': 'Today',
      'stopsToday': 'Stops today',
      'maxSpeed': 'Max speed',
      'averageSpeed': 'Average speed',
      'stopDuration': 'Stop duration',
      'lastUpdate': 'Last update',
      'highestDistance': 'Highest distance',
      'highestAlerts': 'Most alerts',
      'highestStopDuration': 'Longest stop time',
      'mostRecentUpdate': 'Most recent update',
      'removeFromComparison': 'Remove from comparison',
      'noComparisonData': 'No comparison data',
      'comparisonLoadFailed': 'Could not load comparison',
      'comparisonLoading': 'Loading comparison…',
      'comparisonLoadingAnalyzing': 'Analyzing selected vehicles…',
      'backToMap': 'Back to map',
      'multiVehicleReplayTitle': 'Multi-vehicle replay',
      'replaySelectedVehicles': 'Replay selected vehicles',
      'replayVehiclesCount': 'Replay {count} vehicles',
      'replayComparedVehicles': 'Replay compared vehicles',
      'selectAtLeastTwoVehiclesReplay':
          'Select at least two vehicles to start replay.',
      'multiReplayLimitMessage': 'Multi-vehicle replay is limited to 5 vehicles.',
      'multiReplayLoading': 'Loading multi-vehicle replay…',
      'multiReplayNoData': 'No route data for the selected vehicles.',
      'multiReplayLoadFailed': 'Could not load replay.',
      'multiReplayAutoFollow': 'Auto-follow',
      'multiReplayActiveVehicle': 'Active vehicle',
      'multiReplayVisibleVehicles': 'Visible vehicles',
      'multiReplayHide': 'Hide',
      'multiReplayShow': 'Show',
      'multiReplayNoVisibleVehicles': 'No visible vehicles',
      'multiReplaySpeedColors': 'Speed colors',
      'multiReplayNoFixAtTime': 'No position at this time',
      'multiReplayComparison': 'Comparison',
      'multiReplaySummary': 'Summary',
      'multiReplayMovingTime': 'Moving time',
      'multiReplayStoppedTime': 'Stopped time',
      'multiReplayInsufficientData': 'Insufficient data',
      'multiReplayHiddenVehicle': 'Hidden vehicle',
      'multiReplayKpiLoadedNote': 'Indicators for all loaded vehicles (approximate GPS distance).',
      'multiReplayDistanceApproxNote':
          'Distance is approximate from GPS points; gaps are excluded.',
      'multiReplayRouteStart': 'Route start',
      'multiReplayRouteEnd': 'Route end',
      'multiReplayInsightLongestStop': 'Longest stop time',
      'multiReplayInsightHighestSpeed': 'Highest speed',
      'multiReplayInsightMostOverspeed': 'Most overspeed events',
      'multiReplayInsightFirstMovement': 'First movement',
      'multiReplayInsightEarliestEnd': 'Earliest route end',
      'routeDataUnavailable': 'No route data',
      'hideVehicle': 'Hide vehicle',
      'showVehicle': 'Show vehicle',
      'replayToday': 'Today',
      'chooseReplayDate': 'Choose date',
      'replayMultiVehicles': 'Multi-vehicle replay',
      'stopsCountLabel': 'Stops',
      'alertsTodayLabel': 'Alerts today',
      'alertsForVehicle': 'Alerts for this vehicle',
      'alertsForVehicleName': 'Alerts for {name}',
      'tripDateFilter': 'Filter trips by date',
      'clearDateFilter': 'Clear date filter',
      'centerFleetTooltip': 'Centre fleet',
      'fleetSummaryBar': '{online}/{total} online · {moving} moving · {idle} idle',
      'locationUnavailable': 'Unavailable',
      'noLivePosition': 'No live position',
      'positionMayBeOutdated': 'Position may be outdated',
      'lastPositionIsOld': 'Last position is old',
      'currentAddress': 'Address',
      'liveTracking': 'Live tracking',
      'liveTrackingActive': 'Live',
      'trackingDataStale': 'Stale data',
      'trackingReconnecting': 'Reconnecting',
      'trackingOffline': 'Offline',
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
      'routeEventsTimelineTitle': 'Trip events',
      'routeEventsNoneDetected': 'No route events detected',
      'routeEventsSeeMore': 'See all events',
      'replaySpeedShort': 'Speed',
      'replayCurrentPoint': 'Current point',
      'replayCompletedChip': 'Completed',
      'replayMoreActions': 'More',
      'routeEventsSeeLess': 'Show less',
      'routeEventFilterAll': 'All',
      'routeEventFilterStops': 'Stops',
      'routeEventFilterOverspeed': 'Overspeed',
      'routeEventFilterIgnition': 'Ignition',
      'routeEventsFilterNoMatches': 'No events in this filter',
      'tripsTitle': 'Trips',
      'tripLabel': 'Trip',
      'tripTitle': 'Trip {n}',
      'tripStart': 'Start',
      'tripEnd': 'End',
      'tripDuration': 'Duration',
      'tripDistance': 'Distance',
      'tripStopsCount': '{n} stops',
      'tripOverspeedCount': '{n} overspeed',
      'tripMaxSpeed': 'Max speed',
      'tripReplay': 'Replay',
      'tripViewOnMap': 'View on map',
      'tripsNoneDetected': 'No trips detected for this period.',
      'tripShort': 'Short trip',
      'tripKm': 'km',
      'tripMin': 'min',
      'tripTimeArrow': '{from} → {to}',
      'tripKmUnit': 'km',
      'tripIgnitionSummary': 'Ignition: {on} on · {off} off',
      'driverScoreLabel': 'Score',
      'driverScoreExcellent': 'Excellent',
      'driverScoreGood': 'Good',
      'driverScoreModerate': 'Moderate',
      'driverScoreHighRisk': 'Needs attention',
      'driverScoreUnknown': 'Unknown',
      'driverScoreNotScorable': 'Not rated',
      'driverScoreTripTooShort': 'Trip too short',
      'dailyScoreTitle': 'Driving score',
      'dailyScorePeriodTitle': 'For this period',
      'dailyScoreNotScorable': 'Not rated',
      'dailyScoreInsufficientData': 'Not enough data to score this period',
      'dailyScoreTripCount': '{n} trips',
      'dailyScoreScorableTrips': '{scored} scored · {total} trips',
      'dailyScoreTotalDistance': '{km} km total',
      'dailyScoreOverspeed': '{n} overspeed',
      'dailyScoreStops': '{n} stops',
      'dailyScoreBestTrip': 'Best trip: {name}',
      'dailyScoreWorstTrip': 'Needs attention: {name}',
      'dailyScoreNoTrips': 'No trips in this period',
      'dailyScoreDetailsTitle': 'Driving score details',
      'dailyScoreEvaluatedTrips': 'Trips evaluated',
      'dailyScoreUnscoredTrips': 'Trips not scored',
      'dailyScoreTotalDuration': 'Total duration',
      'dailyScoreTotalStopDuration': 'Total stop duration',
      'dailyScoreUnscoredExcludedHint':
          'Trips that are not shown as scored here are not included in this period average.',
      'dailyScoreNoEvaluatedTrips': 'No trips were scored for this period.',
      'dailyScoreTapForDetails': 'Tap for details',
      'dailyScoreBestTripLabel': 'Best trip',
      'dailyScoreWorstTripLabel': 'Needs attention',
      'fleetIntelTitle': 'Fleet behavior',
      'fleetIntelSubtitle':
          'Driving quality summary for ELMOGPS fleet (sample window).',
      'fleetIntelScore': 'Fleet score',
      'fleetIntelNotScorable': 'Not rated',
      'fleetIntelInsufficientData': 'Not enough data',
      'fleetIntelVehicles': 'Vehicles',
      'fleetIntelActiveVehicles': 'Active',
      'fleetIntelInactiveVehicles': 'Inactive',
      'fleetIntelTrips': 'Trips',
      'fleetIntelDistance': 'Distance',
      'fleetIntelOverspeed': 'Overspeed',
      'fleetIntelStops': 'Stops',
      'fleetIntelBestVehicle': 'Best vehicle',
      'fleetIntelWorstVehicle': 'Needs attention (lowest score)',
      'fleetIntelMostActiveVehicle': 'Most driven',
      'fleetIntelMostOverspeedVehicle': 'Most overspeed events',
      'fleetIntelMostStoppedVehicle': 'Longest stop time',
      'fleetIntelNeedsAttention': 'Needs follow-up',
      'fleetIntelRiskDistribution': 'Risk mix',
      'fleetIntelNoData': '—',
      'fleetIntelLoading': 'Loading fleet summary…',
      'fleetIntelError': 'Could not load summary. Pull to retry.',
      'fleetIntelToday': 'Today',
      'fleetIntelYesterday': 'Yesterday',
      'fleetIntelLast7Days': 'Last 7 days',
      'fleetIntelNoTripsInPeriod': 'No trips in this window for sampled vehicles.',
      'fleetIntelVehicleFallback': 'Vehicle {id}',
      'fleetIntelDrivingDuration': 'Driving time: {value}',
      'fleetIntelStopDuration': 'Stop time: {value}',
      'fleetIntelSampleNote':
          '{included}/{total} vehicles · up to {cap} loaded per refresh (online-first).',
      'fleetIntelOpenTrackingTooltip': 'Open tracking',
      'fleetIntelDrivingTime': 'Driving time',
      'fleetIntelPartialRoutes':
          'Some fleet routes could not be loaded; metrics may be incomplete.',
      'fleetIntelCustomPeriod': 'Custom',
      'fleetIntelRefresh': 'Refresh',
      'fleetIntelUpdatedAt': 'Updated · {time}',
      'fleetIntelPartialData': 'Some indicators are based on partial fleet data.',
      'fleetIntelAnalyzedVehicles':
          'Loaded routes for {analyzed} of {total} vehicles.',
      'fleetIntelLimitedToVehicles':
          'The platform loads up to {cap} vehicles per analysis to protect performance.',
      'fleetAttentionTitle': 'Vehicles to follow',
      'fleetAttentionNone': 'No vehicles need follow-up for this period.',
      'fleetAttentionHighRisk': 'High risk',
      'fleetAttentionLowScore': 'Low score',
      'fleetAttentionManyOverspeed': 'Many overspeed moments',
      'fleetAttentionManyStops': 'Many or long stops',
      'fleetAttentionInactive': 'Inactive / no trips',
      'fleetAttentionInsufficientData': 'Insufficient data',
      'fleetAttentionOpenVehicle': 'Open vehicle',
      'fleetAttentionDetailsTitle': 'Follow-up',
      'fleetAttentionScore': 'Period score',
      'fleetAttentionReasons': 'Why this vehicle is listed',
      'fleetAttentionTrips': 'Trips',
      'fleetAttentionDistance': 'Distance',
      'fleetAttentionOverspeed': 'Overspeed moments',
      'fleetAttentionStops': 'Stops',
      'fleetAttentionOpenMap': 'Open map',
      'fleetAttentionOpenTrips': 'Open trips',
      'fleetAttentionNoScore': 'No score for this period (not enough reliable trips).',
      'driverScoreDetailsTitle': 'Score details',
      'driverScoreTripScoredYes': 'This trip is scored',
      'driverScoreTripScoredNo': 'This trip is not scored',
      'driverScoreFinalScore': 'Final score: {value}',
      'driverScoreBaseScore': 'Starting score: {value}',
      'driverScoreTotalPenalty': 'Total penalties: {value}',
      'driverScoreSpeedPenalty': 'Speed overshoots',
      'driverScoreStopPenalty': 'Stops & long idle time',
      'driverScoreIgnitionPenalty': 'Ignition changes',
      'driverScoreEfficiencyPenalty': 'Slow overall progress',
      'driverScoreFactorsTitle': 'What influenced this score',
      'driverScoreReasonOverspeed': 'Moments over the speed limit',
      'driverScoreReasonHeavyOverspeed': 'High-speed overshoots',
      'driverScoreReasonLongStops': 'Long stationary periods',
      'driverScoreReasonExcessiveStops': 'Many stops relative to distance',
      'driverScoreReasonIgnitionTransitions': 'Frequent ignition changes',
      'driverScoreReasonLowEfficiency': 'Low average speed with frequent stops',
      'driverScoreReasonCleanTrip': 'No notable issues on this trip',
      'driverScoreReasonShortTrip':
          'Route was too short or brief for a reliable score.',
      'driverScoreReliableEnough':
          'The trip was long enough to produce a meaningful score.',
      'driverScoreNotReliableEnough':
          'A fair score cannot be shown for this trip with the data available.',
      'driverScoreSteadyDriving': 'Steady driving — no noteworthy penalties.',
      'driverScoreSeverityLow': 'Low impact',
      'driverScoreSeverityMedium': 'Medium impact',
      'driverScoreSeverityHigh': 'Strong impact',
      'driverScoreFactorOther': 'Another factor',
      'driverScorePenaltyLine': '{name}: −{points}',
      'driverScoreFactorOccurrences': '×{n}',
      'routeEventDetailsTitle': 'Event details',
      'routeEventDetailsStop': 'Stop',
      'routeEventDetailsOverspeed': 'Overspeed',
      'routeEventDetailsIgnitionOn': 'Ignition on',
      'routeEventDetailsIgnitionOff': 'Ignition off',
      'routeEventDetailsStartTime': 'Start time',
      'routeEventDetailsEndTime': 'End time',
      'routeEventDetailsDuration': 'Duration',
      'routeEventDetailsTime': 'Time',
      'routeEventDetailsMaxSpeed': 'Max speed',
      'routeEventDetailsLocation': 'Location',
      'routeEventDetailsRecenter': 'Recenter on map',
      // Replay
      'replayRoute': 'Replay route',
      'replayPlay': 'Play',
      'replayPause': 'Pause',
      'replayRestart': 'Restart',
      'replaySpeed': 'Playback speed',
      'replayCurrentSpeed': 'Current speed',
      'replayCurrentTime': 'Current time',
      'replayRecenter': 'Re-center',
      'replayVehicleHidden': 'Hidden',
      'replayVehicleNoData': 'No data',
      'replayVehicleActive': 'Active',
      'replayPlaying': 'Playing',
      'replayPaused': 'Paused',
      'replayShowLabels': 'Show labels',
      'replayHideLabels': 'Hide labels',
      'replayMapLegend': 'Vehicles',
      'replayPointsCount': '{count} points',
      'replayProgress': 'Progress',
      'loadingReplay': 'Loading replay…',
      'errorLoadingReplay': 'Error loading replay.',
      'notEnoughDataForReplay': 'Not enough GPS data for replay.',
      'routeCompleted': 'Route completed',
      'viewReplay': 'View replay',
      'replayMissingGpsData': 'Missing GPS data',
      'replayMissingData': 'Missing data',
      'replayGapsDetected': 'Missing data: {count}',
      'replayGapStartLabel': 'Last fix before gap',
      'replayGapEndLabel': 'First fix after gap',
      'replayGapDurationLabel': 'Gap duration',
      'replayGapsSheetTitle': 'GPS data gaps',
      'replaySnapshotTitle': 'Current snapshot',
      'replaySnapshotTime': 'Time',
      'replaySnapshotSpeed': 'Speed',
      'replaySnapshotAddress': 'Address',
      'replaySnapshotCoordinates': 'Coordinates',
      'replaySnapshotDirection': 'Direction',
      'replaySnapshotIgnition': 'Engine',
      'replaySnapshotEngineOn': 'Engine on',
      'replaySnapshotEngineOff': 'Engine off',
      'replaySnapshotDetails': 'Details',
      'replaySensorsTitle': 'Sensors',
      'replaySensorFuel': 'Fuel',
      'replaySensorBattery': 'Battery',
      'replaySensorGsm': 'GSM signal',
      'replaySensorSatellites': 'Satellites',
      'replaySensorAccuracy': 'Accuracy',
      'replaySensorDriver': 'Driver',
      'replaySensorUnavailable': 'Value unavailable',
      'replayAfterDataGap': 'After data interruption',
      'routeEventFilterDataGaps': 'Missing data',
      'routeTimelineStart': 'Start',
      'routeTimelineEnd': 'End',
      'replayTimelineSummaryStops': '{count} stops',
      'replayTimelineSummaryOverspeed': '{count} speed events',
      'replayTimelineSummaryDataGaps': '{count} data gaps',
      'replayTimelineSummaryIgnition': '{count} engine events',
      'routeEventFilterAlerts': 'Alerts',
      'replayExternalEvent': 'Event',
      'replayExternalAlert': 'Alert',
      'replayExternalMaintenance': 'Maintenance',
      'replayNoAlertsInPeriod': 'No alerts in this period',
      'replayEventDetailsType': 'Type',
      'replayEventDetailsDescription': 'Description',
      'replayExternalPositionUnavailable': 'Position unavailable',
      'replayStepPrevious': 'Previous point',
      'replayStepNext': 'Next point',
      // Speed chart
      'speedChartTitle': 'Speed chart',
      'speedChartMax': 'Max speed',
      'speedChartAvg': 'Average speed',
      'speedChartGpsPoints': 'GPS points',
      'noSpeedData': 'No speed data available.',
      'viewSpeedChart': 'View speed chart',
      'geofencesTitle': 'Geofences',
      'geofencesAdd': 'Add zone',
      'geofenceEdit': 'Edit zone',
      'geofenceDelete': 'Delete zone',
      'geofenceNameLabel': 'Zone name',
      'geofenceTypeLabel': 'Zone type',
      'geofenceTypeCircle': 'Circle',
      'geofenceTypePolygon': 'Polygon',
      'geofenceRadius': 'Radius',
      'geofenceLinkedVehicles': 'Associated vehicles',
      'geofenceAlertSectionTitle': 'Entry/exit alerts',
      'geofenceZoneEntry': 'Zone entry',
      'geofenceZoneExit': 'Zone exit',
      'geofenceShowOnMap': 'Show zones',
      'geofenceTapMapCenter': 'Tap on the map to set the center',
      'geofencePolygonMinPoints': 'Add at least 3 points',
      'geofenceCreated': 'Zone created successfully',
      'geofenceUpdated': 'Zone updated',
      'geofenceDeleted': 'Zone deleted',
      'geofenceLoadError': 'Error loading zones',
      'geofenceAlertStatusOn': 'Alerts on',
      'geofenceAlertStatusOff': 'No alerts',
      'geofenceSearchHint': 'Search by name',
      'geofenceFilterAllTypes': 'All types',
      'geofenceDeleteTitle': 'Delete zone',
      'geofenceDeleteMessage': 'This zone will be permanently deleted.',
      'geofenceDeleteWarningWithVehicles':
          'This zone is linked to {n} vehicle(s). It will still be deleted.',
      'geofencesEmptyTitle': 'No zones yet',
      'geofencesEmptyMessage': 'Add a zone to see it on the map and get alerts.',
      'geofenceColorLabel': 'Colour',
      'geofenceTapMapCenterHint': 'Tap on the map to set the center',
      'geofencePolygonTapHint': 'Tap the map to add polygon vertices',
      'geofencePolygonUndoLast': 'Remove last point',
      'geofenceNotifyEnter': 'Create an entry alert',
      'geofenceNotifyExit': 'Create an exit alert',
      'geofenceNotifyBoth': 'Create both',
      'geofenceNoVehiclesLinked': 'No vehicles selected',
      'geofenceVehiclesSelectedCount': '{n} vehicles selected',
      'geofenceVehiclesClear': 'Clear',
      'geofenceDetailsTitle': 'Zone details',
      'geofenceNotFound': 'Zone not found',
      'driversTitle': 'Drivers',
      'driversAdd': 'Add driver',
      'driversEdit': 'Edit driver',
      'driversDelete': 'Delete driver',
      'driversSearchHint': 'Search by name or code',
      'driversEmptyTitle': 'No drivers',
      'driversEmptyMessage': 'Add drivers to assign them to your vehicles.',
      'driverDetailTitle': 'Driver detail',
      'driverNameLabel': 'Driver name',
      'driverCodeLabel': 'Driver code',
      'driverPhoneLabel': 'Phone',
      'drivingLicenseLabel': 'Driving license',
      'licenseExpiryLabel': 'License expiry date',
      'driversLinkedVehicles': 'Associated vehicles',
      'driverNotesLabel': 'Notes',
      'driversSave': 'Save',
      'driversDeleteConfirmTitle': 'Delete driver',
      'driversDeleteConfirmBody': 'This driver will be deleted permanently.',
      'driversLoadError': 'Unable to load drivers',
      'driversSelectVehiclesHint': 'Tap to select fleet vehicles.',
      'licenseStatusUnknown': 'Status unknown',
      'licenseStatusValid': 'License valid',
      'licenseStatusSoon': 'License expiring soon',
      'licenseStatusExpired': 'License expired',
      'maintenanceTitle': 'Maintenance',
      'maintenanceAdd': 'Add maintenance',
      'maintenanceEdit': 'Edit maintenance',
      'maintenanceDelete': 'Delete maintenance',
      'maintenanceDetailTitle': 'Maintenance detail',
      'maintenanceSearchHint': 'Search maintenance',
      'maintenanceFilterAll': 'All vehicles',
      'maintenanceFilterVehicle': 'Filter by vehicle',
      'maintenanceLoadError': 'Unable to load maintenance',
      'maintenanceEmptyTitle': 'No maintenance',
      'maintenanceEmptyMessage': 'Create maintenance items to track due dates.',
      'maintenanceTypeLabelField': 'Maintenance type',
      'maintenanceDueDateLabel': 'Due date',
      'maintenanceDueOdometerLabel': 'Due odometer (km)',
      'maintenanceMarkCompletedHint': 'Mark as completed',
      'maintenanceDeleteConfirmTitle': 'Delete maintenance',
      'maintenanceDeleteConfirmBody': 'Are you sure you want to delete this maintenance record?',
      'maintStatusUnknown': 'Unknown',
      'maintStatusCompleted': 'Completed',
      'maintStatusUpcoming': 'Upcoming',
      'maintStatusSoon': 'Soon due',
      'maintStatusOverdue': 'Overdue',
      'maintType_oil_change': 'Oil change',
      'maintType_oil_filter': 'Oil filter',
      'maintType_air_filter': 'Air filter',
      'maintType_tires': 'Tires',
      'maintType_brakes': 'Brakes',
      'maintType_battery': 'Battery',
      'maintType_draining': 'Flushing',
      'maintType_general_revision': 'General service',
      'maintType_insurance': 'Insurance',
      'maintType_technical_inspection': 'Technical inspection',
      'maintType_vignette': 'Road tax vignette',
      'maintType_other': 'Other',
      'fleetCardNoDriver': 'No driver assigned',
      'fleetCardDriverAssigned': 'Driver {name}',
      'fleetCardNoMaintenance': 'No maintenance',
      'fleetCardMaintenanceSnippet': 'Maintenance • {snippet}',
      'fleetCardSummaryStoppedFor': 'Stopped {duration}',
      'fleetCardSummaryIdleFor': 'Idle {duration}',
      'fleetCardSummaryEngineOffFor': 'Engine off {duration}',
      'fleetCardLastMovement': 'Last movement: {time}',
      'fleetCardLastIgnition': 'Last ignition: {time}',
      'fleetCardEngineOffSince': 'Engine off for {duration}',
      'fleetCardLastPosition': 'Last position: {address}',
      'fleetCardLastData': 'Last data: {time}',
      'fleetCardAlertNoRecentData': 'No recent data',
      'fleetCardAlertOfflineLong': 'Offline for {duration}',
      'fleetCardAlertOfflineSince': 'Offline since {time}',
      'fleetCardAlertStaleData': 'Stale data ({time})',
      'fleetCardAlertLowBattery': 'Low battery ({voltage})',
      'fleetCardAlertBatteryAttention': 'Check battery ({voltage})',
      'fleetCardAlertLowFuel': 'Low fuel ({level})',
      'relativeJustNow': 'Just now',
      'relativeMinutesAgo': '{n} min ago',
      'relativeHoursAgo': '{n} h ago',
      'relativeDaysAgo': '{n} d ago',
      'relativeYesterdayAt': 'Yesterday {time}',
      'relativeDateAt': '{date} {time}',
      'fleetStatsLastSyncNow': 'Last sync: now',
      'fleetSectionDocuments': 'Documents',
      'fleetDocInsuranceLabel': 'Insurance',
      'fleetDocInspectionLabel': 'Technical inspection',
      'fleetAlertMaintSoonTitle': 'Maintenance due soon',
      'fleetAlertMaintSoonDesc': '{vehicle}: {task} is due soon',
      'fleetAlertMaintOverdueTitle': 'Overdue maintenance',
      'fleetAlertMaintOverdueDesc': '{vehicle}: {task} is overdue',
      'fleetAlertInsuranceSoonTitle': 'Insurance expiring soon',
      'fleetAlertInsuranceSoonDesc': '{vehicle}: insurance expiry is approaching',
      'fleetAlertInsuranceExpiredTitle': 'Insurance expired',
      'fleetAlertInsuranceExpiredDesc': '{vehicle}: insurance has expired',
      'fleetAlertTechSoonTitle': 'Technical inspection expires soon',
      'fleetAlertTechSoonDesc': '{vehicle}: technical inspection date is nearing',
      'fleetAlertTechExpiredTitle': 'Technical inspection expired',
      'fleetAlertTechExpiredDesc': '{vehicle}: technical inspection has expired',
      'fleetAlertLicenseSoonTitle': 'Driver license expiring soon',
      'fleetAlertLicenseSoonDesc': '{name}: driving license expiry is nearing',
      'fleetAlertLicenseExpiredTitle': 'Driver license expired',
      'fleetAlertLicenseExpiredDesc': '{name}: driving license has expired',
      'reportFleetMaintenanceSoon': 'Maintenance report — Coming soon',
      'reportFleetDriversSoon': 'Drivers report — Coming soon',
      'fleetIntelligenceTitle': 'Fleet Intelligence',
      'fleetIntelligenceDashboardSubtitle': 'Fleet KPIs and live status',
      'vehiclesOnline': 'Online',
      'kpiDriversTotal': 'Drivers',
      'kpiDriversActive': 'Active drivers',
      'maintenanceOverdueVehicles': 'Vehicles — overdue maintenance',
      'insufficientData': 'Insufficient data',
      'companyManagement': 'Company management',
      'distributors': 'Distributors',
      'companyManagementHint':
          'Company and distributor management will be added in a dedicated phase.',
      'utilizationScore': 'Utilization score',
      'mostActiveVehicles': 'Most active vehicles',
      'leastActiveVehicles': 'Least active / idle',
      'driversToWatch': 'Drivers to watch',
      'vehicleActivitySection': 'Vehicle activity',
      'driverRankingSection': 'Driver ranking',
      'maintenanceOverviewSection': 'Maintenance overview',
      'alertsOverviewSection': 'Alerts overview',
      'vehicleUtilizationSection': 'Vehicle utilization',
      'maintenanceUpcomingCount': 'Upcoming',
      'maintenanceSoonCount': 'Due soon',
      'maintenanceOverdueCount': 'Overdue records',
      'nextMaintenances': 'Next maintenance',
      'alertsTotalPeriod': 'Total (important)',
      'alertsOverspeed': 'Overspeed',
      'alertsGeofence': 'Geofence enter/exit',
      'alertsOnlineOffline': 'Online / offline (events)',
      'lastImportantEvents': 'Recent important events',
      'periodTotalDistance': 'Period distance',
      'vehiclesActiveInPeriod': 'Vehicles with trips',
      'fleetIntelLiveStatusHint':
          'Status (moving / stopped / idle / offline) reflects the live fleet snapshot.',
      'exportDashboardReport': 'Export dashboard report',
      'driverRankEstimatedNote':
          'Ranking is approximate and based on trips/events linked to the driver\'s assigned vehicles.',
      'notAvailable': 'Not available',
      'fleetStatusProblem': 'Needs attention',
      'adminDashboardLoadError': 'Could not load the dashboard.',
      'adminDashboardTripsPartialError':
          'Could not load trips/events for this period. Other sections still use available data.',
      'dashboardConnectionLive': 'Live',
      'dashboardConnectionReconnecting': 'Reconnecting',
      'dashboardConnectionOverview': 'Offline',
      'dashboardConnectionDegraded': 'Connected · Delayed sync',
      'dashboardConnectionLiveReconnecting': 'Reconnecting live…',
      'dashboardConnectionOffline': 'Offline',
      'dashboardConnectionServerUnavailable': 'Server unavailable',
      'dashboardConnectionSessionExpired': 'Session expired',
      'dashboardConnectionChecking': 'Connecting…',
      'dashboardSyncInProgress': 'Syncing…',
      'dashboardDistanceQuietHint':
          'Distance will update as soon as vehicles start moving.',
      'dashboardNoActivityToday': 'No activity detected today.',
      'dashboardNoActivityPeriod': 'No activity in this period.',
      'dashboardViewFullFleet': 'View full fleet',
      'dashboardNoUrgentMaintenance': 'No urgent maintenance.',
      'dashboardNoImportantAlerts': 'No important alerts.',
      'dashboardImportantAlertsLabel': 'Important alerts',
      'dashboardVehicleActivityEmpty': 'No active vehicles in this period.',
      'licenseAttentionTitle': 'License — follow up',
      'fleetEvtOverspeed': 'Overspeed',
      'fleetEvtGeofenceIn': 'Geofence entry',
      'fleetEvtGeofenceOut': 'Geofence exit',
      'fleetEvtOffline': 'Offline',
      'fleetEvtOnline': 'Online',
      'fleetEvtAlarm': 'Alarm',
      'fleetEvtIgnitionOn': 'Ignition on',
      'fleetEvtIgnitionOff': 'Ignition off',
      'fleetEvtMaintenance': 'Maintenance',
      'validationRequired': 'This field is required',
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
      'aboutFleetTrackingSubtitle':
          'تتبُّع أساطيل GPS ذكي عبر منصة ELMOGPS.',
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
      'noVehiclesInFilter': 'لا توجد مركبات في هذا الفلتر',
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
      'lastKnownData': 'آخر بيانات معروفة',
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
      'cmdConfirmRequired': 'التأكيد مطلوب',
      'cmdCriticalAction': 'إجراء حرج',
      'cmdConfirmSendMessage': 'أنت على وشك إرسال',
      'cmdCriticalWarningDefault': 'هذا الإجراء قد يؤثر على سلامة المركبة والسائق. تأكد من أن التنفيذ آمن.',
      'cmdTypeToConfirm': 'للتأكيد، اكتب:',
      'cmdExecuteCommand': 'تنفيذ الأمر',
      'cmdDeviceOnline': 'الجهاز متصل',
      'cmdDeviceOffline': 'الجهاز غير متصل',
      'cmdLastUpdate': 'آخر تحديث:',
      'cmdVehicleStopped': 'متوقف',
      'cmdSentSuccess': 'تم الإرسال بنجاح.',
      'cmdSentFailed': 'فشل',
      'cmdQueuedMessage': 'تم وضع الأمر في قائمة الانتظار وسيتم تنفيذه عند إعادة اتصال الجهاز.',
      'cmdErrorSavedNotFound': 'لم يتم العثور على أمر محفوظ لهذا الجهاز. يجب أن يقوم فني بتكوينه أولاً.',
      'cmdErrorUnsupported': 'هذا الأمر غير مدعوم من هذا الجهاز.',
      'cmdErrorTimeout': 'انتهت مهلة الاتصال. تحقق من اتصالك وحاول مرة أخرى.',
      'cmdErrorUnauthorized': 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
      'cmdErrorForbidden': 'ليس لديك صلاحية لهذه العملية.',
      'cmdErrorNoConnection': 'لا يوجد اتصال بالإنترنت. تحقق من شبكتك وحاول مرة أخرى.',
      'cmdErrorBadRequest': 'تعذر معالجة الأمر. تحقق من المعاملات وحاول مرة أخرى.',
      'cmdErrorServer': 'خطأ في الخادم. يرجى المحاولة بعد قليل.',
      'cmdErrorUnexpected': 'حدث خطأ غير متوقع. حاول مرة أخرى أو اتصل بالدعم.',
      'cmdConfirmWord': 'تأكيد',
      'cmdLoadFailed': 'فشل تحميل الأوامر',
      'cmdRetry': 'إعادة المحاولة',
      'vehicle': 'مركبة',
      // Command Logs Screen
      'commandHistory': 'السجل',
      'commandHistoryEmpty': 'سيظهر السجل هنا بعد\nإرسال أول أمر.',
      'clearHistoryConfirmMessage': 'سيتم حذف جميع سجلات الأوامر نهائياً.',
      'delete': 'حذف',
      'generalInfo': 'معلومات عامة',
      'command': 'الأمر',
      'systemType': 'نوع النظام',
      'category': 'الفئة',
      'risk': 'المخاطر',
      'method': 'الطريقة',
      'date': 'التاريخ',
      'sentBy': 'أرسل بواسطة',
      'userId': 'معرّف المستخدم',
      'executionContext': 'سياق التنفيذ',
      'connectionStatus': 'حالة الاتصال',
      'online': 'متصل',
      'speed': 'السرعة',
      'device': 'الجهاز',
      'errorMessage': 'رسالة الخطأ',
      'message': 'الرسالة',
      'technicalData': 'بيانات تقنية (فني/مدير)',
      'technicalReason': 'السبب التقني',
      'sentAttributes': 'السمات المرسلة',
      'rawResponse': 'الاستجابة الأولية',
      'copy': 'نسخ',
      'noTechnicalData': 'لا توجد بيانات تقنية متاحة.',
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
      'routeIntelSpeedKmh': '{v} كم/س',
      'routeIntelMinutesShort': '{n} د',
      'routeIntelPreviewTitle': 'إعدادات تحليل المسار',
      'routeIntelPreviewReadOnlyHint':
          'معاينة للقراءة فقط. تُدمج القيم من الحساب والجهاز والمجموعة حيث ينطبق.',
      'routeIntelPreviewLoadingLayers': 'جاري تحميل بعض طبقات الإعدادات…',
      'routeIntelPreviewGroupLoadError':
          'تعذّر تحميل إعدادات المجموعة؛ قد تكون المعاينة ناقصة.',
      'routeIntelSettingsPreviewSection': 'تحليل المسار (معاينة)',
      'routeIntelOverspeedThreshold': 'حد تجاوز السرعة',
      'routeIntelStopEnter': 'سرعة دخول التوقف',
      'routeIntelStopExit': 'سرعة خروج التوقف',
      'routeIntelMinStopDuration': 'أقل مدة توقف',
      'routeIntelDetectStops': 'اكتشاف التوقفات',
      'routeIntelDetectOverspeed': 'اكتشاف تجاوز السرعة',
      'routeIntelDetectIgnition': 'اكتشاف الإشعال',
      'routeIntelSourceDevice': 'جهاز',
      'routeIntelSourceGroup': 'مجموعة',
      'routeIntelSourceUser': 'مستخدم',
      'routeIntelSourceLocal': 'محلي',
      'routeIntelSourceDefault': 'افتراضي',
      'routeIntelEnabled': 'مفعّل',
      'routeIntelDisabled': 'معطّل',
      'routeIntelLocalEditorTitle': 'تعديل العتبات المحلية',
      'routeIntelLocalParamsHeading': 'إعدادات محلية',
      'routeIntelSave': 'حفظ',
      'routeIntelResetLocalPrefsSettings': 'إعادة تعيين الإعدادات المحلية',
      'routeIntelSavedSnack': 'تم الحفظ',
      'routeIntelResetSnack': 'تمت إعادة التعيين',
      'routeIntelInvalidValue': 'قيمة غير صالحة',
      'routeIntelLocalOnlyCentralWarning':
          'تُخزَّن هذه الإعدادات محليًا على هذا الجهاز ولا تُعدّل الإعدادات المركزية لـ ELMOGPS.',
      'routeIntelVehicleEditTitle': 'تعديل عتبات المركبة',
      'routeIntelVehicleEditSubtitle':
          'يُحفظ في الإعدادات المركزية لهذه المركبة على المنصة.',
      'routeIntelVehicleEditButton': 'تعديل عتبات المركبة',
      'routeIntelVehicleSave': 'حفظ',
      'routeIntelVehicleReset': 'إعادة ضبط عتبات المركبة',
      'routeIntelVehicleSaved': 'تم حفظ إعدادات المركبة.',
      'routeIntelVehicleResetDone': 'تمت إعادة ضبط إعدادات المركبة.',
      'routeIntelVehicleSaveError': 'تعذر حفظ الإعدادات. حاول مرة أخرى.',
      'routeIntelVehicleResetError':
          'تعذر إعادة ضبط الإعدادات. حاول مرة أخرى.',
      'routeIntelVehicleOnlyHint': 'هذه الإعدادات تطبّق على هذه المركبة فقط.',
      'routeIntelVehicleNoPermissionHint':
          'يمكنك عرض إعدادات تحليل المسار؛ تغيير الإعدادات المركزية للمركبة متاح لأدوار مخوّلة فقط.',
      'routeIntelVehicleResetConfirmMessage':
          'يُزال فقط تجاوز هذه المركبة على المنصة. إعدادات الأسطول والحساب والإعدادات المحلية لا تتغيّر.',
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
      'todaySummaryTitle': 'نشاط اليوم',
      'engineHoursLabel': 'ساعات المحرك',
      'vehicleActionsTitle': 'الإجراءات',
      'technicalInfoTitle': 'التفاصيل التقنية',
      'noSummaryData': 'لا توجد بيانات نشاط لهذا اليوم.',
      'noAlertsForVehicle': 'لا توجد تنبيهات لهذه المركبة.',
      'alertsLoadError': 'تعذّر تحميل التنبيهات.',
      'tripsLoadError': 'تعذّر تحميل الرحلات.',
      'reportSheetTitle': 'إنشاء تقرير المركبة',
      'selectReportType': 'نوع التقرير',
      'selectPeriod': 'الفترة',
      'startDateLabel': 'تاريخ البداية',
      'endDateLabel': 'تاريخ النهاية',
      'invalidDateRange': 'يجب أن يكون تاريخ البداية قبل تاريخ النهاية.',
      'generateVehicleReport': 'إنشاء',
      'replaySheetTitle': 'إعادة تشغيل مسار المركبة',
      'selectReplayPeriod': 'اختر الفترة',
      'startReplay': 'بدء التشغيل',
      'replayRangeTooLong': 'النطاق يتجاوز 24 ساعة. قد يكون التشغيل بطيئاً مع بيانات كبيرة.',
      'noReplayDataForPeriod': 'لا توجد بيانات مسار لهذه الفترة.',
      'reportPdfSubjectPrefix': 'تقرير ELMOGPS',
      'reportPdfTitlePrefix': 'تقرير',
      'todayRouteLabel': 'مسار اليوم',
      'mapSearchVehicleHint': 'بحث: مركبة، لوحة، معرف…',
      'filterAlertsMap': 'إنذار',
      'mapEmptyFilteredState': 'لا توجد مركبات في هذه الحالة حالياً.',
      'mapNoVehiclesEmpty': 'لا توجد مركبات لعرضها حالياً.',
      'liveFollowRunningLabel': 'جاري التتبع المباشر',
      'resumeVehicleFollow': 'العودة للتتبع',
      'mapLayersTitle': 'طبقات الخريطة',
      'mapLayerAlerts': 'عرض التنبيهات على الخريطة',
      'mapLayerRoutesToday': 'مسار اليوم على الخريطة',
      'mapTypeNormal': 'خريطة عادية',
      'mapTypeSatellite': 'قمر صناعي',
      'mapTypeTerrain': 'تضاريس',
      'mapVehicleListTitle': 'قائمة المركبات',
      'uniqueIdShortLabel': 'معرف الجهاز',
      'mapLayersButton': 'طبقات',
      'filterVehicles': 'تصفية المركبات',
      'chooseVehicles': 'اختيار المركبات',
      'chooseVehiclesHint': 'اختر مركبة واحدة أو أكثر لعرضها على الخريطة',
      'showAllVehicles': 'عرض كل المركبات',
      'showAllVehiclesOnMap': 'عرض كل المركبات على الخريطة',
      'showVehicleOnMap': 'عرض المركبة على الخريطة',
      'showSelectedVehiclesOnMap': 'عرض {count} مركبات على الخريطة',
      'clearSelection': 'مسح الاختيار',
      'selectedVehiclesCount': '{count} محددة',
      'mapFilterSearchHint': 'بحث بالاسم أو اللوحة أو المعرّف…',
      'onlineOnlyFilter': 'متصل فقط',
      'movingOnlyFilter': 'متحرك فقط',
      'vehiclesShownCount': '{count} مركبة معروضة',
      'clearMapFilter': 'مسح التصفية',
      'noVehiclesMatchFilter': 'لا توجد مركبات تطابق هذا التصفية.',
      'selectVehiclesTitle': 'اختر المركبات',
      'mapFilterActiveLabel': 'تصفية نشطة',
      'mapFilterZeroVisible': 'لا مركبات ظاهرة — عدّل التصفية',
      'selectMultipleVehiclesHint': 'اختر مركبة واحدة أو أكثر لعرضها على الخريطة',
      'vehiclesSelectedCount': '{count} مركبة محددة',
      'matchingVehiclesCount': '{count} مركبة مطابقة',
      'noMatchingVehicles': 'لا توجد مركبات تطابق بحثك',
      'vehicleComparisonTitle': 'مقارنة المركبات',
      'compareVehicles': 'مقارنة المركبات',
      'compareVehiclesCount': 'مقارنة {count} مركبات',
      'comparedVehiclesCount': '{count} مركبات قيد المقارنة',
      'selectAtLeastTwoVehicles': 'اختر مركبتين على الأقل للمقارنة.',
      'todayComparison': 'اليوم',
      'stopsToday': 'التوقفات اليوم',
      'maxSpeed': 'أقصى سرعة',
      'averageSpeed': 'متوسط السرعة',
      'stopDuration': 'مدة التوقف',
      'lastUpdate': 'آخر تحديث',
      'highestDistance': 'أعلى مسافة',
      'highestAlerts': 'أكثر تنبيهات',
      'highestStopDuration': 'أطول وقت توقف',
      'mostRecentUpdate': 'أحدث تحديث',
      'removeFromComparison': 'إزالة من المقارنة',
      'noComparisonData': 'لا توجد بيانات للمقارنة',
      'comparisonLoadFailed': 'تعذر تحميل المقارنة',
      'comparisonLoading': 'جاري تحميل المقارنة…',
      'comparisonLoadingAnalyzing': 'جاري تحليل المركبات المحددة…',
      'backToMap': 'العودة إلى الخريطة',
      'multiVehicleReplayTitle': 'إعادة تشغيل متعددة',
      'replaySelectedVehicles': 'إعادة تشغيل المركبات المحددة',
      'replayVehiclesCount': 'إعادة تشغيل {count} مركبات',
      'replayComparedVehicles': 'إعادة تشغيل المركبات المقارنة',
      'selectAtLeastTwoVehiclesReplay':
          'حدد مركبتين على الأقل لبدء إعادة التشغيل.',
      'multiReplayLimitMessage': 'إعادة التشغيل المتعددة محدودة بـ 5 مركبات.',
      'multiReplayLoading': 'جاري تحميل إعادة التشغيل المتعددة…',
      'multiReplayNoData': 'لا توجد بيانات مسار للمركبات المحددة.',
      'multiReplayLoadFailed': 'تعذر تحميل إعادة التشغيل.',
      'multiReplayAutoFollow': 'التتبع التلقائي',
      'multiReplayActiveVehicle': 'المركبة النشطة',
      'multiReplayVisibleVehicles': 'المركبات الظاهرة',
      'multiReplayHide': 'إخفاء',
      'multiReplayShow': 'إظهار',
      'multiReplayNoVisibleVehicles': 'لا توجد مركبات ظاهرة',
      'multiReplaySpeedColors': 'ألوان السرعة',
      'multiReplayNoFixAtTime': 'لا موضع في هذا الوقت',
      'multiReplayComparison': 'المقارنة',
      'multiReplaySummary': 'الملخص',
      'multiReplayMovingTime': 'مدة الحركة',
      'multiReplayStoppedTime': 'مدة التوقف',
      'multiReplayInsufficientData': 'بيانات غير كافية',
      'multiReplayHiddenVehicle': 'مركبة مخفية',
      'multiReplayKpiLoadedNote':
          'مؤشرات لكل المركبات المحمّلة (مسافة GPS تقريبية).',
      'multiReplayDistanceApproxNote':
          'المسافة تقريبية من نقاط GPS؛ الفجوات مستبعدة.',
      'multiReplayRouteStart': 'بداية المسار',
      'multiReplayRouteEnd': 'نهاية المسار',
      'multiReplayInsightLongestStop': 'أطول مدة توقف',
      'multiReplayInsightHighestSpeed': 'أعلى سرعة مسجلة',
      'multiReplayInsightMostOverspeed': 'أكثر تجاوزات سرعة',
      'multiReplayInsightFirstMovement': 'أول حركة',
      'multiReplayInsightEarliestEnd': 'أول نهاية مسار',
      'routeDataUnavailable': 'لا توجد بيانات مسار',
      'hideVehicle': 'إخفاء المركبة',
      'showVehicle': 'إظهار المركبة',
      'replayToday': 'اليوم',
      'chooseReplayDate': 'اختر التاريخ',
      'replayMultiVehicles': 'إعادة تشغيل متعددة',
      'stopsCountLabel': 'التوقفات',
      'alertsTodayLabel': 'تنبيهات اليوم',
      'alertsForVehicle': 'تنبيهات هذه المركبة',
      'alertsForVehicleName': 'تنبيهات {name}',
      'tripDateFilter': 'تصفية الرحلات حسب التاريخ',
      'clearDateFilter': 'مسح تصفية التاريخ',
      'centerFleetTooltip': 'توسيط الأسطول',
      'fleetSummaryBar': '{online}/{total} متصل · {moving} متحرك · {idle} خامل',
      'locationUnavailable': 'غير متاح',
      'noLivePosition': 'لا يوجد موقع مباشر',
      'positionMayBeOutdated': 'قد يكون الموقع قديماً',
      'lastPositionIsOld': 'آخر موقع قديم',
      'currentAddress': 'العنوان',
      'liveTracking': 'تتبع مباشر',
      'liveTrackingActive': 'مباشر',
      'trackingDataStale': 'بيانات قديمة',
      'trackingReconnecting': 'إعادة الاتصال',
      'trackingOffline': 'غير متصل',
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
      'routeEventsTimelineTitle': 'أحداث المسار',
      'routeEventsNoneDetected': 'لا توجد أحداث مسار',
      'routeEventsSeeMore': 'عرض كل الأحداث',
      'replaySpeedShort': 'السرعة',
      'replayCurrentPoint': 'النقطة الحالية',
      'replayCompletedChip': 'مكتمل',
      'replayMoreActions': 'المزيد',
      'routeEventsSeeLess': 'عرض أقل',
      'routeEventFilterAll': 'الكل',
      'routeEventFilterStops': 'التوقفات',
      'routeEventFilterOverspeed': 'تجاوز السرعة',
      'routeEventFilterIgnition': 'الإشعال',
      'routeEventsFilterNoMatches': 'لا أحداث في هذا الفلتر',
      'tripsTitle': 'الرحلات',
      'tripLabel': 'رحلة',
      'tripTitle': 'رحلة {n}',
      'tripStart': 'البداية',
      'tripEnd': 'النهاية',
      'tripDuration': 'المدة',
      'tripDistance': 'المسافة',
      'tripStopsCount': '{n} توقف',
      'tripOverspeedCount': '{n} تجاوز سرعة',
      'tripMaxSpeed': 'أقصى سرعة',
      'tripReplay': 'إعادة التشغيل',
      'tripViewOnMap': 'عرض على الخريطة',
      'tripsNoneDetected': 'لم يتم اكتشاف رحلات في هذه الفترة.',
      'tripShort': 'رحلة قصيرة',
      'tripKm': 'كم',
      'tripMin': 'د',
      'tripTimeArrow': '{from} → {to}',
      'tripKmUnit': 'كم',
      'tripIgnitionSummary': 'الإشعال: {on} تشغيل · {off} إطفاء',
      'driverScoreLabel': 'التقييم',
      'driverScoreExcellent': 'ممتاز',
      'driverScoreGood': 'جيد',
      'driverScoreModerate': 'متوسط',
      'driverScoreHighRisk': 'يحتاج متابعة',
      'driverScoreUnknown': 'غير معروف',
      'driverScoreNotScorable': 'غير مقيّم',
      'driverScoreTripTooShort': 'رحلة قصيرة جدًا',
      'dailyScoreTitle': 'تقييم القيادة للفترة',
      'dailyScorePeriodTitle': 'لهذه الفترة',
      'dailyScoreNotScorable': 'غير مقيّم',
      'dailyScoreInsufficientData': 'بيانات غير كافية لتقييم هذه الفترة',
      'dailyScoreTripCount': '{n} رحلة',
      'dailyScoreScorableTrips': '{scored} قابلة للتقييم · {total} رحلات',
      'dailyScoreTotalDistance': 'إجمالي {km} كم',
      'dailyScoreOverspeed': '{n} تجاوز سرعة',
      'dailyScoreStops': '{n} توقف',
      'dailyScoreBestTrip': 'أفضل رحلة: {name}',
      'dailyScoreWorstTrip': 'تتطلب متابعة: {name}',
      'dailyScoreNoTrips': 'لا توجد رحلات في هذه الفترة',
      'dailyScoreDetailsTitle': 'تفاصيل تقييم القيادة',
      'dailyScoreEvaluatedTrips': 'رحلات مُقيَّمة',
      'dailyScoreUnscoredTrips': 'رحلات غير مُقيَّمة',
      'dailyScoreTotalDuration': 'المدة الإجمالية',
      'dailyScoreTotalStopDuration': 'مدة التوقفات الإجمالية',
      'dailyScoreUnscoredExcludedHint':
          'الرحلات غير المعروضة كمقيّمة هنا لا تُحتسب ضمن متوسط هذه الفترة.',
      'dailyScoreNoEvaluatedTrips': 'لم يُقيَّم أي رحلة لهذه الفترة.',
      'dailyScoreTapForDetails': 'اضغط للتفاصيل',
      'dailyScoreBestTripLabel': 'أفضل رحلة',
      'dailyScoreWorstTripLabel': 'رحلة تتطلّب متابعة',
      'fleetIntelTitle': 'سلوك الأسطول',
      'fleetIntelSubtitle': 'ملخص جودة القيادة لأسطول ELMOGPS (نافذة عيّنة).',
      'fleetIntelScore': 'درجة الأسطول',
      'fleetIntelNotScorable': 'غير مقيّمة',
      'fleetIntelInsufficientData': 'البيانات غير كافية',
      'fleetIntelVehicles': 'المركبات',
      'fleetIntelActiveVehicles': 'نشطة',
      'fleetIntelInactiveVehicles': 'غير نشطة',
      'fleetIntelTrips': 'الرحلات',
      'fleetIntelDistance': 'المسافة',
      'fleetIntelOverspeed': 'تجاوز سرعة',
      'fleetIntelStops': 'التوقّفات',
      'fleetIntelBestVehicle': 'أفضل مركبة',
      'fleetIntelWorstVehicle': 'تتطلّب متابعة (أدنى درجة)',
      'fleetIntelMostActiveVehicle': 'الأكثر قيادة',
      'fleetIntelMostOverspeedVehicle': 'أكثر تجاوزات سرعة',
      'fleetIntelMostStoppedVehicle': 'أطول وقت توقّف',
      'fleetIntelNeedsAttention': 'تتطلّب متابعة',
      'fleetIntelRiskDistribution': 'توزيع الخطر',
      'fleetIntelNoData': '—',
      'fleetIntelLoading': 'جاري تحميل ملخص الأسطول…',
      'fleetIntelError': 'تعذّر التحميل. اسحب للتحديث.',
      'fleetIntelToday': 'اليوم',
      'fleetIntelYesterday': 'أمس',
      'fleetIntelLast7Days': 'آخر 7 أيام',
      'fleetIntelNoTripsInPeriod': 'لا رحلات في هذه النافذة للعيّينة.',
      'fleetIntelVehicleFallback': 'مركبة {id}',
      'fleetIntelDrivingDuration': 'زمن القيادة: {value}',
      'fleetIntelStopDuration': 'زمن التوقّف: {value}',
      'fleetIntelSampleNote':
          '{included}/{total} مركبات · يُحمَّل ما يصل إلى {cap} لكل تحديث (الأولوية للمتصل).',
      'fleetIntelOpenTrackingTooltip': 'فتح التتبّع',
      'fleetIntelDrivingTime': 'زمن القيادة',
      'fleetIntelPartialRoutes':
          'تعذّر تحميل بعض مسارات الأسطول؛ قد يكون الملخص غير كامل.',
      'fleetIntelCustomPeriod': 'فترة مخصّصة',
      'fleetIntelRefresh': 'تحديث',
      'fleetIntelUpdatedAt': 'آخر تحديث · {time}',
      'fleetIntelPartialData':
          'بعض المؤشرات مبنية على بيانات جزئية من الأسطول.',
      'fleetIntelAnalyzedVehicles':
          'تُحمَّل مسارات {analyzed} من أصل {total} مركبات.',
      'fleetIntelLimitedToVehicles':
          'المنصّة تحمّل حتى {cap} مركبة لكل تحليل لحماية الأداء.',
      'fleetAttentionTitle': 'مركبات تحتاج متابعة',
      'fleetAttentionNone': 'لا توجد مركبات تحتاج متابعة لهذه الفترة.',
      'fleetAttentionHighRisk': 'خطر مرتفع',
      'fleetAttentionLowScore': 'درجة منخفضة',
      'fleetAttentionManyOverspeed': 'تجاوزات سرعة متكررة',
      'fleetAttentionManyStops': 'توقّفات كثيرة أو طويلة',
      'fleetAttentionInactive': 'غير نشطة / لا رحلات',
      'fleetAttentionInsufficientData': 'بيانات غير كافية',
      'fleetAttentionOpenVehicle': 'فتح المركبة',
      'fleetAttentionDetailsTitle': 'متابعة المركبة',
      'fleetAttentionScore': 'درجة الفترة',
      'fleetAttentionReasons': 'لماذا ظهرت في القائمة',
      'fleetAttentionTrips': 'الرحلات',
      'fleetAttentionDistance': 'المسافة',
      'fleetAttentionOverspeed': 'لحظات تجاوز السرعة',
      'fleetAttentionStops': 'التوقّفات',
      'fleetAttentionOpenMap': 'فتح الخريطة',
      'fleetAttentionOpenTrips': 'فتح الرحلات',
      'fleetAttentionNoScore': 'لا درجة لهذه الفترة (لا رحلات موثوقة للتقييم).',
      'driverScoreDetailsTitle': 'تفاصيل التقييم',
      'driverScoreTripScoredYes': 'تم تقييم هذه الرحلة',
      'driverScoreTripScoredNo': 'لم يُقيَّم هذا المسار',
      'driverScoreFinalScore': 'الدرجة النهائية: {value}',
      'driverScoreBaseScore': 'نقطة الانطلاق: {value}',
      'driverScoreTotalPenalty': 'مجموع الخصومات: {value}',
      'driverScoreSpeedPenalty': 'تجاوزات السرعة',
      'driverScoreStopPenalty': 'التوقف ومدة السكون',
      'driverScoreIgnitionPenalty': 'تغييرات الإشعال',
      'driverScoreEfficiencyPenalty': 'تباطؤ عام في المسار',
      'driverScoreFactorsTitle': 'ما الذي أثر على التقييم',
      'driverScoreReasonOverspeed': 'لحظات تجاوز السرعة المسموحة',
      'driverScoreReasonHeavyOverspeed': 'تجاوزات بسرعات مرتفعة',
      'driverScoreReasonLongStops': 'مدد توقف طويلة نسبيًا',
      'driverScoreReasonExcessiveStops': 'توقفات كثيرة بالنسبة للمسافة',
      'driverScoreReasonIgnitionTransitions': 'تكرار تشغيل وإطفاء الإشعال',
      'driverScoreReasonLowEfficiency': 'متوسط سرعة منخفض مع توقفات متكررة',
      'driverScoreReasonCleanTrip': 'لا توجد ملاحظات بارزة في هذه الرحلة',
      'driverScoreReasonShortTrip': 'المسار قصير أو قصير الزمن لنتيجة موثوقة.',
      'driverScoreReliableEnough': 'الرحلة كانت كافية لإظهار تقييم معنوي.',
      'driverScoreNotReliableEnough':
          'لا يمكن عرض تقييم عادل لهذه الرحلة مع البيانات المتاحة.',
      'driverScoreSteadyDriving': 'قيادة متزنة — دون خصومات ملحوظة.',
      'driverScoreSeverityLow': 'تأثير خفيف',
      'driverScoreSeverityMedium': 'تأثير متوسط',
      'driverScoreSeverityHigh': 'تأثير قوي',
      'driverScoreFactorOther': 'عامل آخر',
      'driverScorePenaltyLine': '{name}: −{points}',
      'driverScoreFactorOccurrences': '×{n}',
      'routeEventDetailsTitle': 'تفاصيل الحدث',
      'routeEventDetailsStop': 'توقف',
      'routeEventDetailsOverspeed': 'سرعة زائدة',
      'routeEventDetailsIgnitionOn': 'المحرك قيد التشغيل',
      'routeEventDetailsIgnitionOff': 'المحرك متوقف',
      'routeEventDetailsStartTime': 'وقت البداية',
      'routeEventDetailsEndTime': 'وقت النهاية',
      'routeEventDetailsDuration': 'المدة',
      'routeEventDetailsTime': 'الوقت',
      'routeEventDetailsMaxSpeed': 'أقصى سرعة',
      'routeEventDetailsLocation': 'الموقع',
      'routeEventDetailsRecenter': 'توسيط الخريطة',
      // Replay
      'replayRoute': 'إعادة تشغيل المسار',
      'replayPlay': 'تشغيل',
      'replayPause': 'إيقاف مؤقت',
      'replayRestart': 'إعادة البدء',
      'replaySpeed': 'سرعة التشغيل',
      'replayCurrentSpeed': 'السرعة الحالية',
      'replayCurrentTime': 'الوقت الحالي',
      'replayRecenter': 'إعادة التمركز',
      'replayVehicleHidden': 'مخفية',
      'replayVehicleNoData': 'لا بيانات',
      'replayVehicleActive': 'نشطة',
      'replayPlaying': 'تشغيل',
      'replayPaused': 'متوقف',
      'replayShowLabels': 'إظهار التسميات',
      'replayHideLabels': 'إخفاء التسميات',
      'replayMapLegend': 'المركبات',
      'replayPointsCount': '{count} نقطة',
      'replayProgress': 'التقدم',
      'loadingReplay': 'جارٍ تحميل إعادة التشغيل…',
      'errorLoadingReplay': 'حدث خطأ أثناء تحميل إعادة التشغيل.',
      'notEnoughDataForReplay': 'بيانات GPS غير كافية لإعادة التشغيل.',
      'routeCompleted': 'انتهى المسار',
      'viewReplay': 'عرض إعادة التشغيل',
      'replayMissingGpsData': 'بيانات GPS ناقصة',
      'replayMissingData': 'بيانات ناقصة',
      'replayGapsDetected': 'بيانات ناقصة: {count}',
      'replayGapStartLabel': 'آخر نقطة قبل الفجوة',
      'replayGapEndLabel': 'أول نقطة بعد الفجوة',
      'replayGapDurationLabel': 'مدة الفجوة',
      'replayGapsSheetTitle': 'فجوات بيانات GPS',
      'replaySnapshotTitle': 'اللقطة الحالية',
      'replaySnapshotTime': 'الوقت',
      'replaySnapshotSpeed': 'السرعة',
      'replaySnapshotAddress': 'العنوان',
      'replaySnapshotCoordinates': 'الإحداثيات',
      'replaySnapshotDirection': 'الاتجاه',
      'replaySnapshotIgnition': 'المحرك',
      'replaySnapshotEngineOn': 'المحرك يعمل',
      'replaySnapshotEngineOff': 'المحرك متوقف',
      'replaySnapshotDetails': 'التفاصيل',
      'replaySensorsTitle': 'الحساسات',
      'replaySensorFuel': 'الوقود',
      'replaySensorBattery': 'البطارية',
      'replaySensorGsm': 'إشارة GSM',
      'replaySensorSatellites': 'الأقمار',
      'replaySensorAccuracy': 'الدقة',
      'replaySensorDriver': 'السائق',
      'replaySensorUnavailable': 'القيمة غير متوفرة',
      'replayAfterDataGap': 'بعد انقطاع البيانات',
      'routeEventFilterDataGaps': 'بيانات ناقصة',
      'routeTimelineStart': 'البداية',
      'routeTimelineEnd': 'النهاية',
      'replayTimelineSummaryStops': '{count} توقف',
      'replayTimelineSummaryOverspeed': '{count} تجاوز سرعة',
      'replayTimelineSummaryDataGaps': '{count} فجوة بيانات',
      'replayTimelineSummaryIgnition': '{count} حدث محرك',
      'routeEventFilterAlerts': 'التنبيهات',
      'replayExternalEvent': 'حدث',
      'replayExternalAlert': 'تنبيه',
      'replayExternalMaintenance': 'صيانة',
      'replayNoAlertsInPeriod': 'لا توجد تنبيهات في هذه الفترة',
      'replayEventDetailsType': 'النوع',
      'replayEventDetailsDescription': 'الوصف',
      'replayExternalPositionUnavailable': 'الموقع غير متوفر',
      'replayStepPrevious': 'النقطة السابقة',
      'replayStepNext': 'النقطة التالية',
      // Speed chart
      'speedChartTitle': 'رسم السرعة',
      'speedChartMax': 'السرعة القصوى',
      'speedChartAvg': 'السرعة المتوسطة',
      'speedChartGpsPoints': 'نقاط GPS',
      'noSpeedData': 'لا توجد بيانات سرعة متاحة.',
      'viewSpeedChart': 'عرض رسم السرعة',
      'geofencesTitle': 'المناطق الجغرافية',
      'geofencesAdd': 'إضافة منطقة',
      'geofenceEdit': 'تعديل المنطقة',
      'geofenceDelete': 'حذف المنطقة',
      'geofenceNameLabel': 'اسم المنطقة',
      'geofenceTypeLabel': 'نوع المنطقة',
      'geofenceTypeCircle': 'دائرة',
      'geofenceTypePolygon': 'مضلع',
      'geofenceRadius': 'نصف القطر',
      'geofenceLinkedVehicles': 'المركبات المرتبطة',
      'geofenceAlertSectionTitle': 'تنبيهات الدخول والخروج',
      'geofenceZoneEntry': 'دخول منطقة',
      'geofenceZoneExit': 'خروج من منطقة',
      'geofenceShowOnMap': 'عرض المناطق',
      'geofenceTapMapCenter': 'اضغط على الخريطة لتحديد المركز',
      'geofencePolygonMinPoints': 'أضف 3 نقاط على الأقل',
      'geofenceCreated': 'تم إنشاء المنطقة بنجاح',
      'geofenceUpdated': 'تم تحديث المنطقة',
      'geofenceDeleted': 'تم حذف المنطقة',
      'geofenceLoadError': 'حدث خطأ أثناء تحميل المناطق',
      'geofenceAlertStatusOn': 'التنبيهات مفعّلة',
      'geofenceAlertStatusOff': 'بدون تنبيهات',
      'geofenceSearchHint': 'ابحث بالاسم',
      'geofenceFilterAllTypes': 'كل الأنواع',
      'geofenceDeleteTitle': 'حذف المنطقة',
      'geofenceDeleteMessage': 'سيتم حذف المنطقة نهائياً.',
      'geofenceDeleteWarningWithVehicles':
          'المنطقة مرتبطة بـ {n} مركبة. سيتم الحذف على أي حال.',
      'geofencesEmptyTitle': 'لا توجد مناطق',
      'geofencesEmptyMessage': 'أضف منطقة لعرضها على الخريطة وتلقي التنبيهات.',
      'geofenceColorLabel': 'اللون',
      'geofenceTapMapCenterHint': 'اضغط على الخريطة لتحديد المركز',
      'geofencePolygonTapHint': 'اضغط على الخريطة لإضافة نقاط المضلع',
      'geofencePolygonUndoLast': 'حذف آخر نقطة',
      'geofenceNotifyEnter': 'إنشاء تنبيه دخول',
      'geofenceNotifyExit': 'إنشاء تنبيه خروج',
      'geofenceNotifyBoth': 'إنشاء الاثنين',
      'geofenceNoVehiclesLinked': 'لم يتم اختيار مركبات',
      'geofenceVehiclesSelectedCount': '{n} مركبة مختارة',
      'geofenceVehiclesClear': 'مسح',
      'geofenceDetailsTitle': 'تفاصيل المنطقة',
      'geofenceNotFound': 'المنطقة غير موجودة',
      'driversTitle': 'السائقون',
      'driversAdd': 'إضافة سائق',
      'driversEdit': 'تعديل السائق',
      'driversDelete': 'حذف السائق',
      'driversSearchHint': 'بحث بالاسم أو الكود',
      'driversEmptyTitle': 'لا يوجد سائقون',
      'driversEmptyMessage': 'يمكنكم إنشاء ملفّات قائمة ومزامنتها بحسب المركبات.',
      'driverDetailTitle': 'تفاصيل السائق',
      'driverNameLabel': 'اسم السائق',
      'driverCodeLabel': 'كود السائق',
      'driverPhoneLabel': 'الهاتف',
      'drivingLicenseLabel': 'رخصة السياقة',
      'licenseExpiryLabel': 'تاريخ انتهاء الرخصة',
      'driversLinkedVehicles': 'المركبات المرتبطة',
      'driverNotesLabel': 'ملاحظات',
      'driversSave': 'حفظ',
      'driversDeleteConfirmTitle': 'حذف السائق',
      'driversDeleteConfirmBody': 'سيجري حذف السائق بشكلٍ قطعي، هل تُؤكّد ذلك؟',
      'driversLoadError': 'تعذّر تنزيل بيانات السائقين',
      'driversSelectVehiclesHint': 'اختر المركبات من أسطولك.',
      'licenseStatusUnknown': 'حالة مجهولة',
      'licenseStatusValid': 'الرخصة صالحة',
      'licenseStatusSoon': 'الرخصة قريبة الانتهاء',
      'licenseStatusExpired': 'الرخصة منتهية',
      'maintenanceTitle': 'الصيانة',
      'maintenanceAdd': 'إضافة صيانة',
      'maintenanceEdit': 'تعديل الصيانة',
      'maintenanceDelete': 'حذف الصيانة',
      'maintenanceDetailTitle': 'تفاصيل الصيانة',
      'maintenanceSearchHint': 'بحث ضمن قائمة الصيانة',
      'maintenanceFilterAll': 'جميع المركبات',
      'maintenanceFilterVehicle': 'انتقاء المركبة',
      'maintenanceLoadError': 'لم يمكن تحميل جدولة الصيانة',
      'maintenanceEmptyTitle': 'لا توجد صيانة',
      'maintenanceEmptyMessage': 'أنشِئ مهامًا تفصيلية وفق المواعيد المقررة.',
      'maintenanceTypeLabelField': 'نوع الصيانة',
      'maintenanceDueDateLabel': 'تاريخ الاستحقاق',
      'maintenanceDueOdometerLabel': 'كيلومترات الاستحقاق',
      'maintenanceMarkCompletedHint': 'وضْع تمّ الإنهاء إن أمكن ذلك',
      'maintenanceDeleteConfirmTitle': 'حذف بطاقة الصيانة',
      'maintenanceDeleteConfirmBody': 'تأكَّد قبل إزالة هذا السجل بصورة قطعية.',
      'maintStatusUnknown': 'حالة مجهولة',
      'maintStatusCompleted': 'مكتملة',
      'maintStatusUpcoming': 'قادمة',
      'maintStatusSoon': 'قريباً',
      'maintStatusOverdue': 'متأخرة',
      'maintType_oil_change': 'تغيير الزيت',
      'maintType_oil_filter': 'فلتر الزيت',
      'maintType_air_filter': 'فلتر الهواء',
      'maintType_tires': 'إطارات',
      'maintType_brakes': 'فرامل',
      'maintType_battery': 'بطارية',
      'maintType_draining': 'تفريغ/تخليل',
      'maintType_general_revision': 'مراجعات عامّة شاملة',
      'maintType_insurance': 'التأمين',
      'maintType_technical_inspection': 'الفحص التقني',
      'maintType_vignette': 'الرمز المروري أو الملصق',
      'maintType_other': 'أنواع أخرى',
      'fleetCardNoDriver': 'لا يوجد سائق مخصّص',
      'fleetCardDriverAssigned': '{name}',
      'fleetCardNoMaintenance': 'لا توجد صيانة',
      'fleetCardMaintenanceSnippet': 'الصيانة • {snippet}',
      'fleetCardSummaryStoppedFor': 'متوقف منذ {duration}',
      'fleetCardSummaryIdleFor': 'خامل منذ {duration}',
      'fleetCardSummaryEngineOffFor': 'المحرك مطفأ منذ {duration}',
      'fleetCardLastMovement': 'آخر حركة: {time}',
      'fleetCardLastIgnition': 'آخر تشغيل: {time}',
      'fleetCardEngineOffSince': 'المحرك مطفأ منذ {duration}',
      'fleetCardLastPosition': 'آخر موقع: {address}',
      'fleetCardLastData': 'آخر بيانات: {time}',
      'fleetCardAlertNoRecentData': 'لا توجد بيانات حديثة',
      'fleetCardAlertOfflineLong': 'غير متصل منذ {duration}',
      'fleetCardAlertOfflineSince': 'غير متصل منذ {time}',
      'fleetCardAlertStaleData': 'بيانات قديمة ({time})',
      'fleetCardAlertLowBattery': 'بطارية منخفضة ({voltage})',
      'fleetCardAlertBatteryAttention': 'تحقق من البطارية ({voltage})',
      'fleetCardAlertLowFuel': 'وقود منخفض ({level})',
      'relativeJustNow': 'الآن',
      'relativeMinutesAgo': 'منذ {n} د',
      'relativeHoursAgo': 'منذ {n} س',
      'relativeDaysAgo': 'منذ {n} ي',
      'relativeYesterdayAt': 'أمس {time}',
      'relativeDateAt': '{date} {time}',
      'fleetStatsLastSyncNow': 'آخر مزامنة: الآن',
      'fleetSectionDocuments': 'وثائق المركبات',
      'fleetDocInsuranceLabel': 'التأمين',
      'fleetDocInspectionLabel': 'الفحص التقني',
      'fleetAlertMaintSoonTitle': 'الصيانة قريبة الاستحقاق',
      'fleetAlertMaintSoonDesc': '{vehicle}: {task} قريبة الوجوب',
      'fleetAlertMaintOverdueTitle': 'الصيانة متأخّرة فعلًا',
      'fleetAlertMaintOverdueDesc': '{vehicle}: تأخّرت {task}',
      'fleetAlertInsuranceSoonTitle': 'التأمين سيُوشكُ على الانتهاء',
      'fleetAlertInsuranceSoonDesc': '{vehicle}: يوشك تأمينها على الانقضاء',
      'fleetAlertInsuranceExpiredTitle': 'التأمين منسوخ',
      'fleetAlertInsuranceExpiredDesc': '{vehicle}: انقطع تأمينها، يجب تجديد الوثائق.',
      'fleetAlertTechSoonTitle': 'تاريخ الفحص الفني يوشك الانتهاء',
      'fleetAlertTechSoonDesc':
          '{vehicle}: يوشك الموعد الزمني لفحصها الفني على الانقضاء',
      'fleetAlertTechExpiredTitle': 'تاريخ الفحص الفني تجاوُز المهلة',
      'fleetAlertTechExpiredDesc': '{vehicle}: تجاوُز زمن الفحص الفني الموعود',
      'fleetAlertLicenseSoonTitle': 'رخصة القيادة ستنتهي قريباً',
      'fleetAlertLicenseSoonDesc': '{name}: تبقَّى على انتهاء رخصته فترة قصيرة',
      'fleetAlertLicenseExpiredTitle': 'رخصة القيادة منتهية السريان',
      'fleetAlertLicenseExpiredDesc':
          '{name}: انتهَت مهلة اعتبار رخصته سارية وفق الآجال',
      'reportFleetMaintenanceSoon': 'إصدار تقرير الصيانة — يُفعَّل لاحقاً',
      'reportFleetDriversSoon': 'تقرير السائقين — يتوفر خلال المرات القادمة',
      'fleetIntelligenceTitle': 'ذكاء الأسطول',
      'fleetIntelligenceDashboardSubtitle': 'مؤشرات الأداء والحالة الفورية',
      'vehiclesOnline': 'متصلة',
      'kpiDriversTotal': 'السائقون',
      'kpiDriversActive': 'سائقون نشطون',
      'maintenanceOverdueVehicles': 'مركبات بصيانة متأخرة',
      'insufficientData': 'بيانات غير كافية',
      'companyManagement': 'إدارة الشركات',
      'distributors': 'الموزعون',
      'companyManagementHint':
          'ستُضاف إدارة الشركات والموزعين في مرحلة مخصّصة لاحقاً.',
      'utilizationScore': 'معدل الاستعمال',
      'mostActiveVehicles': 'أكثر المركبات نشاطاً',
      'leastActiveVehicles': 'الأقل حركة / راكدة',
      'driversToWatch': 'سائقون يحتاجون متابعة',
      'vehicleActivitySection': 'نشاط المركبات',
      'driverRankingSection': 'ترتيب السائقين',
      'maintenanceOverviewSection': 'ملخص الصيانة',
      'alertsOverviewSection': 'ملخص التنبيهات',
      'vehicleUtilizationSection': 'استعمال المركبات',
      'maintenanceUpcomingCount': 'قادمة',
      'maintenanceSoonCount': 'قريبة',
      'maintenanceOverdueCount': 'سجلات متأخرة',
      'nextMaintenances': 'أقرب الصيانات',
      'alertsTotalPeriod': 'الإجمالي (مهم)',
      'alertsOverspeed': 'تجاوز السرعة',
      'alertsGeofence': 'دخول/خروج منطقة',
      'alertsOnlineOffline': 'متصل/غير متصل (أحداث)',
      'lastImportantEvents': 'آخر الأحداث المهمة',
      'periodTotalDistance': 'مسافة الفترة',
      'vehiclesActiveInPeriod': 'مركبات لها رحلات',
      'fleetIntelLiveStatusHint':
          'حالة (متحركة / متوقفة / خامل / غير متصلة) تعكس لقطة الأسطول الحية.',
      'exportDashboardReport': 'تصدير تقرير لوحة التحكم',
      'driverRankEstimatedNote':
          'الترتيب تقريبي ويُبنى على الرحلات والأحداث المرتبطة بمركبات السائق المعيّنة.',
      'notAvailable': 'غير متوفر',
      'fleetStatusProblem': 'يستحق المتابعة',
      'adminDashboardLoadError': 'تعذّر تحميل لوحة التحكم.',
      'adminDashboardTripsPartialError':
          'تعذّر تحميل الرحلات/الأحداث لهذه الفترة. الأقسام الأخرى تستخدم البيانات المتاحة.',
      'dashboardConnectionLive': 'مباشر',
      'dashboardConnectionReconnecting': 'جارٍ إعادة الاتصال',
      'dashboardConnectionOverview': 'غير متصل',
      'dashboardConnectionDegraded': 'متصل · مزامنة متأخرة',
      'dashboardConnectionLiveReconnecting': 'إعادة اتصال مباشر…',
      'dashboardConnectionOffline': 'غير متصل',
      'dashboardConnectionServerUnavailable': 'الخادم غير متاح',
      'dashboardConnectionSessionExpired': 'انتهت الجلسة',
      'dashboardConnectionChecking': 'جارٍ الاتصال…',
      'dashboardSyncInProgress': 'جارٍ المزامنة…',
      'dashboardDistanceQuietHint':
          'ستتحدّث المسافة بمجرد بدء تحرّك المركبات.',
      'dashboardNoActivityToday': 'لا نشاطًا يُذكر اليوم.',
      'dashboardNoActivityPeriod': 'لا نشاطًا في هذه الفترة.',
      'dashboardViewFullFleet': 'عرض الأسطول بالكامل',
      'dashboardNoUrgentMaintenance': 'لا صيانة عاجلة.',
      'dashboardNoImportantAlerts': 'لا تنبيهات مهمة.',
      'dashboardImportantAlertsLabel': 'تنبيهات مهمة',
      'dashboardVehicleActivityEmpty': 'لا توجد مركبات نشطة خلال هذه الفترة.',
      'licenseAttentionTitle': 'الرخص — يستلزم المتابعة',
      'fleetEvtOverspeed': 'تجاوز السرعة',
      'fleetEvtGeofenceIn': 'دخول منطقة',
      'fleetEvtGeofenceOut': 'خروج منطقة',
      'fleetEvtOffline': 'غير متصل',
      'fleetEvtOnline': 'متصل',
      'fleetEvtAlarm': 'إنذار',
      'fleetEvtIgnitionOn': 'تشغيل المحرك',
      'fleetEvtIgnitionOff': 'إيقاف المحرك',
      'fleetEvtMaintenance': 'صيانة',
      'validationRequired': 'هذا الحقل إلزامي',
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
      'aboutFleetTrackingSubtitle':
          'Suivi GPS intelligent de flotte sur la plateforme ELMOGPS.',
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
      'noVehiclesInFilter': 'Aucun véhicule dans ce filtre',
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
      'lastKnownData': 'Dernière donnée connue',
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
      'cmdConfirmRequired': 'Confirmation requise',
      'cmdCriticalAction': 'Action critique',
      'cmdConfirmSendMessage': 'Vous êtes sur le point d\'envoyer',
      'cmdCriticalWarningDefault': 'Cette action peut affecter la sécurité du véhicule et du conducteur. Assurez-vous que l\'exécution est sûre.',
      'cmdTypeToConfirm': 'Pour confirmer, saisissez :',
      'cmdExecuteCommand': 'Exécuter la commande',
      'cmdDeviceOnline': 'Appareil en ligne',
      'cmdDeviceOffline': 'Appareil hors ligne',
      'cmdLastUpdate': 'Dernière MAJ :',
      'cmdVehicleStopped': 'Arrêté',
      'cmdSentSuccess': 'envoyée avec succès.',
      'cmdSentFailed': 'échouée',
      'cmdQueuedMessage': 'La commande a été mise en file d\'attente et sera exécutée dès la reconnexion de l\'appareil.',
      'cmdErrorSavedNotFound': 'Aucune commande sauvegardée trouvée pour cet appareil. Un technicien doit d\'abord la configurer.',
      'cmdErrorUnsupported': 'Cette commande n\'est pas supportée par cet appareil.',
      'cmdErrorTimeout': 'La connexion a expiré. Vérifiez votre connexion et réessayez.',
      'cmdErrorUnauthorized': 'Session expirée. Veuillez vous reconnecter.',
      'cmdErrorForbidden': 'Vous n\'avez pas les droits pour cette opération.',
      'cmdErrorNoConnection': 'Aucune connexion Internet. Vérifiez votre réseau et réessayez.',
      'cmdErrorBadRequest': 'La commande n\'a pas pu être traitée. Vérifiez les paramètres et réessayez.',
      'cmdErrorServer': 'Erreur serveur. Veuillez réessayer dans quelques instants.',
      'cmdErrorUnexpected': 'Une erreur inattendue s\'est produite. Réessayez ou contactez le support.',
      'cmdConfirmWord': 'CONFIRMER',
      'cmdLoadFailed': 'Échec du chargement des commandes',
      'cmdRetry': 'Réessayer',
      'vehicle': 'Véhicule',
      // Command Logs Screen
      'commandHistory': 'Historique',
      'commandHistoryEmpty': "L'historique apparaîtra ici après\nl'envoi de la première commande.",
      'clearHistoryConfirmMessage': 'Tous les journaux de commandes seront supprimés définitivement.',
      'delete': 'Effacer',
      'generalInfo': 'Informations générales',
      'command': 'Commande',
      'systemType': 'Type système',
      'category': 'Catégorie',
      'risk': 'Risque',
      'method': 'Méthode',
      'date': 'Date',
      'sentBy': 'Envoyé par',
      'userId': 'ID utilisateur',
      'executionContext': "Contexte d'exécution",
      'connectionStatus': 'État connexion',
      'online': 'En ligne',
      'speed': 'Vitesse',
      'device': 'Appareil',
      'errorMessage': "Message d'erreur",
      'message': 'Message',
      'technicalData': 'Données techniques (Technicien/Admin)',
      'technicalReason': 'Raison technique',
      'sentAttributes': 'Attributs envoyés',
      'rawResponse': 'Réponse brute (rawResponse)',
      'copy': 'Copier',
      'noTechnicalData': 'Aucune donnée technique disponible.',
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
      'routeIntelSpeedKmh': '{v} km/h',
      'routeIntelMinutesShort': '{n} min',
      'routeIntelPreviewTitle': 'Paramètres d’analyse du trajet',
      'routeIntelPreviewReadOnlyHint':
          'Aperçu lecture seule. Valeurs fusionnées depuis le compte, l’appareil et le groupe le cas échéant.',
      'routeIntelPreviewLoadingLayers':
          'Chargement de certaines couches de paramètres…',
      'routeIntelPreviewGroupLoadError':
          'Impossible de charger les paramètres du groupe ; aperçu peut être incomplet.',
      'routeIntelSettingsPreviewSection':
          'Analyse du trajet (aperçu — sans véhicule)',
      'routeIntelOverspeedThreshold': 'Seuil de survitesse',
      'routeIntelStopEnter': 'Début d’arrêt',
      'routeIntelStopExit': 'Fin d’arrêt',      'routeIntelMinStopDuration': 'Durée minimale d’arrêt',
      'routeIntelDetectStops': 'Détecter les arrêts',
      'routeIntelDetectOverspeed': 'Détecter la survitesse',
      'routeIntelDetectIgnition': 'Détecter le contact',      'routeIntelSourceDevice': 'Appareil',
      'routeIntelSourceGroup': 'Groupe',
      'routeIntelSourceUser': 'Utilisateur',
      'routeIntelSourceLocal': 'Local',
      'routeIntelSourceDefault': 'Défaut',
      'routeIntelEnabled': 'Activé',
      'routeIntelDisabled': 'Désactivé',
      'routeIntelLocalEditorTitle': 'Modifier les seuils locaux',
      'routeIntelLocalParamsHeading': 'Paramètres locaux',
      'routeIntelSave': 'Enregistrer',
      'routeIntelResetLocalPrefsSettings': 'Réinitialiser les paramètres locaux',
      'routeIntelSavedSnack': 'Enregistré',
      'routeIntelResetSnack': 'Réinitialisé',
      'routeIntelInvalidValue': 'Valeur invalide',
      'routeIntelLocalOnlyCentralWarning':
          'Ces paramètres sont enregistrés localement sur cet appareil. Ils ne modifient pas la configuration centrale ELMOGPS.',
      'routeIntelVehicleEditTitle': 'Seuils du véhicule',
      'routeIntelVehicleEditSubtitle':
          'Enregistrés dans la configuration centrale de ce véhicule sur la plateforme.',
      'routeIntelVehicleEditButton': 'Modifier les seuils du véhicule',
      'routeIntelVehicleSave': 'Enregistrer',
      'routeIntelVehicleReset': 'Réinitialiser les seuils du véhicule',
      'routeIntelVehicleSaved': 'Paramètres du véhicule enregistrés.',
      'routeIntelVehicleResetDone': 'Paramètres du véhicule réinitialisés.',
      'routeIntelVehicleSaveError':
          'Impossible d’enregistrer les paramètres. Réessayez.',
      'routeIntelVehicleResetError':
          'Impossible de réinitialiser les paramètres. Réessayez.',
      'routeIntelVehicleOnlyHint':
          'Ces paramètres s’appliquent uniquement à ce véhicule.',
      'routeIntelVehicleNoPermissionHint':
          'Lecture seule possible ; seuls les profils autorisés peuvent modifier la configuration centrale du véhicule.',
      'routeIntelVehicleResetConfirmMessage':
          'Supprime uniquement les dérogations d’analyse de trajet pour ce véhicule sur la plateforme. Flotte, compte et paramètres locaux restent inchangés.',
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
      'todaySummaryTitle': 'Activité du jour',
      'engineHoursLabel': 'Heures moteur',
      'vehicleActionsTitle': 'Actions',
      'technicalInfoTitle': 'Détails techniques',
      'noSummaryData': "Aucune donnée d'activité pour aujourd'hui.",
      'noAlertsForVehicle': 'Aucune alerte pour ce véhicule.',
      'alertsLoadError': 'Impossible de charger les alertes.',
      'tripsLoadError': 'Impossible de charger les trajets.',
      'reportSheetTitle': 'Générer un rapport véhicule',
      'selectReportType': 'Type de rapport',
      'selectPeriod': 'Période',
      'startDateLabel': 'Date de début',
      'endDateLabel': 'Date de fin',
      'invalidDateRange': 'La date de début doit être avant la date de fin.',
      'generateVehicleReport': 'Générer',
      'replaySheetTitle': 'Rejouer le trajet du véhicule',
      'selectReplayPeriod': 'Sélectionner la période',
      'startReplay': 'Lancer le replay',
      'replayRangeTooLong': 'La plage dépasse 24 heures. Le replay peut être lent avec beaucoup de données.',
      'noReplayDataForPeriod': 'Aucune donnée de trajet pour cette période.',
      'reportPdfSubjectPrefix': 'Rapport ELMOGPS',
      'reportPdfTitlePrefix': 'Rapport',
      'todayRouteLabel': 'Itinéraire du jour',
      'mapSearchVehicleHint': 'Rechercher véhicule, plaque, ID…',
      'filterAlertsMap': 'Alertes',
      'mapEmptyFilteredState': 'Aucun véhicule dans cet état pour le moment.',
      'mapNoVehiclesEmpty': 'Aucun véhicule à afficher pour le moment.',
      'liveFollowRunningLabel': 'Suivi en cours…',
      'resumeVehicleFollow': 'Reprendre le suivi',
      'mapLayersTitle': 'Couches de carte',
      'mapLayerAlerts': 'Afficher les alertes sur la carte',
      'mapLayerRoutesToday': 'Trace du jour sur la carte',
      'mapTypeNormal': 'Carte standard',
      'mapTypeSatellite': 'Satellite',
      'mapTypeTerrain': 'Relief',
      'mapVehicleListTitle': 'Liste des véhicules',
      'uniqueIdShortLabel': 'Identifiant appareil',
      'mapLayersButton': 'Couches',
      'filterVehicles': 'Filtrer les véhicules',
      'chooseVehicles': 'Choisir les véhicules',
      'chooseVehiclesHint': 'Sélectionnez un ou plusieurs véhicules à afficher sur la carte',
      'showAllVehicles': 'Afficher tous les véhicules',
      'showAllVehiclesOnMap': 'Afficher tous les véhicules sur la carte',
      'showVehicleOnMap': 'Afficher le véhicule sur la carte',
      'showSelectedVehiclesOnMap': 'Afficher {count} véhicules sur la carte',
      'clearSelection': 'Effacer la sélection',
      'selectedVehiclesCount': '{count} sélectionné(s)',
      'mapFilterSearchHint': 'Rechercher nom, plaque ou ID…',
      'onlineOnlyFilter': 'En ligne seulement',
      'movingOnlyFilter': 'En mouvement seulement',
      'vehiclesShownCount': '{count} véhicules affichés',
      'clearMapFilter': 'Effacer le filtre',
      'noVehiclesMatchFilter': 'Aucun véhicule ne correspond à ce filtre.',
      'selectVehiclesTitle': 'Sélectionner des véhicules',
      'mapFilterActiveLabel': 'Filtre actif',
      'mapFilterZeroVisible': 'Aucun véhicule visible — ajustez le filtre',
      'selectMultipleVehiclesHint': 'Sélectionnez un ou plusieurs véhicules à afficher sur la carte',
      'vehiclesSelectedCount': '{count} véhicules sélectionnés',
      'matchingVehiclesCount': '{count} véhicules correspondants',
      'noMatchingVehicles': 'Aucun véhicule ne correspond à votre recherche',
      'vehicleComparisonTitle': 'Comparaison des véhicules',
      'compareVehicles': 'Comparer les véhicules',
      'compareVehiclesCount': 'Comparer {count} véhicules',
      'comparedVehiclesCount': '{count} véhicules comparés',
      'selectAtLeastTwoVehicles':
          'Sélectionnez au moins deux véhicules pour comparer.',
      'todayComparison': "Aujourd'hui",
      'stopsToday': 'Arrêts aujourd\'hui',
      'maxSpeed': 'Vitesse max.',
      'averageSpeed': 'Vitesse moyenne',
      'stopDuration': 'Durée d\'arrêt',
      'lastUpdate': 'Dernière mise à jour',
      'highestDistance': 'Distance la plus élevée',
      'highestAlerts': 'Plus d\'alertes',
      'highestStopDuration': 'Temps d\'arrêt le plus élevé',
      'mostRecentUpdate': 'Mise à jour la plus récente',
      'removeFromComparison': 'Retirer de la comparaison',
      'noComparisonData': 'Aucune donnée de comparaison',
      'comparisonLoadFailed': 'Impossible de charger la comparaison',
      'comparisonLoading': 'Chargement de la comparaison…',
      'comparisonLoadingAnalyzing': 'Analyse des véhicules sélectionnés…',
      'backToMap': 'Retour à la carte',
      'multiVehicleReplayTitle': 'Replay multi-véhicules',
      'replaySelectedVehicles': 'Replay multi-véhicules',
      'replayVehiclesCount': 'Replay {count} véhicules',
      'replayComparedVehicles': 'Replay des véhicules comparés',
      'selectAtLeastTwoVehiclesReplay':
          'Sélectionnez au moins deux véhicules pour lancer le replay.',
      'multiReplayLimitMessage':
          'Le replay multi-véhicules est limité à 5 véhicules.',
      'multiReplayLoading': 'Chargement du replay multi-véhicules…',
      'multiReplayNoData':
          'Aucune donnée de trajet pour les véhicules sélectionnés.',
      'multiReplayLoadFailed': 'Impossible de charger le replay.',
      'multiReplayAutoFollow': 'Suivi automatique',
      'multiReplayActiveVehicle': 'Véhicule actif',
      'multiReplayVisibleVehicles': 'Véhicules visibles',
      'multiReplayHide': 'Masquer',
      'multiReplayShow': 'Afficher',
      'multiReplayNoVisibleVehicles': 'Aucun véhicule visible',
      'multiReplaySpeedColors': 'Couleurs de vitesse',
      'multiReplayNoFixAtTime': 'Aucune position à cet instant',
      'multiReplayComparison': 'Comparaison',
      'multiReplaySummary': 'Résumé',
      'multiReplayMovingTime': 'Durée en mouvement',
      'multiReplayStoppedTime': 'Durée à l\'arrêt',
      'multiReplayInsufficientData': 'Données insuffisantes',
      'multiReplayHiddenVehicle': 'Véhicule masqué',
      'multiReplayKpiLoadedNote':
          'Indicateurs pour tous les véhicules chargés (distance GPS approximative).',
      'multiReplayDistanceApproxNote':
          'Distance approximative à partir des points GPS ; les coupures sont exclues.',
      'multiReplayRouteStart': 'Début du trajet',
      'multiReplayRouteEnd': 'Fin du trajet',
      'multiReplayInsightLongestStop': 'Plus long arrêt',
      'multiReplayInsightHighestSpeed': 'Vitesse la plus élevée',
      'multiReplayInsightMostOverspeed': 'Plus d\'excès de vitesse',
      'multiReplayInsightFirstMovement': 'Premier mouvement',
      'multiReplayInsightEarliestEnd': 'Première fin de trajet',
      'routeDataUnavailable': 'Aucune donnée de trajet',
      'hideVehicle': 'Masquer le véhicule',
      'showVehicle': 'Afficher le véhicule',
      'replayToday': 'Aujourd\'hui',
      'chooseReplayDate': 'Choisir une date',
      'replayMultiVehicles': 'Replay multi-véhicules',
      'stopsCountLabel': 'Arrêts',
      'alertsTodayLabel': "Alertes aujourd'hui",
      'alertsForVehicle': 'Alertes pour ce véhicule',
      'alertsForVehicleName': 'Alertes pour {name}',
      'tripDateFilter': 'Filtrer les trajets par date',
      'clearDateFilter': 'Effacer le filtre de date',
      'centerFleetTooltip': 'Centrer la flotte',
      'fleetSummaryBar': '{online}/{total} en ligne · {moving} en mouvement · {idle} au ralenti',
      'locationUnavailable': 'Indisponible',
      'noLivePosition': 'Pas de position en direct',
      'positionMayBeOutdated': 'Position possiblement obsolète',
      'lastPositionIsOld': 'Dernière position ancienne',
      'currentAddress': 'Adresse',
      'liveTracking': 'Suivi en direct',
      'liveTrackingActive': 'En direct',
      'trackingDataStale': 'Données obsolètes',
      'trackingReconnecting': 'Reconnexion',
      'trackingOffline': 'Hors ligne',
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
      'routeEventsTimelineTitle': 'Événements du trajet',
      'routeEventsNoneDetected': 'Aucun événement détecté',
      'routeEventsSeeMore': 'Voir tous les événements',
      'replaySpeedShort': 'Vitesse',
      'replayCurrentPoint': 'Point actuel',
      'replayCompletedChip': 'Terminé',
      'replayMoreActions': 'Plus',
      'routeEventsSeeLess': 'Voir moins',
      'routeEventFilterAll': 'Tous',
      'routeEventFilterStops': 'Arrêts',
      'routeEventFilterOverspeed': 'Survitesse',
      'routeEventFilterIgnition': 'Contact',
      'routeEventsFilterNoMatches': 'Aucun événement dans ce filtre',
      'tripsTitle': 'Trajets',
      'tripLabel': 'Trajet',
      'tripTitle': 'Trajet {n}',
      'tripStart': 'Départ',
      'tripEnd': 'Arrivée',
      'tripDuration': 'Durée',
      'tripDistance': 'Distance',
      'tripStopsCount': '{n} arrêts',
      'tripOverspeedCount': '{n} survitesse',
      'tripMaxSpeed': 'Vitesse max',
      'tripReplay': 'Relecture',
      'tripViewOnMap': 'Voir sur la carte',
      'tripsNoneDetected': 'Aucun trajet détecté pour cette période.',
      'tripShort': 'Trajet trop court',
      'tripKm': 'km',
      'tripMin': 'min',
      'tripTimeArrow': '{from} → {to}',
      'tripKmUnit': 'km',
      'tripIgnitionSummary': 'Contact: {on} marche · {off} arrêt',
      'driverScoreLabel': 'Score',
      'driverScoreExcellent': 'Excellent',
      'driverScoreGood': 'Bon',
      'driverScoreModerate': 'Moyen',
      'driverScoreHighRisk': 'À surveiller',
      'driverScoreUnknown': 'Inconnu',
      'driverScoreNotScorable': 'Non évalué',
      'driverScoreTripTooShort': 'Trajet trop court',
      'dailyScoreTitle': 'Score de conduite',
      'dailyScorePeriodTitle': 'Pour cette période',
      'dailyScoreNotScorable': 'Non évalué',
      'dailyScoreInsufficientData': 'Données insuffisantes pour cette période',
      'dailyScoreTripCount': '{n} trajets',
      'dailyScoreScorableTrips': '{scored} notés · {total} trajets',
      'dailyScoreTotalDistance': '{km} km au total',
      'dailyScoreOverspeed': '{n} survitesses',
      'dailyScoreStops': '{n} arrêts',
      'dailyScoreBestTrip': 'Meilleur trajet : {name}',
      'dailyScoreWorstTrip': 'À surveiller : {name}',
      'dailyScoreNoTrips': 'Aucun trajet sur cette période',
      'dailyScoreDetailsTitle': 'Détails du score de conduite',
      'dailyScoreEvaluatedTrips': 'Trajets évalués',
      'dailyScoreUnscoredTrips': 'Trajets non notés',
      'dailyScoreTotalDuration': 'Durée totale',
      'dailyScoreTotalStopDuration': 'Durée totale des arrêts',
      'dailyScoreUnscoredExcludedHint':
          'Les trajets qui ne sont pas indiqués comme notés ici ne sont pas inclus dans la moyenne de la période.',
      'dailyScoreNoEvaluatedTrips': 'Aucun trajet n’a été noté pour cette période.',
      'dailyScoreTapForDetails': 'Voir le détail',
      'dailyScoreBestTripLabel': 'Meilleur trajet',
      'dailyScoreWorstTripLabel': 'À surveiller',
      'fleetIntelTitle': 'Comportement flotte',
      'fleetIntelSubtitle':
          'Résumé ELMOGPS de la qualité de conduite (fenêtre échantillon).',
      'fleetIntelScore': 'Score flotte',
      'fleetIntelNotScorable': 'Non évalué',
      'fleetIntelInsufficientData': 'Données insuffisantes',
      'fleetIntelVehicles': 'Véhicules',
      'fleetIntelActiveVehicles': 'Actifs',
      'fleetIntelInactiveVehicles': 'Inactifs',
      'fleetIntelTrips': 'Trajets',
      'fleetIntelDistance': 'Distance',
      'fleetIntelOverspeed': 'Dépassements',
      'fleetIntelStops': 'Arrêts',
      'fleetIntelBestVehicle': 'Meilleur véhicule',
      'fleetIntelWorstVehicle': 'À surveiller (score le plus bas)',
      'fleetIntelMostActiveVehicle': 'Le plus roulé',
      'fleetIntelMostOverspeedVehicle': 'Plus de dépassements',
      'fleetIntelMostStoppedVehicle': 'Temps d’arrêt le plus long',
      'fleetIntelNeedsAttention': 'À suivre',
      'fleetIntelRiskDistribution': 'Répartition des risques',
      'fleetIntelNoData': '—',
      'fleetIntelLoading': 'Chargement du résumé…',
      'fleetIntelError': 'Impossible de charger. Tirez pour réessayer.',
      'fleetIntelToday': 'Aujourd’hui',
      'fleetIntelYesterday': 'Hier',
      'fleetIntelLast7Days': '7 derniers jours',
      'fleetIntelNoTripsInPeriod':
          'Aucun trajet sur cette fenêtre pour l’échantillon.',
      'fleetIntelVehicleFallback': 'Véhicule {id}',
      'fleetIntelDrivingDuration': 'Temps de conduite : {value}',
      'fleetIntelStopDuration': 'Temps d’arrêt : {value}',
      'fleetIntelSampleNote':
          '{included}/{total} véhicules · jusqu’à {cap} chargés à chaque refresh (en ligne en priorité).',
      'fleetIntelOpenTrackingTooltip': 'Ouvrir le suivi',
      'fleetIntelDrivingTime': 'Temps de conduite',
      'fleetIntelPartialRoutes':
          'Certains parcours n’ont pas pu être chargés ; données partielles possibles.',
      'fleetIntelCustomPeriod': 'Personnalisé',
      'fleetIntelRefresh': 'Actualiser',
      'fleetIntelUpdatedAt': 'Mis à jour · {time}',
      'fleetIntelPartialData':
          'Certains indicateurs reposent sur un échantillon partiel.',
      'fleetIntelAnalyzedVehicles':
          'Parcours chargés pour {analyzed} véhicules sur {total}.',
      'fleetIntelLimitedToVehicles':
          'La plateforme charge jusqu’à {cap} véhicules par analyse pour préserver les performances.',
      'fleetAttentionTitle': 'Véhicules à suivre',
      'fleetAttentionNone':
          'Aucun véhicule à suivre pour cette période.',
      'fleetAttentionHighRisk': 'Risque élevé',
      'fleetAttentionLowScore': 'Score bas',
      'fleetAttentionManyOverspeed': 'Nombreux dépassements',
      'fleetAttentionManyStops': 'Nombreux ou longues immobilisations',
      'fleetAttentionInactive': 'Inactif / sans trajets',
      'fleetAttentionInsufficientData': 'Données insuffisantes',
      'fleetAttentionOpenVehicle': 'Voir le véhicule',
      'fleetAttentionDetailsTitle': 'Suivi',
      'fleetAttentionScore': 'Score de la période',
      'fleetAttentionReasons': 'Pourquoi ce véhicule est listé',
      'fleetAttentionTrips': 'Trajets',
      'fleetAttentionDistance': 'Distance',
      'fleetAttentionOverspeed': 'Dépassements de vitesse',
      'fleetAttentionStops': 'Arrêts',
      'fleetAttentionOpenMap': 'Voir la carte',
      'fleetAttentionOpenTrips': 'Voir les trajets',
      'fleetAttentionNoScore':
          'Pas de score pour cette période (pas assez de trajets exploitables).',
      'driverScoreDetailsTitle': 'Détails du score',
      'driverScoreTripScoredYes': 'Ce trajet est noté',
      'driverScoreTripScoredNo': 'Ce trajet n’est pas noté',
      'driverScoreFinalScore': 'Score final : {value}',
      'driverScoreBaseScore': 'Score de départ : {value}',
      'driverScoreTotalPenalty': 'Pénalités totales : {value}',
      'driverScoreSpeedPenalty': 'Survitesse',
      'driverScoreStopPenalty': 'Arrêts et immobilisation longue',
      'driverScoreIgnitionPenalty': 'Changements de contact',
      'driverScoreEfficiencyPenalty': 'Progression globale lente',
      'driverScoreFactorsTitle': 'Éléments ayant influencé ce score',
      'driverScoreReasonOverspeed': 'Dépassements de la limite de vitesse',
      'driverScoreReasonHeavyOverspeed': 'Survitesse à haute vitesse',
      'driverScoreReasonLongStops': 'Immobilisations prolongées',
      'driverScoreReasonExcessiveStops': 'Nombreux arrêts par rapport à la distance',
      'driverScoreReasonIgnitionTransitions': 'Allumages / extinctions fréquents',
      'driverScoreReasonLowEfficiency': 'Faible vitesse moyenne avec arrêts répétés',
      'driverScoreReasonCleanTrip': 'Aucun élément notable sur ce trajet',
      'driverScoreReasonShortTrip':
          'Trajet trop court ou trop bref pour une évaluation fiable.',
      'driverScoreReliableEnough':
          'Ce trajet suffit pour produire un score représentatif.',
      'driverScoreNotReliableEnough':
          'Un score équitable ne peut pas être affiché avec les données disponibles.',
      'driverScoreSteadyDriving':
          'Conduite régulière — pas de pénalités notables.',
      'driverScoreSeverityLow': 'Impact faible',
      'driverScoreSeverityMedium': 'Impact moyen',
      'driverScoreSeverityHigh': 'Impact fort',
      'driverScoreFactorOther': 'Autre facteur',
      'driverScorePenaltyLine': '{name} : −{points}',
      'driverScoreFactorOccurrences': '×{n}',
      'routeEventDetailsTitle': "Détails de l'événement",
      'routeEventDetailsStop': 'Arrêt',
      'routeEventDetailsOverspeed': 'Survitesse',
      'routeEventDetailsIgnitionOn': 'Contact activé',
      'routeEventDetailsIgnitionOff': 'Contact coupé',
      'routeEventDetailsStartTime': 'Heure de début',
      'routeEventDetailsEndTime': 'Heure de fin',
      'routeEventDetailsDuration': 'Durée',
      'routeEventDetailsTime': 'Heure',
      'routeEventDetailsMaxSpeed': 'Vitesse max.',
      'routeEventDetailsLocation': 'Emplacement',
      'routeEventDetailsRecenter': 'Recentrer sur la carte',
      // Replay
      'replayRoute': 'Rejouer le trajet',
      'replayPlay': 'Lecture',
      'replayPause': 'Pause',
      'replayRestart': 'Redémarrer',
      'replaySpeed': 'Vitesse de lecture',
      'replayCurrentSpeed': 'Vitesse actuelle',
      'replayCurrentTime': 'Heure actuelle',
      'replayRecenter': 'Recentrer',
      'replayVehicleHidden': 'Masqué',
      'replayVehicleNoData': 'Aucune donnée',
      'replayVehicleActive': 'Actif',
      'replayPlaying': 'Lecture',
      'replayPaused': 'En pause',
      'replayShowLabels': 'Afficher les libellés',
      'replayHideLabels': 'Masquer les libellés',
      'replayMapLegend': 'Véhicules',
      'replayPointsCount': '{count} points',
      'replayProgress': 'Progression',
      'loadingReplay': 'Chargement du replay…',
      'errorLoadingReplay': 'Erreur lors du chargement du replay.',
      'notEnoughDataForReplay': 'Données GPS insuffisantes pour le replay.',
      'routeCompleted': 'Trajet terminé',
      'viewReplay': 'Voir replay',
      'replayMissingGpsData': 'Données GPS manquantes',
      'replayMissingData': 'Données manquantes',
      'replayGapsDetected': 'Données manquantes : {count}',
      'replayGapStartLabel': 'Dernier point avant la coupure',
      'replayGapEndLabel': 'Premier point après la coupure',
      'replayGapDurationLabel': 'Durée de la coupure',
      'replayGapsSheetTitle': 'Coupures de données GPS',
      'replaySnapshotTitle': 'Instant actuel',
      'replaySnapshotTime': 'Heure',
      'replaySnapshotSpeed': 'Vitesse',
      'replaySnapshotAddress': 'Adresse',
      'replaySnapshotCoordinates': 'Coordonnées',
      'replaySnapshotDirection': 'Direction',
      'replaySnapshotIgnition': 'Moteur',
      'replaySnapshotEngineOn': 'Moteur allumé',
      'replaySnapshotEngineOff': 'Moteur éteint',
      'replaySnapshotDetails': 'Détails',
      'replaySensorsTitle': 'Capteurs',
      'replaySensorFuel': 'Carburant',
      'replaySensorBattery': 'Batterie',
      'replaySensorGsm': 'Signal GSM',
      'replaySensorSatellites': 'Satellites',
      'replaySensorAccuracy': 'Précision',
      'replaySensorDriver': 'Conducteur',
      'replaySensorUnavailable': 'Valeur non disponible',
      'replayAfterDataGap': 'Données reprises après interruption',
      'routeEventFilterDataGaps': 'Données manquantes',
      'routeTimelineStart': 'Début',
      'routeTimelineEnd': 'Fin',
      'replayTimelineSummaryStops': '{count} arrêts',
      'replayTimelineSummaryOverspeed': '{count} survitesse',
      'replayTimelineSummaryDataGaps': '{count} coupures',
      'replayTimelineSummaryIgnition': '{count} moteur',
      'routeEventFilterAlerts': 'Alertes',
      'replayExternalEvent': 'Événement',
      'replayExternalAlert': 'Alerte',
      'replayExternalMaintenance': 'Maintenance',
      'replayNoAlertsInPeriod': 'Aucune alerte sur cette période',
      'replayEventDetailsType': 'Type',
      'replayEventDetailsDescription': 'Description',
      'replayExternalPositionUnavailable': 'Position non disponible',
      'replayStepPrevious': 'Point précédent',
      'replayStepNext': 'Point suivant',
      // Speed chart
      'speedChartTitle': 'Graphique de vitesse',
      'speedChartMax': 'Vitesse maximale',
      'speedChartAvg': 'Vitesse moyenne',
      'speedChartGpsPoints': 'Points GPS',
      'noSpeedData': 'Aucune donnée de vitesse disponible.',
      'viewSpeedChart': 'Voir graphique vitesse',
      'geofencesTitle': 'Zones géographiques',
      'geofencesAdd': 'Ajouter une zone',
      'geofenceEdit': 'Modifier la zone',
      'geofenceDelete': 'Supprimer la zone',
      'geofenceNameLabel': 'Nom de la zone',
      'geofenceTypeLabel': 'Type de zone',
      'geofenceTypeCircle': 'Cercle',
      'geofenceTypePolygon': 'Polygone',
      'geofenceRadius': 'Rayon',
      'geofenceLinkedVehicles': 'Véhicules associés',
      'geofenceAlertSectionTitle': 'Alertes d’entrée/sortie',
      'geofenceZoneEntry': 'Entrée zone',
      'geofenceZoneExit': 'Sortie zone',
      'geofenceShowOnMap': 'Afficher les zones',
      'geofenceTapMapCenter': 'Appuyez sur la carte pour définir le centre',
      'geofencePolygonMinPoints': 'Ajoutez au moins 3 points',
      'geofenceCreated': 'Zone créée avec succès',
      'geofenceUpdated': 'Zone mise à jour',
      'geofenceDeleted': 'Zone supprimée',
      'geofenceLoadError': 'Erreur lors du chargement des zones',
      'geofenceAlertStatusOn': 'Alertes actives',
      'geofenceAlertStatusOff': 'Pas d’alertes',
      'geofenceSearchHint': 'Rechercher par nom',
      'geofenceFilterAllTypes': 'Tous les types',
      'geofenceDeleteTitle': 'Supprimer la zone',
      'geofenceDeleteMessage': 'La zone sera définitivement supprimée.',
      'geofenceDeleteWarningWithVehicles':
          'Cette zone est liée à {n} véhicule(s). Elle sera tout de même supprimée.',
      'geofencesEmptyTitle': 'Aucune zone',
      'geofencesEmptyMessage': 'Ajoutez une zone pour la voir sur la carte et recevoir des alertes.',
      'geofenceColorLabel': 'Couleur',
      'geofenceTapMapCenterHint': 'Appuyez sur la carte pour définir le centre',
      'geofencePolygonTapHint': 'Appuyez sur la carte pour ajouter des points',
      'geofencePolygonUndoLast': 'Annuler le dernier point',
      'geofenceNotifyEnter': 'Créer une alerte d’entrée',
      'geofenceNotifyExit': 'Créer une alerte de sortie',
      'geofenceNotifyBoth': 'Créer les deux',
      'geofenceNoVehiclesLinked': 'Aucun véhicule sélectionné',
      'geofenceVehiclesSelectedCount': '{n} véhicule(s) sélectionné(s)',
      'geofenceVehiclesClear': 'Effacer',
      'geofenceDetailsTitle': 'Détails de la zone',
      'geofenceNotFound': 'Zone introuvable',
      'driversTitle': 'Conducteurs',
      'driversAdd': 'Ajouter conducteur',
      'driversEdit': 'Modifier conducteur',
      'driversDelete': 'Supprimer conducteur',
      'driversSearchHint': 'Rechercher par nom ou code',
      'driversEmptyTitle': 'Aucun conducteur',
      'driversEmptyMessage': 'Créez un conducteur pour l’associer à vos véhicules.',
      'driverDetailTitle': 'Conducteur — détails',
      'driverNameLabel': 'Nom du conducteur',
      'driverCodeLabel': 'Code conducteur',
      'driverPhoneLabel': 'Téléphone',
      'drivingLicenseLabel': 'Permis de conduire',
      'licenseExpiryLabel': 'Date d’expiration du permis',
      'driversLinkedVehicles': 'Véhicules associés',
      'driverNotesLabel': 'Remarques',
      'driversSave': 'Enregistrer',
      'driversDeleteConfirmTitle': 'Supprimer ce conducteur',
      'driversDeleteConfirmBody':
          'Cette action efface définitivement ce conducteur.',
      'driversLoadError': 'Chargement des conducteurs impossible',
      'driversSelectVehiclesHint': 'Choisir des véhicules de votre flotte.',
      'licenseStatusUnknown': 'Statut inconnu',
      'licenseStatusValid': 'Licence valide',
      'licenseStatusSoon': 'Licence bientôt expirée',
      'licenseStatusExpired': 'Licence expirée',
      'maintenanceTitle': 'Maintenance',
      'maintenanceAdd': 'Ajouter maintenance',
      'maintenanceEdit': 'Modifier maintenance',
      'maintenanceDelete': 'Supprimer maintenance',
      'maintenanceDetailTitle': 'Détail de la maintenance',
      'maintenanceSearchHint': 'Rechercher une maintenance',
      'maintenanceFilterAll': 'Tous les véhicules',
      'maintenanceFilterVehicle': 'Filtrer par véhicule',
      'maintenanceLoadError': 'Chargement de la maintenance impossible',
      'maintenanceEmptyTitle': 'Aucune maintenance',
      'maintenanceEmptyMessage':
          'Planifiez les entretiens pour suivre échéances et kilométrages.',
      'maintenanceTypeLabelField': 'Type de maintenance',
      'maintenanceDueDateLabel': 'Date d’échéance',
      'maintenanceDueOdometerLabel': 'Kilométrage d’échéance',
      'maintenanceMarkCompletedHint': 'Marquer comme terminé',
      'maintenanceDeleteConfirmTitle': 'Supprimer la maintenance',
      'maintenanceDeleteConfirmBody':
          'Supprimer cet enregistrement de façon définitive ?',
      'maintStatusUnknown': 'Inconnu',
      'maintStatusCompleted': 'Terminé',
      'maintStatusUpcoming': 'À venir',
      'maintStatusSoon': 'Bientôt',
      'maintStatusOverdue': 'En retard',
      'maintType_oil_change': 'Changement d’huile',
      'maintType_oil_filter': 'Filtre à huile',
      'maintType_air_filter': 'Filtre à air',
      'maintType_tires': 'Pneus',
      'maintType_brakes': 'Freins',
      'maintType_battery': 'Batterie',
      'maintType_draining': 'Vidange',
      'maintType_general_revision': 'Révision générale',
      'maintType_insurance': 'Assurance',
      'maintType_technical_inspection': 'Visite technique',
      'maintType_vignette': 'Vignette',
      'maintType_other': 'Autre',
      'fleetCardNoDriver': 'Conducteur non assigné',
      'fleetCardDriverAssigned': 'Conducteur {name}',
      'fleetCardNoMaintenance': 'Aucune maintenance',
      'fleetCardMaintenanceSnippet': 'Maintenance • {snippet}',
      'fleetCardSummaryStoppedFor': 'Arrêtée depuis {duration}',
      'fleetCardSummaryIdleFor': 'Inactif depuis {duration}',
      'fleetCardSummaryEngineOffFor': 'Moteur éteint depuis {duration}',
      'fleetCardLastMovement': 'Dernier mouvement : {time}',
      'fleetCardLastIgnition': 'Dernier allumage : {time}',
      'fleetCardEngineOffSince': 'Moteur éteint depuis {duration}',
      'fleetCardLastPosition': 'Dernière position : {address}',
      'fleetCardLastData': 'Dernière donnée : {time}',
      'fleetCardAlertNoRecentData': 'Aucune donnée récente',
      'fleetCardAlertOfflineLong': 'Hors ligne depuis {duration}',
      'fleetCardAlertOfflineSince': 'Hors ligne depuis {time}',
      'fleetCardAlertStaleData': 'Données obsolètes ({time})',
      'fleetCardAlertLowBattery': 'Batterie faible ({voltage})',
      'fleetCardAlertBatteryAttention': 'Vérifier la batterie ({voltage})',
      'fleetCardAlertLowFuel': 'Carburant bas ({level})',
      'relativeJustNow': 'À l\'instant',
      'relativeMinutesAgo': 'il y a {n} min',
      'relativeHoursAgo': 'il y a {n} h',
      'relativeDaysAgo': 'il y a {n} j',
      'relativeYesterdayAt': 'hier {time}',
      'relativeDateAt': '{date} {time}',
      'fleetStatsLastSyncNow': 'Dernière mise à jour : maintenant',
      'fleetSectionDocuments': 'Documents',
      'fleetDocInsuranceLabel': 'Assurance',
      'fleetDocInspectionLabel': 'Visite technique',
      'fleetAlertMaintSoonTitle': 'Maintenance bientôt due',
      'fleetAlertMaintSoonDesc': '{vehicle} : « {task} » approche.',
      'fleetAlertMaintOverdueTitle': 'Maintenance en retard',
      'fleetAlertMaintOverdueDesc': '{vehicle} : « {task} » est en retard.',
      'fleetAlertInsuranceSoonTitle': 'Assurance bientôt expirée',
      'fleetAlertInsuranceSoonDesc': '{vehicle} : la validité assurance approche.',
      'fleetAlertInsuranceExpiredTitle': 'Assurance expirée',
      'fleetAlertInsuranceExpiredDesc': '{vehicle} : assurance expirée.',
      'fleetAlertTechSoonTitle': 'Visite technique bientôt expirée',
      'fleetAlertTechSoonDesc': '{vehicle} : la VT approche.',
      'fleetAlertTechExpiredTitle': 'Visite technique expirée',
      'fleetAlertTechExpiredDesc': '{vehicle} : VT expirée.',
      'fleetAlertLicenseSoonTitle': 'Permis conducteur bientôt expiré',
      'fleetAlertLicenseSoonDesc': '{name} : expiration du permis proche.',
      'fleetAlertLicenseExpiredTitle': 'Permis conducteur expiré',
      'fleetAlertLicenseExpiredDesc': '{name} : permis expiré.',
      'reportFleetMaintenanceSoon':
          'Rapport Maintenance — Disponible prochainement',
      'reportFleetDriversSoon':
          'Rapport Conducteurs — Disponible prochainement',
      'fleetIntelligenceTitle': 'Intelligence flotte',
      'fleetIntelligenceDashboardSubtitle': 'Indicateurs et état en direct',
      'vehiclesOnline': 'En ligne',
      'kpiDriversTotal': 'Conducteurs',
      'kpiDriversActive': 'Conducteurs actifs',
      'maintenanceOverdueVehicles': 'Véhicules — maintenance en retard',
      'insufficientData': 'Données insuffisantes',
      'companyManagement': 'Gestion des entreprises',
      'distributors': 'Distributeurs',
      'companyManagementHint':
          'La gestion multi-entreprises et distributeurs sera ajoutée dans une phase dédiée.',
      'utilizationScore': "Score d'utilisation",
      'mostActiveVehicles': 'Véhicules les plus actifs',
      'leastActiveVehicles': 'Les moins actifs / à l’arrêt',
      'driversToWatch': 'Conducteurs à surveiller',
      'vehicleActivitySection': 'Activité des véhicules',
      'driverRankingSection': 'Classement des conducteurs',
      'maintenanceOverviewSection': 'Aperçu maintenance',
      'alertsOverviewSection': 'Aperçu des alertes',
      'vehicleUtilizationSection': 'Utilisation des véhicules',
      'maintenanceUpcomingCount': 'À venir',
      'maintenanceSoonCount': 'Bientôt',
      'maintenanceOverdueCount': 'En retard (fiches)',
      'nextMaintenances': 'Prochaines maintenances',
      'alertsTotalPeriod': 'Total (important)',
      'alertsOverspeed': 'Excès de vitesse',
      'alertsGeofence': 'Entrée/sortie de zone',
      'alertsOnlineOffline': 'Hors ligne / en ligne (événements)',
      'lastImportantEvents': 'Derniers événements importants',
      'periodTotalDistance': 'Distance sur la période',
      'vehiclesActiveInPeriod': 'Véhicules avec trajets',
      'fleetIntelLiveStatusHint':
          'Les états (en mouvement / arrêtés / au ralenti / hors ligne) reflètent le flux temps réel actuel.',
      'exportDashboardReport': 'Exporter le rapport du tableau de bord',
      'driverRankEstimatedNote':
          'Classement approximatif d’après trajets/événements des véhicules assignés au conducteur.',
      'notAvailable': 'Non disponible',
      'fleetStatusProblem': 'À surveiller',
      'adminDashboardLoadError': 'Échec du chargement du tableau de bord.',
      'adminDashboardTripsPartialError':
          'Impossible de charger trajets/événements pour cette période. Les autres sections restent disponibles.',
      'dashboardConnectionLive': 'En direct',
      'dashboardConnectionReconnecting': 'Reconnexion',
      'dashboardConnectionOverview': 'Hors ligne',
      'dashboardConnectionDegraded': 'Connecté · Synchronisation retardée',
      'dashboardConnectionLiveReconnecting': 'Reconnexion du direct…',
      'dashboardConnectionOffline': 'Hors ligne',
      'dashboardConnectionServerUnavailable': 'Serveur indisponible',
      'dashboardConnectionSessionExpired': 'Session expirée',
      'dashboardConnectionChecking': 'Connexion…',
      'dashboardSyncInProgress': 'Synchronisation…',
      'dashboardDistanceQuietHint':
          'La distance se mettra à jour dès les premiers déplacements.',
      'dashboardNoActivityToday': 'Aucune activité détectée aujourd\'hui.',
      'dashboardNoActivityPeriod': 'Aucune activité sur cette période.',
      'dashboardViewFullFleet': 'Voir toute la flotte',
      'dashboardNoUrgentMaintenance': 'Aucune maintenance urgente.',
      'dashboardNoImportantAlerts': 'Aucune alerte importante.',
      'dashboardImportantAlertsLabel': 'Alertes importantes',
      'dashboardVehicleActivityEmpty':
          'Aucun véhicule actif sur cette période.',
      'licenseAttentionTitle': 'Permis — suivi requis',
      'fleetEvtOverspeed': 'Excès de vitesse',
      'fleetEvtGeofenceIn': 'Entrée zone',
      'fleetEvtGeofenceOut': 'Sortie zone',
      'fleetEvtOffline': 'Hors ligne',
      'fleetEvtOnline': 'En ligne',
      'fleetEvtAlarm': 'Alarme',
      'fleetEvtIgnitionOn': 'Contact mis',
      'fleetEvtIgnitionOff': 'Contact coupé',
      'fleetEvtMaintenance': 'Maintenance',
      'validationRequired': 'Champ obligatoire',
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
      'aboutFleetTrackingSubtitle':
          'Seguimiento GPS inteligente de flota en la plataforma ELMOGPS.',
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
      'noVehiclesInFilter': 'Ningún vehículo en este filtro',
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
      'lastKnownData': 'Último dato conocido',
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
      'cmdConfirmRequired': 'Confirmación requerida',
      'cmdCriticalAction': 'Acción crítica',
      'cmdConfirmSendMessage': 'Está a punto de enviar',
      'cmdCriticalWarningDefault': 'Esta acción puede afectar la seguridad del vehículo y del conductor. Asegúrese de que la ejecución sea segura.',
      'cmdTypeToConfirm': 'Para confirmar, escriba:',
      'cmdExecuteCommand': 'Ejecutar comando',
      'cmdDeviceOnline': 'Dispositivo en línea',
      'cmdDeviceOffline': 'Dispositivo fuera de línea',
      'cmdLastUpdate': 'Última actualización:',
      'cmdVehicleStopped': 'Detenido',
      'cmdSentSuccess': 'enviado con éxito.',
      'cmdSentFailed': 'fallido',
      'cmdQueuedMessage': 'El comando ha sido puesto en cola y se ejecutará cuando el dispositivo se reconecte.',
      'cmdErrorSavedNotFound': 'No se encontró un comando guardado para este dispositivo. Un técnico debe configurarlo primero.',
      'cmdErrorUnsupported': 'Este comando no es compatible con este dispositivo.',
      'cmdErrorTimeout': 'La conexión ha expirado. Verifique su conexión e intente de nuevo.',
      'cmdErrorUnauthorized': 'Sesión expirada. Por favor, inicie sesión de nuevo.',
      'cmdErrorForbidden': 'No tiene permisos para esta operación.',
      'cmdErrorNoConnection': 'Sin conexión a Internet. Verifique su red e intente de nuevo.',
      'cmdErrorBadRequest': 'El comando no pudo ser procesado. Verifique los parámetros e intente de nuevo.',
      'cmdErrorServer': 'Error del servidor. Intente de nuevo en un momento.',
      'cmdErrorUnexpected': 'Ocurrió un error inesperado. Intente de nuevo o contacte al soporte.',
      'cmdConfirmWord': 'CONFIRMAR',
      'cmdLoadFailed': 'Error al cargar los comandos',
      'cmdRetry': 'Reintentar',
      'vehicle': 'Vehículo',
      // Command Logs Screen
      'commandHistory': 'Historial',
      'commandHistoryEmpty': 'El historial aparecerá aquí después\nde enviar el primer comando.',
      'clearHistoryConfirmMessage': 'Todos los registros de comandos serán eliminados permanentemente.',
      'delete': 'Borrar',
      'generalInfo': 'Información general',
      'command': 'Comando',
      'systemType': 'Tipo de sistema',
      'category': 'Categoría',
      'risk': 'Riesgo',
      'method': 'Método',
      'date': 'Fecha',
      'sentBy': 'Enviado por',
      'userId': 'ID de usuario',
      'executionContext': 'Contexto de ejecución',
      'connectionStatus': 'Estado de conexión',
      'online': 'En línea',
      'speed': 'Velocidad',
      'device': 'Dispositivo',
      'errorMessage': 'Mensaje de error',
      'message': 'Mensaje',
      'technicalData': 'Datos técnicos (Técnico/Admin)',
      'technicalReason': 'Razón técnica',
      'sentAttributes': 'Atributos enviados',
      'rawResponse': 'Respuesta sin procesar',
      'copy': 'Copiar',
      'noTechnicalData': 'No hay datos técnicos disponibles.',
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
      'routeIntelSpeedKmh': '{v} km/h',
      'routeIntelMinutesShort': '{n} min',
      'routeIntelPreviewTitle': 'Ajustes de análisis de ruta',
      'routeIntelPreviewReadOnlyHint':
          'Vista previa solo lectura. Valores combinados desde la cuenta, el dispositivo y el grupo cuando aplica.',
      'routeIntelPreviewLoadingLayers':
          'Cargando algunas capas de configuración…',
      'routeIntelPreviewGroupLoadError':
          'No se pudieron cargar los valores del grupo; la vista puede estar incompleta.',
      'routeIntelSettingsPreviewSection': 'Análisis de ruta (vista previa)',
      'routeIntelOverspeedThreshold': 'Umbral de exceso de velocidad',
      'routeIntelStopEnter': 'Velocidad de entrada en parada',
      'routeIntelStopExit': 'Velocidad de salida de parada',
      'routeIntelMinStopDuration': 'Duración mínima de parada',
      'routeIntelDetectStops': 'Detectar paradas',
      'routeIntelDetectOverspeed': 'Detectar exceso de velocidad',
      'routeIntelDetectIgnition': 'Detectar contacto',
      'routeIntelSourceDevice': 'Dispositivo',
      'routeIntelSourceGroup': 'Grupo',
      'routeIntelSourceUser': 'Usuario',
      'routeIntelSourceLocal': 'Local',
      'routeIntelSourceDefault': 'Predeterminado',
      'routeIntelEnabled': 'Activado',
      'routeIntelDisabled': 'Desactivado',
      'routeIntelLocalEditorTitle': 'Editar umbrales locales',
      'routeIntelLocalParamsHeading': 'Parámetros locales',
      'routeIntelSave': 'Guardar',
      'routeIntelResetLocalPrefsSettings': 'Restablecer ajustes locales',
      'routeIntelSavedSnack': 'Guardado',
      'routeIntelResetSnack': 'Restablecido',
      'routeIntelInvalidValue': 'Valor no válido',
      'routeIntelLocalOnlyCentralWarning':
          'Estos ajustes se guardan solo en este dispositivo. No modifican la configuración central de ELMOGPS.',
      'routeIntelVehicleEditTitle': 'Umbrales del vehículo',
      'routeIntelVehicleEditSubtitle':
          'Se guardan en la configuración central de este vehículo en la plataforma.',
      'routeIntelVehicleEditButton': 'Editar umbrales del vehículo',
      'routeIntelVehicleSave': 'Guardar',
      'routeIntelVehicleReset': 'Restablecer umbrales del vehículo',
      'routeIntelVehicleSaved': 'Ajustes del vehículo guardados.',
      'routeIntelVehicleResetDone': 'Ajustes del vehículo restablecidos.',
      'routeIntelVehicleSaveError':
          'No se pudieron guardar los ajustes. Inténtalo de nuevo.',
      'routeIntelVehicleResetError':
          'No se pudieron restablecer los ajustes. Inténtalo de nuevo.',
      'routeIntelVehicleOnlyHint':
          'Estos ajustes se aplican solo a este vehículo.',
      'routeIntelVehicleNoPermissionHint':
          'Solo lectura; solo los perfiles autorizados pueden cambiar la configuración central del vehículo.',
      'routeIntelVehicleResetConfirmMessage':
          'Elimina solo las anulaciones de análisis de ruta de este vehículo en la plataforma. Flota, cuenta y ajustes locales no cambian.',
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
      'todaySummaryTitle': 'Actividad de hoy',
      'engineHoursLabel': 'Horas de motor',
      'vehicleActionsTitle': 'Acciones',
      'technicalInfoTitle': 'Detalles técnicos',
      'noSummaryData': 'No hay datos de actividad para hoy.',
      'noAlertsForVehicle': 'No hay alertas para este vehículo.',
      'alertsLoadError': 'No se pudieron cargar las alertas.',
      'tripsLoadError': 'No se pudieron cargar los viajes.',
      'reportSheetTitle': 'Generar informe del vehículo',
      'selectReportType': 'Tipo de informe',
      'selectPeriod': 'Período',
      'startDateLabel': 'Fecha de inicio',
      'endDateLabel': 'Fecha de fin',
      'invalidDateRange': 'La fecha de inicio debe ser anterior a la fecha de fin.',
      'generateVehicleReport': 'Generar',
      'replaySheetTitle': 'Reproducir ruta del vehículo',
      'selectReplayPeriod': 'Seleccionar período',
      'startReplay': 'Iniciar reproducción',
      'replayRangeTooLong': 'El rango supera las 24 horas. La reproducción puede ser lenta con muchos datos.',
      'noReplayDataForPeriod': 'No hay datos de ruta para este período.',
      'reportPdfSubjectPrefix': 'Informe ELMOGPS',
      'reportPdfTitlePrefix': 'Informe',
      'todayRouteLabel': 'Ruta de hoy',
      'mapSearchVehicleHint': 'Buscar vehículo, matrícula, ID…',
      'filterAlertsMap': 'Alertas',
      'mapEmptyFilteredState': 'No hay vehículos en este estado ahora.',
      'mapNoVehiclesEmpty': 'No hay vehículos para mostrar.',
      'liveFollowRunningLabel': 'Siguiendo en vivo…',
      'resumeVehicleFollow': 'Volver al seguimiento',
      'mapLayersTitle': 'Capas del mapa',
      'mapLayerAlerts': 'Mostrar alertas en el mapa',
      'mapLayerRoutesToday': 'Trazado del día en el mapa',
      'mapTypeNormal': 'Mapa estándar',
      'mapTypeSatellite': 'Satélite',
      'mapTypeTerrain': 'Terreno',
      'mapVehicleListTitle': 'Lista de vehículos',
      'uniqueIdShortLabel': 'ID del dispositivo',
      'mapLayersButton': 'Capas',
      'filterVehicles': 'Filtrar vehículos',
      'chooseVehicles': 'Elegir vehículos',
      'chooseVehiclesHint': 'Seleccione uno o más vehículos para mostrar en el mapa',
      'showAllVehicles': 'Mostrar todos los vehículos',
      'showAllVehiclesOnMap': 'Mostrar todos los vehículos en el mapa',
      'showVehicleOnMap': 'Mostrar vehículo en el mapa',
      'showSelectedVehiclesOnMap': 'Mostrar {count} vehículos en el mapa',
      'clearSelection': 'Borrar selección',
      'selectedVehiclesCount': '{count} seleccionados',
      'mapFilterSearchHint': 'Buscar nombre, matrícula o ID…',
      'onlineOnlyFilter': 'Solo en línea',
      'movingOnlyFilter': 'Solo en movimiento',
      'vehiclesShownCount': '{count} vehículos mostrados',
      'clearMapFilter': 'Borrar filtro',
      'noVehiclesMatchFilter': 'Ningún vehículo coincide con este filtro.',
      'selectVehiclesTitle': 'Seleccionar vehículos',
      'mapFilterActiveLabel': 'Filtro activo',
      'mapFilterZeroVisible': 'Ningún vehículo visible — ajuste el filtro',
      'selectMultipleVehiclesHint': 'Seleccione uno o más vehículos para mostrar en el mapa',
      'vehiclesSelectedCount': '{count} vehículos seleccionados',
      'matchingVehiclesCount': '{count} vehículos coincidentes',
      'noMatchingVehicles': 'Ningún vehículo coincide con su búsqueda',
      'vehicleComparisonTitle': 'Comparación de vehículos',
      'compareVehicles': 'Comparar vehículos',
      'compareVehiclesCount': 'Comparar {count} vehículos',
      'comparedVehiclesCount': '{count} vehículos comparados',
      'selectAtLeastTwoVehicles':
          'Seleccione al menos dos vehículos para comparar.',
      'todayComparison': 'Hoy',
      'stopsToday': 'Paradas hoy',
      'maxSpeed': 'Velocidad máx.',
      'averageSpeed': 'Velocidad media',
      'stopDuration': 'Duración de parada',
      'lastUpdate': 'Última actualización',
      'highestDistance': 'Mayor distancia',
      'highestAlerts': 'Más alertas',
      'highestStopDuration': 'Mayor tiempo de parada',
      'mostRecentUpdate': 'Actualización más reciente',
      'removeFromComparison': 'Quitar de la comparación',
      'noComparisonData': 'Sin datos de comparación',
      'comparisonLoadFailed': 'No se pudo cargar la comparación',
      'comparisonLoading': 'Cargando comparación…',
      'comparisonLoadingAnalyzing': 'Analizando vehículos seleccionados…',
      'backToMap': 'Volver al mapa',
      'multiVehicleReplayTitle': 'Reproducción multi-vehículo',
      'replaySelectedVehicles': 'Reproducir vehículos seleccionados',
      'replayVehiclesCount': 'Reproducir {count} vehículos',
      'replayComparedVehicles': 'Reproducir vehículos comparados',
      'selectAtLeastTwoVehiclesReplay':
          'Seleccione al menos dos vehículos para iniciar la reproducción.',
      'multiReplayLimitMessage':
          'La reproducción multi-vehículo está limitada a 5 vehículos.',
      'multiReplayLoading': 'Cargando reproducción multi-vehículo…',
      'multiReplayNoData':
          'No hay datos de ruta para los vehículos seleccionados.',
      'multiReplayLoadFailed': 'No se pudo cargar la reproducción.',
      'multiReplayAutoFollow': 'Seguimiento automático',
      'multiReplayActiveVehicle': 'Vehículo activo',
      'multiReplayVisibleVehicles': 'Vehículos visibles',
      'multiReplayHide': 'Ocultar',
      'multiReplayShow': 'Mostrar',
      'multiReplayNoVisibleVehicles': 'No hay vehículos visibles',
      'multiReplaySpeedColors': 'Colores de velocidad',
      'multiReplayNoFixAtTime': 'Sin posición en este momento',
      'multiReplayComparison': 'Comparación',
      'multiReplaySummary': 'Resumen',
      'multiReplayMovingTime': 'Tiempo en movimiento',
      'multiReplayStoppedTime': 'Tiempo detenido',
      'multiReplayInsufficientData': 'Datos insuficientes',
      'multiReplayHiddenVehicle': 'Vehículo oculto',
      'multiReplayKpiLoadedNote':
          'Indicadores de todos los vehículos cargados (distancia GPS aproximada).',
      'multiReplayDistanceApproxNote':
          'Distancia aproximada desde puntos GPS; se excluyen cortes.',
      'multiReplayRouteStart': 'Inicio de ruta',
      'multiReplayRouteEnd': 'Fin de ruta',
      'multiReplayInsightLongestStop': 'Mayor tiempo detenido',
      'multiReplayInsightHighestSpeed': 'Velocidad más alta',
      'multiReplayInsightMostOverspeed': 'Más excesos de velocidad',
      'multiReplayInsightFirstMovement': 'Primer movimiento',
      'multiReplayInsightEarliestEnd': 'Primera fin de ruta',
      'routeDataUnavailable': 'Sin datos de ruta',
      'hideVehicle': 'Ocultar vehículo',
      'showVehicle': 'Mostrar vehículo',
      'replayToday': 'Hoy',
      'chooseReplayDate': 'Elegir fecha',
      'replayMultiVehicles': 'Reproducción multi-vehículo',
      'stopsCountLabel': 'Paradas',
      'alertsTodayLabel': 'Alertas hoy',
      'alertsForVehicle': 'Alertas de este vehículo',
      'alertsForVehicleName': 'Alertas de {name}',
      'tripDateFilter': 'Filtrar viajes por fecha',
      'clearDateFilter': 'Borrar filtro de fecha',
      'centerFleetTooltip': 'Centrar flota',
      'fleetSummaryBar': '{online}/{total} en línea · {moving} en marcha · {idle} en ralentí',
      'locationUnavailable': 'No disponible',
      'noLivePosition': 'Sin posición en vivo',
      'positionMayBeOutdated': 'La posición puede estar desactualizada',
      'lastPositionIsOld': 'Última posición es antigua',
      'currentAddress': 'Dirección',
      'liveTracking': 'Seguimiento en vivo',
      'liveTrackingActive': 'En vivo',
      'trackingDataStale': 'Datos obsoletos',
      'trackingReconnecting': 'Reconectando',
      'trackingOffline': 'Sin conexión',
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
      'routeEventsTimelineTitle': 'Eventos del trayecto',
      'routeEventsNoneDetected': 'No se detectaron eventos',
      'routeEventsSeeMore': 'Ver todos los eventos',
      'replaySpeedShort': 'Velocidad',
      'replayCurrentPoint': 'Punto actual',
      'replayCompletedChip': 'Completado',
      'replayMoreActions': 'Más',
      'routeEventsSeeLess': 'Mostrar menos',
      'routeEventFilterAll': 'Todos',
      'routeEventFilterStops': 'Paradas',
      'routeEventFilterOverspeed': 'Exceso de velocidad',
      'routeEventFilterIgnition': 'Contacto',
      'routeEventsFilterNoMatches': 'Sin eventos en este filtro',
      'tripsTitle': 'Trayectos',
      'tripLabel': 'Trayecto',
      'tripTitle': 'Trayecto {n}',
      'tripStart': 'Inicio',
      'tripEnd': 'Fin',
      'tripDuration': 'Duración',
      'tripDistance': 'Distancia',
      'tripStopsCount': '{n} paradas',
      'tripOverspeedCount': '{n} exceso de velocidad',
      'tripMaxSpeed': 'Velocidad máxima',
      'tripReplay': 'Reproducción',
      'tripViewOnMap': 'Ver en el mapa',
      'tripsNoneDetected': 'No se detectaron trayectos en este período.',
      'tripShort': 'Trayecto corto',
      'tripKm': 'km',
      'tripMin': 'min',
      'tripTimeArrow': '{from} → {to}',
      'tripKmUnit': 'km',
      'tripIgnitionSummary': 'Contacto: {on} ON · {off} OFF',
      'driverScoreLabel': 'Puntuación',
      'driverScoreExcellent': 'Excelente',
      'driverScoreGood': 'Bueno',
      'driverScoreModerate': 'Medio',
      'driverScoreHighRisk': 'Requiere atención',
      'driverScoreUnknown': 'Desconocido',
      'driverScoreNotScorable': 'No evaluado',
      'driverScoreTripTooShort': 'Trayecto demasiado corto',
      'dailyScoreTitle': 'Puntuación de conducción',
      'dailyScorePeriodTitle': 'En este período',
      'dailyScoreNotScorable': 'No evaluado',
      'dailyScoreInsufficientData': 'Datos insuficientes para evaluar este período',
      'dailyScoreTripCount': '{n} trayectos',
      'dailyScoreScorableTrips': '{scored} evaluados · {total} trayectos',
      'dailyScoreTotalDistance': '{km} km en total',
      'dailyScoreOverspeed': '{n} excesos de velocidad',
      'dailyScoreStops': '{n} paradas',
      'dailyScoreBestTrip': 'Mejor trayecto: {name}',
      'dailyScoreWorstTrip': 'Requiere atención: {name}',
      'dailyScoreNoTrips': 'Sin trayectos en este período',
      'dailyScoreDetailsTitle': 'Detalles de la puntuación de conducción',
      'dailyScoreEvaluatedTrips': 'Trayectos evaluados',
      'dailyScoreUnscoredTrips': 'Trayectos sin evaluar',
      'dailyScoreTotalDuration': 'Duración total',
      'dailyScoreTotalStopDuration': 'Duración total en paradas',
      'dailyScoreUnscoredExcludedHint':
          'Los trayectos que no aparecen aquí como evaluados no se incluyen en el promedio del período.',
      'dailyScoreNoEvaluatedTrips': 'No se evaluó ningún trayecto en este período.',
      'dailyScoreTapForDetails': 'Pulsa para ver detalles',
      'dailyScoreBestTripLabel': 'Mejor trayecto',
      'dailyScoreWorstTripLabel': 'Requiere atención',
      'fleetIntelTitle': 'Comportamiento de flota',
      'fleetIntelSubtitle':
          'Resumen ELMOGPS de calidad de conducción (ventana muestral).',
      'fleetIntelScore': 'Puntuación flota',
      'fleetIntelNotScorable': 'Sin evaluar',
      'fleetIntelInsufficientData': 'Datos insuficientes',
      'fleetIntelVehicles': 'Vehículos',
      'fleetIntelActiveVehicles': 'Activos',
      'fleetIntelInactiveVehicles': 'Inactivos',
      'fleetIntelTrips': 'Viajes',
      'fleetIntelDistance': 'Distancia',
      'fleetIntelOverspeed': 'Excesos',
      'fleetIntelStops': 'Paradas',
      'fleetIntelBestVehicle': 'Mejor vehículo',
      'fleetIntelWorstVehicle': 'Requiere seguimiento (menor puntaje)',
      'fleetIntelMostActiveVehicle': 'Más tiempo en marcha',
      'fleetIntelMostOverspeedVehicle': 'Más excesos de velocidad',
      'fleetIntelMostStoppedVehicle': 'Más tiempo detenido',
      'fleetIntelNeedsAttention': 'Requiere seguimiento',
      'fleetIntelRiskDistribution': 'Mezcla de riesgos',
      'fleetIntelNoData': '—',
      'fleetIntelLoading': 'Cargando resumen…',
      'fleetIntelError': 'No se pudo cargar. Desliza para reintentar.',
      'fleetIntelToday': 'Hoy',
      'fleetIntelYesterday': 'Ayer',
      'fleetIntelLast7Days': 'Últimos 7 días',
      'fleetIntelNoTripsInPeriod':
          'Sin viajes en esta ventana para la muestra.',
      'fleetIntelVehicleFallback': 'Vehículo {id}',
      'fleetIntelDrivingDuration': 'Tiempo conduciendo: {value}',
      'fleetIntelStopDuration': 'Tiempo en paradas: {value}',
      'fleetIntelSampleNote':
          '{included}/{total} vehículos · hasta {cap} por actualización (conectados primero).',
      'fleetIntelOpenTrackingTooltip': 'Abrir seguimiento',
      'fleetIntelDrivingTime': 'Tiempo en marcha',
      'fleetIntelPartialRoutes':
          'No se pudieron cargar algunas rutas; el resumen puede estar incompleto.',
      'fleetIntelCustomPeriod': 'Personalizado',
      'fleetIntelRefresh': 'Actualizar',
      'fleetIntelUpdatedAt': 'Actualizado · {time}',
      'fleetIntelPartialData':
          'Algunos indicadores se basan en datos parciales de la flota.',
      'fleetIntelAnalyzedVehicles':
          'Rutas cargadas para {analyzed} de {total} vehículos.',
      'fleetIntelLimitedToVehicles':
          'La plataforma carga hasta {cap} vehículos por análisis para proteger el rendimiento.',
      'fleetAttentionTitle': 'Vehículos a seguir',
      'fleetAttentionNone': 'Ningún vehículo requiere seguimiento en este periodo.',
      'fleetAttentionHighRisk': 'Alto riesgo',
      'fleetAttentionLowScore': 'Puntuación baja',
      'fleetAttentionManyOverspeed': 'Muchos excesos de velocidad',
      'fleetAttentionManyStops': 'Muchas paradas o paradas largas',
      'fleetAttentionInactive': 'Inactivo / sin viajes',
      'fleetAttentionInsufficientData': 'Datos insuficientes',
      'fleetAttentionOpenVehicle': 'Abrir vehículo',
      'fleetAttentionDetailsTitle': 'Seguimiento',
      'fleetAttentionScore': 'Puntuación del periodo',
      'fleetAttentionReasons': 'Por qué aparece este vehículo',
      'fleetAttentionTrips': 'Viajes',
      'fleetAttentionDistance': 'Distancia',
      'fleetAttentionOverspeed': 'Excesos de velocidad',
      'fleetAttentionStops': 'Paradas',
      'fleetAttentionOpenMap': 'Abrir mapa',
      'fleetAttentionOpenTrips': 'Abrir viajes',
      'fleetAttentionNoScore':
          'Sin puntuación en este periodo (no hay viajes suficientemente fiables).',
      'driverScoreDetailsTitle': 'Detalles de la puntuación',
      'driverScoreTripScoredYes': 'Este trayecto sí tiene puntuación',
      'driverScoreTripScoredNo': 'Este trayecto no tiene puntuación',
      'driverScoreFinalScore': 'Puntuación final: {value}',
      'driverScoreBaseScore': 'Puntuación inicial: {value}',
      'driverScoreTotalPenalty': 'Penalizaciones totales: {value}',
      'driverScoreSpeedPenalty': 'Excesos de velocidad',
      'driverScoreStopPenalty': 'Paradas y paradas largas',
      'driverScoreIgnitionPenalty': 'Cambios de contacto',
      'driverScoreEfficiencyPenalty': 'Avance general lento',
      'driverScoreFactorsTitle': 'Qué influyó en esta puntuación',
      'driverScoreReasonOverspeed': 'Momentos por encima del límite',
      'driverScoreReasonHeavyOverspeed': 'Excesos a alta velocidad',
      'driverScoreReasonLongStops': 'Paradas prolongadas',
      'driverScoreReasonExcessiveStops': 'Muchas paradas para la distancia',
      'driverScoreReasonIgnitionTransitions': 'Encendidos/apagados frecuentes',
      'driverScoreReasonLowEfficiency': 'Velocidad media baja con paradas repetidas',
      'driverScoreReasonCleanTrip': 'Sin observaciones destacadas en este trayecto',
      'driverScoreReasonShortTrip':
          'El trayecto es demasiado corto o breve para una puntuación fiable.',
      'driverScoreReliableEnough':
          'El trayecto es suficiente para una puntuación representativa.',
      'driverScoreNotReliableEnough':
          'No puede mostrarse una puntuación justa con los datos disponibles.',
      'driverScoreSteadyDriving':
          'Conducción uniforme — sin penalizaciones destacables.',
      'driverScoreSeverityLow': 'Impacto bajo',
      'driverScoreSeverityMedium': 'Impacto medio',
      'driverScoreSeverityHigh': 'Impacto alto',
      'driverScoreFactorOther': 'Otro factor',
      'driverScorePenaltyLine': '{name}: −{points}',
      'driverScoreFactorOccurrences': '×{n}',
      'routeEventDetailsTitle': 'Detalles del evento',
      'routeEventDetailsStop': 'Parada',
      'routeEventDetailsOverspeed': 'Exceso de velocidad',
      'routeEventDetailsIgnitionOn': 'Contacto encendido',
      'routeEventDetailsIgnitionOff': 'Contacto apagado',
      'routeEventDetailsStartTime': 'Hora de inicio',
      'routeEventDetailsEndTime': 'Hora de fin',
      'routeEventDetailsDuration': 'Duración',
      'routeEventDetailsTime': 'Hora',
      'routeEventDetailsMaxSpeed': 'Velocidad máx.',
      'routeEventDetailsLocation': 'Ubicación',
      'routeEventDetailsRecenter': 'Centrar en el mapa',
      // Replay
      'replayRoute': 'Reproducir ruta',
      'replayPlay': 'Reproducir',
      'replayPause': 'Pausa',
      'replayRestart': 'Reiniciar',
      'replaySpeed': 'Velocidad de reproducción',
      'replayCurrentSpeed': 'Velocidad actual',
      'replayCurrentTime': 'Hora actual',
      'replayRecenter': 'Recentrar',
      'replayVehicleHidden': 'Oculto',
      'replayVehicleNoData': 'Sin datos',
      'replayVehicleActive': 'Activo',
      'replayPlaying': 'Reproduciendo',
      'replayPaused': 'En pausa',
      'replayShowLabels': 'Mostrar etiquetas',
      'replayHideLabels': 'Ocultar etiquetas',
      'replayMapLegend': 'Vehículos',
      'replayPointsCount': '{count} puntos',
      'replayProgress': 'Progreso',
      'loadingReplay': 'Cargando reproducción…',
      'errorLoadingReplay': 'Error al cargar la reproducción.',
      'notEnoughDataForReplay': 'Datos GPS insuficientes para reproducir la ruta.',
      'routeCompleted': 'Ruta finalizada',
      'viewReplay': 'Ver replay',
      'replayMissingGpsData': 'Datos GPS faltantes',
      'replayMissingData': 'Datos faltantes',
      'replayGapsDetected': 'Datos faltantes: {count}',
      'replayGapStartLabel': 'Último punto antes de la brecha',
      'replayGapEndLabel': 'Primer punto después de la brecha',
      'replayGapDurationLabel': 'Duración de la brecha',
      'replayGapsSheetTitle': 'Brechas de datos GPS',
      'replaySnapshotTitle': 'Instantánea actual',
      'replaySnapshotTime': 'Hora',
      'replaySnapshotSpeed': 'Velocidad',
      'replaySnapshotAddress': 'Dirección',
      'replaySnapshotCoordinates': 'Coordenadas',
      'replaySnapshotDirection': 'Rumbo',
      'replaySnapshotIgnition': 'Motor',
      'replaySnapshotEngineOn': 'Motor encendido',
      'replaySnapshotEngineOff': 'Motor apagado',
      'replaySnapshotDetails': 'Detalles',
      'replaySensorsTitle': 'Sensores',
      'replaySensorFuel': 'Combustible',
      'replaySensorBattery': 'Batería',
      'replaySensorGsm': 'Señal GSM',
      'replaySensorSatellites': 'Satélites',
      'replaySensorAccuracy': 'Precisión',
      'replaySensorDriver': 'Conductor',
      'replaySensorUnavailable': 'Valor no disponible',
      'replayAfterDataGap': 'Después de una interrupción de datos',
      'routeEventFilterDataGaps': 'Datos faltantes',
      'routeTimelineStart': 'Inicio',
      'routeTimelineEnd': 'Fin',
      'replayTimelineSummaryStops': '{count} paradas',
      'replayTimelineSummaryOverspeed': '{count} excesos',
      'replayTimelineSummaryDataGaps': '{count} brechas',
      'replayTimelineSummaryIgnition': '{count} motor',
      'routeEventFilterAlerts': 'Alertas',
      'replayExternalEvent': 'Evento',
      'replayExternalAlert': 'Alerta',
      'replayExternalMaintenance': 'Mantenimiento',
      'replayNoAlertsInPeriod': 'No hay alertas en este período',
      'replayEventDetailsType': 'Tipo',
      'replayEventDetailsDescription': 'Descripción',
      'replayExternalPositionUnavailable': 'Posición no disponible',
      'replayStepPrevious': 'Punto anterior',
      'replayStepNext': 'Punto siguiente',
      // Speed chart
      'speedChartTitle': 'Gráfico de velocidad',
      'speedChartMax': 'Velocidad máxima',
      'speedChartAvg': 'Velocidad media',
      'speedChartGpsPoints': 'Puntos GPS',
      'noSpeedData': 'No hay datos de velocidad disponibles.',
      'viewSpeedChart': 'Ver gráfico de velocidad',
      'geofencesTitle': 'Zonas geográficas',
      'geofencesAdd': 'Añadir zona',
      'geofenceEdit': 'Editar zona',
      'geofenceDelete': 'Eliminar zona',
      'geofenceNameLabel': 'Nombre de la zona',
      'geofenceTypeLabel': 'Tipo de zona',
      'geofenceTypeCircle': 'Círculo',
      'geofenceTypePolygon': 'Polígono',
      'geofenceRadius': 'Radio',
      'geofenceLinkedVehicles': 'Vehículos asociados',
      'geofenceAlertSectionTitle': 'Alertas de entrada/salida',
      'geofenceZoneEntry': 'Entrada a zona',
      'geofenceZoneExit': 'Salida de zona',
      'geofenceShowOnMap': 'Mostrar zonas',
      'geofenceTapMapCenter': 'Toque el mapa para definir el centro',
      'geofencePolygonMinPoints': 'Añada al menos 3 puntos',
      'geofenceCreated': 'Zona creada correctamente',
      'geofenceUpdated': 'Zona actualizada',
      'geofenceDeleted': 'Zona eliminada',
      'geofenceLoadError': 'Error al cargar zonas',
      'geofenceAlertStatusOn': 'Alertas activas',
      'geofenceAlertStatusOff': 'Sin alertas',
      'geofenceSearchHint': 'Buscar por nombre',
      'geofenceFilterAllTypes': 'Todos los tipos',
      'geofenceDeleteTitle': 'Eliminar zona',
      'geofenceDeleteMessage': 'La zona se eliminará de forma permanente.',
      'geofenceDeleteWarningWithVehicles':
          'Esta zona está vinculada a {n} vehículo(s). Se eliminará de todas formas.',
      'geofencesEmptyTitle': 'Sin zonas',
      'geofencesEmptyMessage': 'Añada una zona para verla en el mapa y recibir alertas.',
      'geofenceColorLabel': 'Color',
      'geofenceTapMapCenterHint': 'Toque el mapa para definir el centro',
      'geofencePolygonTapHint': 'Toque el mapa para añadir vértices',
      'geofencePolygonUndoLast': 'Quitar último punto',
      'geofenceNotifyEnter': 'Crear alerta de entrada',
      'geofenceNotifyExit': 'Crear alerta de salida',
      'geofenceNotifyBoth': 'Crear ambas',
      'geofenceNoVehiclesLinked': 'Ningún vehículo seleccionado',
      'geofenceVehiclesSelectedCount': '{n} vehículo(s) seleccionado(s)',
      'geofenceVehiclesClear': 'Limpiar',
      'geofenceDetailsTitle': 'Detalles de la zona',
      'geofenceNotFound': 'Zona no encontrada',
      'driversTitle': 'Conductores',
      'driversAdd': 'Añadir conductor',
      'driversEdit': 'Editar conductor',
      'driversDelete': 'Eliminar conductor',
      'driversSearchHint': 'Buscar por nombre o código',
      'driversEmptyTitle': 'Sin conductores',
      'driversEmptyMessage': 'Agregue conductores para enlazarlos a vehículos.',
      'driverDetailTitle': 'Detalle del conductor',
      'driverNameLabel': 'Nombre del conductor',
      'driverCodeLabel': 'Código del conductor',
      'driverPhoneLabel': 'Teléfono',
      'drivingLicenseLabel': 'Licencia de conducir',
      'licenseExpiryLabel': 'Fecha de vencimiento de la licencia',
      'driversLinkedVehicles': 'Vehículos asociados',
      'driverNotesLabel': 'Notas',
      'driversSave': 'Guardar',
      'driversDeleteConfirmTitle': 'Eliminar conductor',
      'driversDeleteConfirmBody': 'Este conductor se eliminará de forma permanente.',
      'driversLoadError': 'No se pueden cargar conductores',
      'driversSelectVehiclesHint': 'Seleccionar vehículos de la flota.',
      'licenseStatusUnknown': 'Estado desconocido',
      'licenseStatusValid': 'Licencia válida',
      'licenseStatusSoon': 'Licencia por vencer',
      'licenseStatusExpired': 'Licencia vencida',
      'maintenanceTitle': 'Mantenimiento',
      'maintenanceAdd': 'Añadir mantenimiento',
      'maintenanceEdit': 'Editar mantenimiento',
      'maintenanceDelete': 'Eliminar mantenimiento',
      'maintenanceDetailTitle': 'Detalle de mantenimiento',
      'maintenanceSearchHint': 'Buscar mantenimiento',
      'maintenanceFilterAll': 'Todos los vehículos',
      'maintenanceFilterVehicle': 'Filtrar por vehículo',
      'maintenanceLoadError': 'No se pueden cargar mantenimientos',
      'maintenanceEmptyTitle': 'Sin mantenimiento',
      'maintenanceEmptyMessage': 'Planifique trabajos y fechas aquí mismo.',
      'maintenanceTypeLabelField': 'Tipo de mantenimiento',
      'maintenanceDueDateLabel': 'Fecha de vencimiento',
      'maintenanceDueOdometerLabel': 'Kilometraje de vencimiento',
      'maintenanceMarkCompletedHint': 'Marcar terminado',
      'maintenanceDeleteConfirmTitle': 'Eliminar mantenimiento',
      'maintenanceDeleteConfirmBody': '¿Eliminar esta ficha?',
      'maintStatusUnknown': 'Desconocido',
      'maintStatusCompleted': 'Completado',
      'maintStatusUpcoming': 'Próximo',
      'maintStatusSoon': 'Pronto',
      'maintStatusOverdue': 'Vencido',
      'maintType_oil_change': 'Cambio de aceite',
      'maintType_oil_filter': 'Filtro de aceite',
      'maintType_air_filter': 'Filtro de aire',
      'maintType_tires': 'Neumáticos',
      'maintType_brakes': 'Frenos',
      'maintType_battery': 'Batería',
      'maintType_draining': 'Drenaje/aceites',
      'maintType_general_revision': 'Servicio integral',
      'maintType_insurance': 'Seguro',
      'maintType_technical_inspection': 'Inspección técnica',
      'maintType_vignette': 'Vignete / impuesto vial',
      'maintType_other': 'Otros',
      'fleetCardNoDriver': 'Sin conductor asignado',
      'fleetCardDriverAssigned': 'Conductor {name}',
      'fleetCardNoMaintenance': 'Sin mantenimiento',
      'fleetCardMaintenanceSnippet': 'Mantenimiento • {snippet}',
      'fleetCardSummaryStoppedFor': 'Detenido {duration}',
      'fleetCardSummaryIdleFor': 'Inactivo {duration}',
      'fleetCardSummaryEngineOffFor': 'Motor apagado {duration}',
      'fleetCardLastMovement': 'Último movimiento: {time}',
      'fleetCardLastIgnition': 'Último encendido: {time}',
      'fleetCardEngineOffSince': 'Motor apagado desde {duration}',
      'fleetCardLastPosition': 'Última posición: {address}',
      'fleetCardLastData': 'Últimos datos: {time}',
      'fleetCardAlertNoRecentData': 'Sin datos recientes',
      'fleetCardAlertOfflineLong': 'Sin conexión {duration}',
      'fleetCardAlertOfflineSince': 'Sin conexión desde {time}',
      'fleetCardAlertStaleData': 'Datos antiguos ({time})',
      'fleetCardAlertLowBattery': 'Batería baja ({voltage})',
      'fleetCardAlertBatteryAttention': 'Revisar batería ({voltage})',
      'fleetCardAlertLowFuel': 'Combustible bajo ({level})',
      'relativeJustNow': 'Ahora',
      'relativeMinutesAgo': 'hace {n} min',
      'relativeHoursAgo': 'hace {n} h',
      'relativeDaysAgo': 'hace {n} d',
      'relativeYesterdayAt': 'ayer {time}',
      'relativeDateAt': '{date} {time}',
      'fleetStatsLastSyncNow': 'Última sincronización: ahora',
      'fleetSectionDocuments': 'Documentos',
      'fleetDocInsuranceLabel': 'Seguro',
      'fleetDocInspectionLabel': 'Inspección técnica',
      'fleetAlertMaintSoonTitle': 'Mantenimiento próximo',
      'fleetAlertMaintSoonDesc': '{vehicle}: "{task}" vence pronto.',
      'fleetAlertMaintOverdueTitle': 'Mantenimiento vencido',
      'fleetAlertMaintOverdueDesc': '{vehicle}: "{task}" atrasado.',
      'fleetAlertInsuranceSoonTitle': 'Seguro por vencer',
      'fleetAlertInsuranceSoonDesc': '{vehicle}: el contrato llega su plazo.',
      'fleetAlertInsuranceExpiredTitle': 'Seguro caducado',
      'fleetAlertInsuranceExpiredDesc': '{vehicle}: seguro vencido.',
      'fleetAlertTechSoonTitle': 'Inspección técnica cercana',
      'fleetAlertTechSoonDesc': '{vehicle}: ITV próximo vencimiento.',
      'fleetAlertTechExpiredTitle': 'Inspección técnica vencida',
      'fleetAlertTechExpiredDesc': '{vehicle}: ITV vencida.',
      'fleetAlertLicenseSoonTitle': 'Licencia cercana al vencimiento',
      'fleetAlertLicenseSoonDesc': '{name}: revise la caducidad de la licencia.',
      'fleetAlertLicenseExpiredTitle': 'Licencia vencida',
      'fleetAlertLicenseExpiredDesc': '{name}: licencia expirada.',
      'reportFleetMaintenanceSoon':
          'Informe de mantenimiento — Disponible próximamente',
      'reportFleetDriversSoon':
          'Informe de conductores — Disponible próximamente',
      'fleetIntelligenceTitle': 'Inteligencia de flota',
      'fleetIntelligenceDashboardSubtitle': 'Indicadores y estado en vivo',
      'vehiclesOnline': 'En línea',
      'kpiDriversTotal': 'Conductores',
      'kpiDriversActive': 'Conductores activos',
      'maintenanceOverdueVehicles': 'Vehículos — mantenimiento vencido',
      'insufficientData': 'Datos insuficientes',
      'companyManagement': 'Gestión de empresas',
      'distributors': 'Distribuidores',
      'companyManagementHint':
          'La gestión de empresas y distribuidores se añadirá en una fase dedicada.',
      'utilizationScore': 'Puntuación de uso',
      'mostActiveVehicles': 'Vehículos más activos',
      'leastActiveVehicles': 'Menos activos / inactivos',
      'driversToWatch': 'Conductores a vigilar',
      'vehicleActivitySection': 'Actividad de vehículos',
      'driverRankingSection': 'Clasificación de conductores',
      'maintenanceOverviewSection': 'Resumen de mantenimiento',
      'alertsOverviewSection': 'Resumen de alertas',
      'vehicleUtilizationSection': 'Uso de vehículos',
      'maintenanceUpcomingCount': 'Próximas',
      'maintenanceSoonCount': 'Pronto',
      'maintenanceOverdueCount': 'Atrasadas (registros)',
      'nextMaintenances': 'Próximos mantenimientos',
      'alertsTotalPeriod': 'Total (importantes)',
      'alertsOverspeed': 'Exceso de velocidad',
      'alertsGeofence': 'Entrada/salida de zona',
      'alertsOnlineOffline': 'En línea / fuera de línea (eventos)',
      'lastImportantEvents': 'Eventos importantes recientes',
      'periodTotalDistance': 'Distancia del período',
      'vehiclesActiveInPeriod': 'Vehículos con trayectos',
      'fleetIntelLiveStatusHint':
          'El estado (en movimiento / detenidos / ralentí / fuera de línea) refleja la flota en tiempo real.',
      'exportDashboardReport': 'Exportar informe del panel',
      'driverRankEstimatedNote':
          'Clasificación aproximada según trayectos/eventos de los vehículos asignados al conductor.',
      'notAvailable': 'No disponible',
      'fleetStatusProblem': 'Requiere seguimiento',
      'adminDashboardLoadError': 'No se pudo cargar el panel.',
      'adminDashboardTripsPartialError':
          'No se pudieron cargar trayectos/eventos para este período. Otras secciones siguen disponibles.',
      'dashboardConnectionLive': 'En directo',
      'dashboardConnectionReconnecting': 'Reconectando',
      'dashboardConnectionOverview': 'Fuera de línea',
      'dashboardConnectionDegraded': 'Conectado · Sincronización retrasada',
      'dashboardConnectionLiveReconnecting': 'Reconectando en vivo…',
      'dashboardConnectionOffline': 'Fuera de línea',
      'dashboardConnectionServerUnavailable': 'Servidor no disponible',
      'dashboardConnectionSessionExpired': 'Sesión expirada',
      'dashboardConnectionChecking': 'Conectando…',
      'dashboardSyncInProgress': 'Sincronizando…',
      'dashboardDistanceQuietHint':
          'La distancia se actualizará cuando los vehículos comiencen a moverse.',
      'dashboardNoActivityToday': 'No hay actividad detectada hoy.',
      'dashboardNoActivityPeriod': 'No hay actividad en este período.',
      'dashboardViewFullFleet': 'Ver toda la flota',
      'dashboardNoUrgentMaintenance': 'Sin mantenimiento urgente.',
      'dashboardNoImportantAlerts': 'Sin alertas importantes.',
      'dashboardImportantAlertsLabel': 'Alertas importantes',
      'dashboardVehicleActivityEmpty':
          'No hay vehículos activos en este período.',
      'licenseAttentionTitle': 'Licencia — requiere seguimiento',
      'fleetEvtOverspeed': 'Exceso de velocidad',
      'fleetEvtGeofenceIn': 'Entrada de zona',
      'fleetEvtGeofenceOut': 'Salida de zona',
      'fleetEvtOffline': 'Fuera de línea',
      'fleetEvtOnline': 'En línea',
      'fleetEvtAlarm': 'Alarma',
      'fleetEvtIgnitionOn': 'Encendido',
      'fleetEvtIgnitionOff': 'Apagado',
      'fleetEvtMaintenance': 'Mantenimiento',
      'validationRequired': 'Campo obligatorio',
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
