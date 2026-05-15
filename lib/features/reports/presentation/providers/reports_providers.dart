import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../data/services/report_pdf_service.dart';
import '../../data/services/report_share_service.dart';
import '../../domain/entities/summary_report.dart';
import '../../domain/entities/stop_report.dart';
import '../../domain/entities/event_report.dart';
import '../../domain/repositories/reports_repository.dart';

// ── Filter state ──────────────────────────────────────────────────────────────

enum ReportPeriod { today, yesterday, thisWeek, thisMonth, custom }

extension ReportPeriodLabel on ReportPeriod {
  /// Localized label for UI display.
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        ReportPeriod.today => l10n.periodToday,
        ReportPeriod.yesterday => l10n.periodYesterday,
        ReportPeriod.thisWeek => l10n.periodThisWeek,
        ReportPeriod.thisMonth => l10n.periodThisMonth,
        ReportPeriod.custom => l10n.periodCustom,
      };

  /// @deprecated Use [localizedLabel] instead.
  String get labelFr => switch (this) {
        ReportPeriod.today => "Aujourd'hui",
        ReportPeriod.yesterday => 'Hier',
        ReportPeriod.thisWeek => 'Cette semaine',
        ReportPeriod.thisMonth => 'Ce mois',
        ReportPeriod.custom => 'Personnalisé',
      };
}

class ReportFilterState {
  const ReportFilterState({
    this.vehicleId,
    this.vehicleName = '',
    this.period = ReportPeriod.today,
    required this.from,
    required this.to,
    this.hasGenerated = false,
  });

  final String? vehicleId;
  final String vehicleName;
  final ReportPeriod period;
  final DateTime from;
  final DateTime to;

  /// True once the user has pressed "Générer" at least once.
  final bool hasGenerated;

  bool get canGenerate => vehicleId != null && vehicleId!.isNotEmpty;

  ReportFilterParams? get params => canGenerate
      ? ReportFilterParams(
          vehicleId: vehicleId!,
          from: from.toUtc(),
          to: to.toUtc(),
        )
      : null;

  ReportFilterState copyWith({
    String? vehicleId,
    String? vehicleName,
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    bool? hasGenerated,
  }) =>
      ReportFilterState(
        vehicleId: vehicleId ?? this.vehicleId,
        vehicleName: vehicleName ?? this.vehicleName,
        period: period ?? this.period,
        from: from ?? this.from,
        to: to ?? this.to,
        hasGenerated: hasGenerated ?? this.hasGenerated,
      );

  static ReportFilterState initial() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return ReportFilterState(from: todayStart, to: now);
  }
}

/// Immutable key used as [FutureProvider.family] parameter.
/// Equals / hashCode are required for Riverpod family caching.
class ReportFilterParams {
  const ReportFilterParams({
    required this.vehicleId,
    required this.from,
    required this.to,
  });

  final String vehicleId;
  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is ReportFilterParams &&
      other.vehicleId == vehicleId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(vehicleId, from, to);
}

// ── Filter notifier ───────────────────────────────────────────────────────────

class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier() : super(ReportFilterState.initial());

  void setVehicle(String id, String name) {
    state = state.copyWith(vehicleId: id, vehicleName: name);
  }

  void setPeriod(ReportPeriod period) {
    final now = DateTime.now();
    late DateTime from;
    late DateTime to;

    switch (period) {
      case ReportPeriod.today:
        from = DateTime(now.year, now.month, now.day);
        to = now;
      case ReportPeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        from = DateTime(yesterday.year, yesterday.month, yesterday.day);
        to = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      case ReportPeriod.thisWeek:
        final daysFromMonday = now.weekday - 1;
        from = DateTime(now.year, now.month, now.day - daysFromMonday);
        to = now;
      case ReportPeriod.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = now;
      case ReportPeriod.custom:
        // Keep existing from/to when switching to custom
        from = state.from;
        to = state.to;
    }

    state = state.copyWith(period: period, from: from, to: to);
  }

  void setFrom(DateTime from) {
    state = state.copyWith(
      period: ReportPeriod.custom,
      from: from,
      to: from.isAfter(state.to) ? from.add(const Duration(hours: 1)) : state.to,
    );
  }

  void setTo(DateTime to) {
    state = state.copyWith(
      period: ReportPeriod.custom,
      to: to,
      from: to.isBefore(state.from) ? to.subtract(const Duration(hours: 1)) : state.from,
    );
  }

  void generate() {
    state = state.copyWith(hasGenerated: true);
  }
}

// ── Entry params (for pre-filling from Vehicle Details) ──────────────────────

class ReportsEntryParams {
  const ReportsEntryParams({
    required this.vehicleId,
    required this.vehicleName,
    required this.period,
    required this.from,
    required this.to,
    this.tabIndex = 0,
  });

  final String vehicleId;
  final String vehicleName;
  final ReportPeriod period;
  final DateTime from;
  final DateTime to;
  final int tabIndex;
}

// ── Repository / datasource providers ────────────────────────────────────────

final reportsDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  return ReportsRemoteDataSource(ref.read(traccarClientProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.read(reportsDataSourceProvider));
});

// ── Filter provider ───────────────────────────────────────────────────────────

final reportFilterProvider =
    StateNotifierProvider.autoDispose<ReportFilterNotifier, ReportFilterState>(
  (ref) => ReportFilterNotifier(),
);

// ── Data providers ────────────────────────────────────────────────────────────

final summaryReportProvider = FutureProvider.autoDispose
    .family<SummaryReport?, ReportFilterParams>((ref, params) {
  return ref.read(reportsRepositoryProvider).getSummary(
        deviceId: params.vehicleId,
        from: params.from,
        to: params.to,
      );
});

final stopsReportProvider = FutureProvider.autoDispose
    .family<List<StopReport>, ReportFilterParams>((ref, params) {
  return ref.read(reportsRepositoryProvider).getStops(
        deviceId: params.vehicleId,
        from: params.from,
        to: params.to,
      );
});

final eventsReportProvider = FutureProvider.autoDispose
    .family<List<EventReport>, ReportFilterParams>((ref, params) {
  return ref.read(reportsRepositoryProvider).getEvents(
        deviceId: params.vehicleId,
        from: params.from,
        to: params.to,
      );
});

final reportTripsProvider = FutureProvider.autoDispose
    .family<List<TripEntity>, ReportFilterParams>((ref, params) {
  return ref.read(reportsRepositoryProvider).getTrips(
        deviceId: params.vehicleId,
        from: params.from,
        to: params.to,
      );
});

final reportRouteProvider = FutureProvider.autoDispose
    .family<List<RoutePoint>, ReportFilterParams>((ref, params) {
  return ref.read(reportsRepositoryProvider).getRoute(
        deviceId: params.vehicleId,
        from: params.from,
        to: params.to,
      );
});

// ── Service providers ─────────────────────────────────────────────────────────

final reportPdfServiceProvider = Provider<ReportPdfService>((ref) {
  return ReportPdfService();
});

final reportShareServiceProvider = Provider<ReportShareService>((ref) {
  return ReportShareService();
});

// ── PDF generation state ──────────────────────────────────────────────────────

enum PdfGenStatus { idle, loading, success, error }

class PdfGenerationState {
  const PdfGenerationState({
    this.status = PdfGenStatus.idle,
    this.filePath,
    this.errorMessage,
  });

  final PdfGenStatus status;
  final String? filePath;
  final String? errorMessage;

  bool get isLoading => status == PdfGenStatus.loading;
  bool get isSuccess => status == PdfGenStatus.success;
  bool get isError => status == PdfGenStatus.error;

  PdfGenerationState copyWith({
    PdfGenStatus? status,
    String? filePath,
    String? errorMessage,
  }) =>
      PdfGenerationState(
        status: status ?? this.status,
        filePath: filePath ?? this.filePath,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class PdfGenerationNotifier extends StateNotifier<PdfGenerationState> {
  PdfGenerationNotifier(this._pdfService) : super(const PdfGenerationState());

  final ReportPdfService _pdfService;

  Future<String?> generateFull({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    SummaryReport? summary,
    List<TripEntity>? trips,
    List<StopReport>? stops,
    List<EventReport>? events,
  }) async {
    state = const PdfGenerationState(status: PdfGenStatus.loading);
    try {
      final path = await _pdfService.generateFullReportPdf(
        vehicleName: vehicleName,
        from: from,
        to: to,
        summary: summary,
        trips: trips,
        stops: stops,
        events: events,
      );
      state = PdfGenerationState(status: PdfGenStatus.success, filePath: path);
      return path;
    } catch (e) {
      state = PdfGenerationState(
        status: PdfGenStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void reset() => state = const PdfGenerationState();
}

final pdfGenerationProvider = StateNotifierProvider.autoDispose<
    PdfGenerationNotifier, PdfGenerationState>((ref) {
  return PdfGenerationNotifier(ref.read(reportPdfServiceProvider));
});
