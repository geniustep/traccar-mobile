import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../trips/domain/entities/trip.dart';
import '../../domain/entities/event_report.dart';
import '../../domain/entities/stop_report.dart';
import '../../domain/entities/summary_report.dart';

// ── Colour palette (matches AppColors.accent = 0xFF00B4D8) ────────────────────
const _kAccent = PdfColor.fromInt(0xFF00B4D8);
const _kAccentLight = PdfColor.fromInt(0xFFE0F7FA);
const _kDark = PdfColor.fromInt(0xFF0D1B2A);
const _kGrey = PdfColor.fromInt(0xFF546E7A);
const _kLightGrey = PdfColor.fromInt(0xFFF5F7F9);
const _kWhite = PdfColors.white;
const _kDivider = PdfColor.fromInt(0xFFCFD8DC);

// ── Number / date formatters ───────────────────────────────────────────────────
final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
final _shortDateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
final _timeFmt = DateFormat('HH:mm', 'fr_FR');
final _numFmt = NumberFormat('#,##0.0', 'fr_FR');

class ReportPdfService {
  // ── Public API ───────────────────────────────────────────────────────────────

  Future<String> generateSummaryPdf({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    required SummaryReport summary,
  }) =>
      _generate(
        vehicleName: vehicleName,
        from: from,
        to: to,
        summary: summary,
      );

  Future<String> generateTripsPdf({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    required List<TripEntity> trips,
  }) =>
      _generate(
        vehicleName: vehicleName,
        from: from,
        to: to,
        trips: trips,
      );

  Future<String> generateStopsPdf({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    required List<StopReport> stops,
  }) =>
      _generate(
        vehicleName: vehicleName,
        from: from,
        to: to,
        stops: stops,
      );

  Future<String> generateEventsPdf({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    required List<EventReport> events,
  }) =>
      _generate(
        vehicleName: vehicleName,
        from: from,
        to: to,
        events: events,
      );

  Future<String> generateFullReportPdf({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    SummaryReport? summary,
    List<TripEntity>? trips,
    List<StopReport>? stops,
    List<EventReport>? events,
  }) =>
      _generate(
        vehicleName: vehicleName,
        from: from,
        to: to,
        summary: summary,
        trips: trips,
        stops: stops,
        events: events,
      );

  // ── Core generator ───────────────────────────────────────────────────────────

  Future<String> _generate({
    required String vehicleName,
    required DateTime from,
    required DateTime to,
    SummaryReport? summary,
    List<TripEntity>? trips,
    List<StopReport>? stops,
    List<EventReport>? events,
  }) async {
    final doc = pw.Document(
      title: 'Rapport ELMOGPS — $vehicleName',
      author: 'ELMOGPS',
      creator: 'elmogps.com',
    );

    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final obliqueFont = pw.Font.helveticaOblique();

    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: obliqueFont,
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(ctx, vehicleName, from, to, boldFont),
        footer: (ctx) => _buildFooter(ctx, baseFont),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          if (summary != null) ..._summarySection(summary, boldFont, baseFont),
          if (trips != null && trips.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            ..._tripsSection(trips, boldFont, baseFont),
          ],
          if (stops != null && stops.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            ..._stopsSection(stops, boldFont, baseFont),
          ],
          if (events != null && events.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            ..._eventsSection(events, boldFont, baseFont),
          ],
          if (summary == null &&
              (trips == null || trips.isEmpty) &&
              (stops == null || stops.isEmpty) &&
              (events == null || events.isEmpty))
            _emptySection(baseFont),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final filename =
        'elmogps_${vehicleName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Context ctx,
    String vehicleName,
    DateTime from,
    DateTime to,
    pw.Font boldFont,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _kDark,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ELMOGPS — Rapport de Flotte',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 13,
                  color: _kAccent,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Véhicule : $vehicleName',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: _kWhite,
                ),
              ),
              pw.Text(
                'Période : ${_shortDateFmt.format(from)}  →  ${_shortDateFmt.format(to)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blueGrey200,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Généré le',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey200),
              ),
              pw.Text(
                _dateFmt.format(DateTime.now()),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: _kWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx, pw.Font baseFont) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _kDivider, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(font: baseFont, fontSize: 8, color: _kGrey),
          ),
          pw.Text(
            'elmogps.com',
            style: pw.TextStyle(font: baseFont, fontSize: 8, color: _kGrey),
          ),
        ],
      ),
    );
  }

  // ── Section header helper ────────────────────────────────────────────────────

  pw.Widget _sectionTitle(String title, pw.Font boldFont) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _kAccentLight,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 11,
          color: _kDark,
        ),
      ),
    );
  }

  // ── Summary section ──────────────────────────────────────────────────────────

  List<pw.Widget> _summarySection(
    SummaryReport s,
    pw.Font boldFont,
    pw.Font baseFont,
  ) {
    final items = <_KV>[
      _KV('Distance totale', '${_numFmt.format(s.totalDistanceKm)} km'),
      _KV('Temps moteur', _formatDuration(s.engineDuration)),
      _KV('Vitesse maximale', '${_numFmt.format(s.maxSpeedKmh)} km/h'),
      _KV('Vitesse moyenne', '${_numFmt.format(s.averageSpeedKmh)} km/h'),
      if (s.spentFuel > 0)
        _KV('Carburant consommé', '${_numFmt.format(s.spentFuel)} L'),
    ];

    return [
      _sectionTitle('Résumé', boldFont),
      pw.SizedBox(height: 6),
      pw.Wrap(
        spacing: 8,
        runSpacing: 6,
        children: items
            .map((kv) => _kpiCard(kv.key, kv.value, boldFont, baseFont))
            .toList(),
      ),
    ];
  }

  pw.Widget _kpiCard(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font baseFont,
  ) {
    return pw.Container(
      width: 120,
      decoration: const pw.BoxDecoration(
        color: _kLightGrey,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.fromBorderSide(pw.BorderSide(color: _kDivider, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: baseFont, fontSize: 8, color: _kGrey),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont, fontSize: 11, color: _kDark),
          ),
        ],
      ),
    );
  }

  // ── Trips section ────────────────────────────────────────────────────────────

  List<pw.Widget> _tripsSection(
    List<TripEntity> trips,
    pw.Font boldFont,
    pw.Font baseFont,
  ) {
    final headers = ['N°', 'Début', 'Fin', 'Durée', 'Distance', 'Vit. max'];
    final rows = trips.asMap().entries.map((e) {
      final i = e.key + 1;
      final t = e.value;
      return [
        '$i',
        _dateFmt.format(t.startTime),
        t.endTime != null ? _dateFmt.format(t.endTime!) : '—',
        _formatDuration(Duration(seconds: t.durationSeconds)),
        '${_numFmt.format(t.distanceMeters / 1000)} km',
        '${_numFmt.format(t.maxSpeedKmh)} km/h',
      ];
    }).toList();

    return [
      _sectionTitle('Trajets (${trips.length})', boldFont),
      pw.SizedBox(height: 6),
      _buildTable(headers, rows, boldFont, baseFont),
    ];
  }

  // ── Stops section ────────────────────────────────────────────────────────────

  List<pw.Widget> _stopsSection(
    List<StopReport> stops,
    pw.Font boldFont,
    pw.Font baseFont,
  ) {
    final headers = ['N°', 'Début', 'Fin', 'Durée', 'Lieu'];
    final rows = stops.asMap().entries.map((e) {
      final i = e.key + 1;
      final s = e.value;
      return [
        '$i',
        _dateFmt.format(s.startTime),
        s.endTime != null ? _dateFmt.format(s.endTime!) : '—',
        _formatDuration(s.duration),
        s.address ?? '${s.lat.toStringAsFixed(4)}, ${s.lng.toStringAsFixed(4)}',
      ];
    }).toList();

    return [
      _sectionTitle('Arrêts (${stops.length})', boldFont),
      pw.SizedBox(height: 6),
      _buildTable(headers, rows, boldFont, baseFont),
    ];
  }

  // ── Events section ───────────────────────────────────────────────────────────

  List<pw.Widget> _eventsSection(
    List<EventReport> events,
    pw.Font boldFont,
    pw.Font baseFont,
  ) {
    return [
      _sectionTitle('Événements (${events.length})', boldFont),
      pw.SizedBox(height: 6),
      ...events.asMap().entries.map((e) {
        final idx = e.key;
        final ev = e.value;
        final bg = idx.isEven ? _kLightGrey : _kWhite;
        return pw.Container(
          color: bg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 90,
                child: pw.Text(
                  _timeFmt.format(ev.eventTime),
                  style: pw.TextStyle(font: baseFont, fontSize: 8, color: _kGrey),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  ev.labelFr,
                  style: pw.TextStyle(font: boldFont, fontSize: 9, color: _kDark),
                ),
              ),
              if (ev.speedKmh != null)
                pw.Text(
                  '${_numFmt.format(ev.speedKmh!)} km/h',
                  style: pw.TextStyle(font: baseFont, fontSize: 8, color: _kGrey),
                ),
            ],
          ),
        );
      }),
    ];
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  pw.Widget _emptySection(pw.Font baseFont) {
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 32),
        child: pw.Text(
          'Aucune donnée disponible pour cette période.',
          style: pw.TextStyle(font: baseFont, fontSize: 11, color: _kGrey),
        ),
      ),
    );
  }

  // ── Table builder ────────────────────────────────────────────────────────────

  pw.Widget _buildTable(
    List<String> headers,
    List<List<String>> rows,
    pw.Font boldFont,
    pw.Font baseFont,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: null,
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 8, color: _kWhite),
      headerDecoration: const pw.BoxDecoration(color: _kDark),
      cellStyle: pw.TextStyle(font: baseFont, fontSize: 8, color: _kDark),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      rowDecoration: const pw.BoxDecoration(color: _kWhite),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  // ── Duration formatter ───────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    if (d.inSeconds == 0) return '0 min';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }
}

// ── Simple key-value helper ───────────────────────────────────────────────────

class _KV {
  const _KV(this.key, this.value);
  final String key;
  final String value;
}
