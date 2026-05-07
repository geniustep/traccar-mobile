import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../domain/entities/summary_report.dart';
import '../../domain/entities/stop_report.dart';
import '../../domain/entities/event_report.dart';
import '../providers/reports_providers.dart';
import 'pdf_preview_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReportsScreen — main entry point
// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabCount = 5;

  List<String> _buildTabLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.reportsSummary,
      l10n.reportsRoute,
      l10n.reportsTrips,
      l10n.reportsStops,
      l10n.reportsEvents,
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        centerTitle: false,
        actions: [
          _PdfButton(filter: filter),
          _ShareButton(filter: filter),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondaryOf(context),
          labelStyle: AppTextStyles.labelMedium,
          tabs: _buildTabLabels(context).map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ─────────────────────────────────────────────────────
          _ReportFilterBar(
            filter: filter,
            onVehicleSelected: (id, name) =>
                ref.read(reportFilterProvider.notifier).setVehicle(id, name),
            onPeriodSelected: (p) =>
                ref.read(reportFilterProvider.notifier).setPeriod(p),
            onFromPicked: (dt) =>
                ref.read(reportFilterProvider.notifier).setFrom(dt),
            onToPicked: (dt) =>
                ref.read(reportFilterProvider.notifier).setTo(dt),
            onGenerate: () =>
                ref.read(reportFilterProvider.notifier).generate(),
          ),

          // ── Tabs ───────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(filter: filter),
                _RouteTab(filter: filter),
                _TripsTab(filter: filter),
                _StopsTab(filter: filter),
                _EventsTab(filter: filter),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// PDF export button (AppBar action)
// ─────────────────────────────────────────────────────────────────────────────

class _PdfButton extends ConsumerWidget {
  const _PdfButton({required this.filter});
  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfState = ref.watch(pdfGenerationProvider);
    final l10n = AppLocalizations.of(context);

    if (pdfState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.picture_as_pdf_outlined),
      tooltip: l10n.exportPdf,
      onPressed: filter.hasGenerated ? () => _exportPdf(context, ref) : null,
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(reportFilterProvider);
    final params = filter.params;
    if (params == null) return;

    // Collect already-loaded data from existing providers (no extra network call).
    final summaryAsync = ref.read(summaryReportProvider(params));
    final tripsAsync = ref.read(reportTripsProvider(params));
    final stopsAsync = ref.read(stopsReportProvider(params));
    final eventsAsync = ref.read(eventsReportProvider(params));

    final summary = summaryAsync.valueOrNull;
    final trips = tripsAsync.valueOrNull;
    final stops = stopsAsync.valueOrNull;
    final events = eventsAsync.valueOrNull;

    final path = await ref.read(pdfGenerationProvider.notifier).generateFull(
          vehicleName: filter.vehicleName,
          from: filter.from,
          to: filter.to,
          summary: summary,
          trips: trips,
          stops: stops,
          events: events,
        );

    if (path == null) {
      if (context.mounted) {
        final errMsg = ref.read(pdfGenerationProvider).errorMessage ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).pdfError}: $errMsg'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            title: '${AppLocalizations.of(context).exportPdfLabel} — ${filter.vehicleName}',
            filePath: path,
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share button (AppBar action)
// ─────────────────────────────────────────────────────────────────────────────

class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.filter});
  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.share_outlined),
      tooltip: l10n.shareReport,
      onPressed: filter.hasGenerated ? () => _showShareSheet(context, ref) : null,
    );
  }

  void _showShareSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ShareBottomSheet(filter: filter),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ShareBottomSheet extends ConsumerWidget {
  const _ShareBottomSheet({required this.filter});
  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pdfState = ref.watch(pdfGenerationProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.shareReportLabel,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 12),

            // PDF option
            _ShareOption(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: AppColors.error,
              label: l10n.shareAsPdf,
              subtitle: 'PDF · ${filter.vehicleName}',
              isLoading: pdfState.isLoading,
              onTap: () => _sharePdf(context, ref),
            ),
            const SizedBox(height: 8),

            // Text option
            _ShareOption(
              icon: Icons.chat_bubble_outline,
              iconColor: AppColors.emerald,
              label: l10n.shareAsText,
              subtitle: 'WhatsApp, SMS…',
              onTap: () => _shareText(context, ref),
            ),
            const SizedBox(height: 8),

            // Print option
            _ShareOption(
              icon: Icons.print_outlined,
              iconColor: AppColors.accent,
              label: l10n.printLabel,
              subtitle: l10n.exportPdfLabel,
              isLoading: pdfState.isLoading,
              onTap: () => _printPdf(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final path = await _generatePdf(context, ref);
    if (path == null || !context.mounted) return;
    await ref.read(reportShareServiceProvider).sharePdf(
          path,
          subject: 'Rapport ELMOGPS — ${filter.vehicleName}',
        );
  }

  Future<void> _shareText(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final params = filter.params;
    if (params == null) return;

    final summaryAsync = ref.read(summaryReportProvider(params));
    final tripsAsync = ref.read(reportTripsProvider(params));

    await ref.read(reportShareServiceProvider).shareTextSummary(
          vehicleName: filter.vehicleName,
          from: filter.from,
          to: filter.to,
          summary: summaryAsync.valueOrNull,
          trips: tripsAsync.valueOrNull,
        );
  }

  Future<void> _printPdf(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final path = await _generatePdf(context, ref);
    if (path == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          title: 'Rapport — ${filter.vehicleName}',
          filePath: path,
        ),
      ),
    );
  }

  Future<String?> _generatePdf(BuildContext context, WidgetRef ref) async {
    final params = filter.params;
    if (params == null) return null;

    final summaryAsync = ref.read(summaryReportProvider(params));
    final tripsAsync = ref.read(reportTripsProvider(params));
    final stopsAsync = ref.read(stopsReportProvider(params));
    final eventsAsync = ref.read(eventsReportProvider(params));

    final path = await ref.read(pdfGenerationProvider.notifier).generateFull(
          vehicleName: filter.vehicleName,
          from: filter.from,
          to: filter.to,
          summary: summaryAsync.valueOrNull,
          trips: tripsAsync.valueOrNull,
          stops: stopsAsync.valueOrNull,
          events: eventsAsync.valueOrNull,
        );

    if (path == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pdfError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return path;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share option tile
// ─────────────────────────────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondaryOf(context),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _ReportFilterBar extends ConsumerWidget {
  const _ReportFilterBar({
    required this.filter,
    required this.onVehicleSelected,
    required this.onPeriodSelected,
    required this.onFromPicked,
    required this.onToPicked,
    required this.onGenerate,
  });

  final ReportFilterState filter;
  final void Function(String id, String name) onVehicleSelected;
  final void Function(ReportPeriod) onPeriodSelected;
  final void Function(DateTime) onFromPicked;
  final void Function(DateTime) onToPicked;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Container(
      color: AppColors.surfaceOf(context),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle selector
          vehiclesAsync.when(
            data: (vehicles) => _VehicleDropdown(
              vehicles: vehicles,
              selectedId: filter.vehicleId,
              selectedName: filter.vehicleName,
              onSelected: onVehicleSelected,
            ),
            loading: () => const SizedBox(
              height: 44,
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            error: (_, __) => const SizedBox(height: 44),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Period chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ReportPeriod.values.map((p) {
                final isSelected = filter.period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _PeriodChip(
                    label: p.labelFr,
                    isSelected: isSelected,
                    onTap: () => onPeriodSelected(p),
                  ),
                );
              }).toList(),
            ),
          ),

          // Custom date pickers
          if (filter.period == ReportPeriod.custom) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: 'De',
                    value: DateFormatter.toDateTime(filter.from),
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDateTime(context, filter.from, onFromPicked),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.accent),
                ),
                Expanded(
                  child: _DateChip(
                    label: 'À',
                    value: DateFormatter.toDateTime(filter.to),
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDateTime(context, filter.to, onToPicked),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Show the selected range as read-only chips
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 12,
                    color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  '${DateFormatter.toDateTime(filter.from)} → ${DateFormatter.toDateTime(filter.to)}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: filter.canGenerate ? onGenerate : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(context.l10n.generateReport),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
              ),
            ),
          ),
          if (!filter.canGenerate)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.selectVehicleHint,
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11, color: AppColors.textMutedOf(context)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(
    BuildContext context,
    DateTime initial,
    void Function(DateTime) onPicked,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleDropdown extends StatelessWidget {
  const _VehicleDropdown({
    required this.vehicles,
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
  });

  final List<VehicleEntity> vehicles;
  final String? selectedId;
  final String selectedName;
  final void Function(String id, String name) onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(
              color: selectedId != null
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_rounded,
                size: 16,
                color: selectedId != null
                    ? AppColors.accent
                    : AppColors.textMutedOf(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedId != null
                    ? selectedName
                    : context.l10n.selectVehicleDropdownHint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selectedId != null
                      ? AppColors.textPrimaryOf(context)
                      : AppColors.textMutedOf(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.textSecondaryOf(context)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scroll) => _VehiclePickerSheet(
          vehicles: vehicles,
          selectedId: selectedId,
          onSelected: (v) {
            onSelected(v.id, v.name);
            Navigator.pop(ctx);
          },
          scrollController: scroll,
        ),
      ),
    );
  }
}

class _VehiclePickerSheet extends StatelessWidget {
  const _VehiclePickerSheet({
    required this.vehicles,
    required this.selectedId,
    required this.onSelected,
    required this.scrollController,
  });

  final List<VehicleEntity> vehicles;
  final String? selectedId;
  final void Function(VehicleEntity) onSelected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderOf(context),
            borderRadius: BorderRadius.circular(2)),
        ),
          Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Text(context.l10n.selectVehicleSheetTitle,
              style: AppTextStyles.headlineSmall),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: vehicles.length,
            itemBuilder: (_, i) {
              final v = vehicles[i];
              final isSelected = v.id == selectedId;
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.surfaceElevatedOf(context),
                  child: Icon(Icons.directions_car_rounded,
                      size: 16,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondaryOf(context)),
                ),
                title: Text(v.name, style: AppTextStyles.labelLarge),
                subtitle: Text(v.plateNumber, style: AppTextStyles.bodySmall),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.accent, size: 20)
                    : null,
                onTap: () => onSelected(v),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period chip & date chip
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : AppColors.borderOf(context),
              width: isSelected ? 1.2 : 0.8),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected
                ? AppColors.accent
                : AppColors.textSecondaryOf(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: AppColors.accent),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.accent.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, size: 12, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Résumé
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.filter});

  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filter.hasGenerated) {
      return _NotGeneratedPlaceholder(
        icon: Icons.summarize_outlined,
        message: context.l10n.reportGenerateHintSummary,
      );
    }

    final params = filter.params;
    if (params == null) {
      return _NoVehiclePlaceholder();
    }

    final summaryAsync = ref.watch(summaryReportProvider(params));

    return summaryAsync.when(
      loading: () => LoadingView(message: context.l10n.loadingSummary),
      error: (e, _) => ErrorView(
        message: context.l10n.errorLoadingReport,
        onRetry: () => ref.invalidate(summaryReportProvider(params)),
      ),
      data: (summary) {
        if (summary == null) {
          return EmptyView(
            icon: Icons.summarize_outlined,
            title: context.l10n.noDataTitle,
            message: context.l10n.noReportAvailable,
          );
        }
        return _SummaryContent(
            summary: summary, from: filter.from, to: filter.to);
      },
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.summary,
    required this.from,
    required this.to,
  });

  final SummaryReport summary;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final engDur = summary.engineDuration;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // ── Header card ──────────────────────────────────────────────────
          ElmoCard(
            gradient: AppColors.oceanGradient,
            borderColor: AppColors.accentLight.withValues(alpha: 0.25),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.summarize_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.deviceName,
                          style: AppTextStyles.headlineSmall.copyWith(
                              color: Colors.white)),
                      Text(
                        '${DateFormatter.toDate(from)} → ${DateFormatter.toDate(to)}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── KPI grid ─────────────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
            children: [
              _KpiCard(
                icon: Icons.route_rounded,
                label: context.l10n.totalDistanceLabel,
                value: '${summary.totalDistanceKm.toStringAsFixed(1)} km',
                color: AppColors.accent,
              ),
              if (summary.engineHoursMs >= 60000)
                _KpiCard(
                  icon: Icons.timer_rounded,
                  label: context.l10n.engineTimeLabel,
                  value: _fmtDuration(engDur),
                  color: AppColors.purple,
                ),
              _KpiCard(
                icon: Icons.speed_rounded,
                label: context.l10n.maxSpeedKpiLabel,
                value: FormatUtils.speed(summary.maxSpeedKmh),
                color: AppColors.error,
              ),
              _KpiCard(
                icon: Icons.av_timer_rounded,
                label: context.l10n.avgSpeedKpiLabel,
                value: FormatUtils.speed(summary.averageSpeedKmh),
                color: AppColors.success,
              ),
              if (summary.spentFuel > 0)
                _KpiCard(
                  icon: Icons.local_gas_station_rounded,
                  label: context.l10n.fuelConsumedLabel,
                  value: '${summary.spentFuel.toStringAsFixed(1)} L',
                  color: AppColors.amber,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Period detail ─────────────────────────────────────────────────
          ElmoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.analysedPeriod, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                _PeriodRow(label: context.l10n.periodStartLabel, value: DateFormatter.toDateTime(from)),
                _PeriodRow(label: context.l10n.periodEndLabel, value: DateFormatter.toDateTime(to)),
                _PeriodRow(
                  label: context.l10n.totalDurationLabel,
                  value: _fmtDuration(to.difference(from).abs()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondaryOf(context))),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Route
// ─────────────────────────────────────────────────────────────────────────────

class _RouteTab extends ConsumerWidget {
  const _RouteTab({required this.filter});

  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filter.hasGenerated) {
      return _NotGeneratedPlaceholder(
        icon: Icons.map_outlined,
        message: context.l10n.reportGenerateHintRoute,
      );
    }

    final params = filter.params;
    if (params == null) return _NoVehiclePlaceholder();

    final routeAsync = ref.watch(reportRouteProvider(params));

    return routeAsync.when(
      loading: () => LoadingView(message: context.l10n.loadingRoute),
      error: (e, _) => ErrorView(
        message: context.l10n.errorLoadingRoute,
        onRetry: () => ref.invalidate(reportRouteProvider(params)),
      ),
      data: (points) {
        if (points.isEmpty) {
          return EmptyView(
            icon: Icons.map_outlined,
            title: context.l10n.noRouteDataTitle,
            message: context.l10n.noRouteReport,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              _RouteStatsBanner(points: points),
              const SizedBox(height: AppSpacing.md),

              // ── Action buttons ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/reports/route-map',
                          extra: {
                            'params': params,
                            'vehicleName': filter.vehicleName,
                          },
                        ),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: Text(context.l10n.viewOnMap,
                            style: const TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.buttonRadius)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/reports/replay',
                          extra: {
                            'params': params,
                            'vehicleName': filter.vehicleName,
                          },
                        ),
                        icon: const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16),
                        label: Text(context.l10n.viewReplay,
                            style: const TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.buttonRadius)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/reports/charts',
                          extra: {
                            'params': params,
                            'vehicleName': filter.vehicleName,
                          },
                        ),
                        icon: const Icon(Icons.show_chart_rounded,
                            size: 16),
                        label: Text(context.l10n.viewSpeedChart,
                            style: const TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.buttonRadius)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              ElmoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(context.l10n.gpsPointsLabel,
                            style: AppTextStyles.labelLarge),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${points.length} pts',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PeriodRow(
                      label: context.l10n.routeDeparture,
                      value:
                          '${DateFormatter.toDateTime(points.first.fixTime)} · '
                          '${FormatUtils.speed(points.first.speed)}',
                    ),
                    _PeriodRow(
                      label: context.l10n.routeArrival,
                      value:
                          '${DateFormatter.toDateTime(points.last.fixTime)} · '
                          '${FormatUtils.speed(points.last.speed)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RouteStatsBanner extends StatelessWidget {
  const _RouteStatsBanner({required this.points});

  final List points;

  static double _maxSpd(List pts) {
    double m = 0;
    for (final p in pts) {
      if (p.speed > m) m = p.speed;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final first = points.first;
    final last = points.last;
    final dur = last.fixTime.difference(first.fixTime).abs();
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    final durStr = h > 0 ? '${h}h ${m}min' : '${m}min';
    final maxSpd = _maxSpd(points);

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.schedule_rounded,
            label: context.l10n.durationLabel,
            value: durStr,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            icon: Icons.speed_rounded,
            label: context.l10n.routeMaxSpeedShort,
            value: FormatUtils.speed(maxSpd),
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KpiCard(
            icon: Icons.gps_fixed_rounded,
            label: context.l10n.routePointsShort,
            value: '${points.length}',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Trajets
// ─────────────────────────────────────────────────────────────────────────────

class _TripsTab extends ConsumerWidget {
  const _TripsTab({required this.filter});

  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filter.hasGenerated) {
      return _NotGeneratedPlaceholder(
        icon: Icons.route_outlined,
        message: context.l10n.reportGenerateHintTrips,
      );
    }

    final params = filter.params;
    if (params == null) return _NoVehiclePlaceholder();

    final tripsAsync = ref.watch(reportTripsProvider(params));

    return tripsAsync.when(
      loading: () => LoadingView(message: context.l10n.loadingTrips),
      error: (e, _) => ErrorView(
        message: context.l10n.errorLoadingTrips,
        onRetry: () => ref.invalidate(reportTripsProvider(params)),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return EmptyView(
            icon: Icons.route_outlined,
            title: context.l10n.noTripsDataTitle,
            message: context.l10n.noTripsReport,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: trips.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _TripReportCard(
            index: i + 1,
            trip: trips[i],
          ),
        );
      },
    );
  }
}

class _TripReportCard extends StatelessWidget {
  const _TripReportCard({required this.index, required this.trip});

  final int index;
  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    return ElmoCard(
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormatter.toDate(trip.startTime),
                        style: AppTextStyles.labelLarge),
                    Text(
                      '${DateFormatter.toTime(trip.startTime)} → '
                      '${trip.endTime != null ? DateFormatter.toTime(trip.endTime!) : 'En cours'}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trip.isOngoing)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusMoving.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(context.l10n.ongoingTrip,
                      style: const TextStyle(
                          color: AppColors.statusMoving,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 0, thickness: 0.5),
          const SizedBox(height: AppSpacing.sm),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TripStat(
                icon: Icons.route_rounded,
                label: context.l10n.distanceLabel,
                value: FormatUtils.distance(trip.distanceMeters),
                color: AppColors.accent,
              ),
              _TripStat(
                icon: Icons.timer_rounded,
                label: context.l10n.durationLabel,
                value: DateFormatter.duration(trip.durationSeconds),
                color: AppColors.purple,
              ),
              _TripStat(
                icon: Icons.speed_rounded,
                label: context.l10n.routeMaxSpeedShort,
                value: FormatUtils.speed(trip.maxSpeedKmh),
                color: AppColors.error,
              ),
              _TripStat(
                icon: Icons.av_timer_rounded,
                label: context.l10n.routeAvgSpeedShort,
                value: FormatUtils.speed(trip.averageSpeedKmh),
                color: AppColors.success,
              ),
            ],
          ),

          // Address row
          if (trip.startAddress != null || trip.endAddress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TripRouteRow(
              start: trip.startAddress ?? context.l10n.routeDeparture,
              end: trip.endAddress ?? context.l10n.routeArrival,
            ),
          ],
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _TripRouteRow extends StatelessWidget {
  const _TripRouteRow({required this.start, required this.end});

  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _TripLocation(
            icon: Icons.radio_button_checked,
            label: start,
            color: AppColors.success,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
              width: 1.5, height: 10,
              color: AppColors.borderOf(context),
            ),
          ),
          _TripLocation(
            icon: Icons.location_on_rounded,
            label: end,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _TripLocation extends StatelessWidget {
  const _TripLocation({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Arrêts
// ─────────────────────────────────────────────────────────────────────────────

class _StopsTab extends ConsumerWidget {
  const _StopsTab({required this.filter});

  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filter.hasGenerated) {
      return _NotGeneratedPlaceholder(
        icon: Icons.stop_circle_outlined,
        message: context.l10n.reportGenerateHintStops,
      );
    }

    final params = filter.params;
    if (params == null) return _NoVehiclePlaceholder();

    final stopsAsync = ref.watch(stopsReportProvider(params));

    return stopsAsync.when(
      loading: () => LoadingView(message: context.l10n.loadingStops),
      error: (e, _) => ErrorView(
        message: context.l10n.errorLoadingStops,
        onRetry: () => ref.invalidate(stopsReportProvider(params)),
      ),
      data: (stops) {
        if (stops.isEmpty) {
          return EmptyView(
            icon: Icons.stop_circle_outlined,
            title: context.l10n.noStopsDataTitle,
            message: context.l10n.noStopsReport,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: stops.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _StopReportCard(
            index: i + 1,
            stop: stops[i],
          ),
        );
      },
    );
  }
}

class _StopReportCard extends StatelessWidget {
  const _StopReportCard({required this.index, required this.stop});

  final int index;
  final StopReport stop;

  @override
  Widget build(BuildContext context) {
    final dur = stop.duration;
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    final durStr = h > 0 ? '${h}h ${m}min' : '${m}min';

    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.statusStopped.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: AppColors.statusStopped,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.address ?? '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                      style: AppTextStyles.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${DateFormatter.toTime(stop.startTime)} → '
                      '${stop.endTime != null ? DateFormatter.toTime(stop.endTime!) : '—'}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              // Duration badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusStopped.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  durStr,
                  style: const TextStyle(
                    color: AppColors.statusStopped,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.accent),
              const SizedBox(width: 5),
              Text(DateFormatter.toDate(stop.startTime),
                  style: AppTextStyles.bodySmall),
              const Spacer(),
              // Coordinates
              Text(
                '${stop.lat.toStringAsFixed(4)}, ${stop.lng.toStringAsFixed(4)}',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Événements
// ─────────────────────────────────────────────────────────────────────────────

class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.filter});

  final ReportFilterState filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!filter.hasGenerated) {
      return _NotGeneratedPlaceholder(
        icon: Icons.event_note_outlined,
        message: context.l10n.reportGenerateHintEvents,
      );
    }

    final params = filter.params;
    if (params == null) return _NoVehiclePlaceholder();

    final eventsAsync = ref.watch(eventsReportProvider(params));

    return eventsAsync.when(
      loading: () => LoadingView(message: context.l10n.loadingEvents),
      error: (e, _) => ErrorView(
        message: context.l10n.errorLoadingEvents,
        onRetry: () => ref.invalidate(eventsReportProvider(params)),
      ),
      data: (events) {
        if (events.isEmpty) {
          return EmptyView(
            icon: Icons.event_note_outlined,
            title: context.l10n.noEventsDataTitle,
            message: context.l10n.noEventsReport,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: events.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, i) => _EventTimelineItem(event: events[i]),
        );
      },
    );
  }
}

class _EventTimelineItem extends StatelessWidget {
  const _EventTimelineItem({required this.event});

  final EventReport event;

  static Color _color(String severity) => switch (severity) {
        'critical' => AppColors.error,
        'warning' => AppColors.warning,
        'success' => AppColors.success,
        'info' => AppColors.accent,
        _ => AppColors.textSecondary,
      };

  static IconData _icon(String type) => switch (type) {
        'deviceOverspeed' => Icons.speed_rounded,
        'ignitionOn' => Icons.power_rounded,
        'ignitionOff' => Icons.power_off_rounded,
        'deviceOnline' => Icons.wifi_rounded,
        'deviceOffline' => Icons.wifi_off_rounded,
        'geofenceEnter' => Icons.login_rounded,
        'geofenceExit' => Icons.logout_rounded,
        'alarm' => Icons.warning_amber_rounded,
        'maintenance' => Icons.build_rounded,
        'deviceMoving' => Icons.directions_car_rounded,
        'deviceStopped' => Icons.stop_circle_rounded,
        'hardBraking' => Icons.emergency_rounded,
        'hardAcceleration' => Icons.rocket_launch_rounded,
        _ => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(event.severity);
    final icon = _icon(event.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withValues(alpha: 0.35), width: 1.2),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
          ],
        ),

        const SizedBox(width: AppSpacing.sm),

        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: color.withValues(alpha: 0.15), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(event.labelFr,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: color)),
                    ),
                    Text(
                      DateFormatter.toTime(event.eventTime),
                      style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormatter.toDate(event.eventTime),
                      style: AppTextStyles.bodySmall
                          .copyWith(fontSize: 10),
                    ),
                    if (event.speedKmh != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.speed_rounded,
                          size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        FormatUtils.speed(event.speedKmh!),
                        style: AppTextStyles.bodySmall
                            .copyWith(fontSize: 10, color: color),
                      ),
                    ],
                    if (event.deviceName.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        event.deviceName,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondaryOf(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared placeholder widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NotGeneratedPlaceholder extends StatelessWidget {
  const _NotGeneratedPlaceholder({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoVehiclePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: Icons.directions_car_outlined,
      title: context.l10n.noVehicleSelectedTitle,
      message: context.l10n.selectVehicleHint,
    );
  }
}
