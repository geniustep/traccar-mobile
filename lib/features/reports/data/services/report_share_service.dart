import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/summary_report.dart';
import '../../../trips/domain/entities/trip.dart';

final _shortDateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
final _numFmt = NumberFormat('#,##0.0', 'fr_FR');

class ReportShareService {
  /// Opens the system share sheet for a PDF file.
  Future<void> sharePdf(
    String filePath, {
    String? subject,
    String? message,
  }) async {
    final file = XFile(filePath, mimeType: 'application/pdf');
    await Share.shareXFiles(
      [file],
      subject: subject ?? 'Rapport ELMOGPS',
      text: message,
    );
  }

  /// Shares a compact text summary (suitable for WhatsApp / SMS).
  Future<void> shareTextSummary({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    SummaryReport? summary,
    List<TripEntity>? trips,
  }) async {
    final buf = StringBuffer();
    buf.writeln('📊 Rapport ELMOGPS');
    buf.writeln('🚗 Véhicule: $vehicleName');
    buf.writeln('📅 Période: ${_shortDateFmt.format(from)} → ${_shortDateFmt.format(to)}');
    buf.writeln();

    if (summary != null) {
      buf.writeln('📍 Distance totale: ${_numFmt.format(summary.totalDistanceKm)} km');
      buf.writeln('⏱️ Temps moteur: ${_fmtDuration(summary.engineDuration)}');
      buf.writeln('🚀 Vitesse max: ${_numFmt.format(summary.maxSpeedKmh)} km/h');
      buf.writeln('📈 Vitesse moyenne: ${_numFmt.format(summary.averageSpeedKmh)} km/h');
      if (summary.spentFuel > 0) {
        buf.writeln('⛽ Carburant: ${_numFmt.format(summary.spentFuel)} L');
      }
    }

    if (trips != null && trips.isNotEmpty) {
      buf.writeln('🔢 Trajets: ${trips.length}');
    }

    buf.writeln();
    buf.write('Généré par ELMOGPS — elmogps.com');

    await Share.share(buf.toString(), subject: 'Rapport ELMOGPS — $vehicleName');
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds == 0) return '0 min';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }
}
