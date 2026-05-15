import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reports/presentation/providers/reports_providers.dart';

/// Shows the report-entry bottom sheet from Vehicle Details.
///
/// Returns [ReportsEntryParams] if the user confirms, or `null` on dismiss.
Future<ReportsEntryParams?> showReportEntrySheet(
  BuildContext context, {
  required String vehicleId,
  required String vehicleName,
}) {
  AppLogger.navigation(
      'ReportEntrySheet opened: vehicleId=$vehicleId, name=$vehicleName');
  return showModalBottomSheet<ReportsEntryParams>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReportEntrySheetBody(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReportEntrySheetBody extends StatefulWidget {
  const _ReportEntrySheetBody({
    required this.vehicleId,
    required this.vehicleName,
  });

  final String vehicleId;
  final String vehicleName;

  @override
  State<_ReportEntrySheetBody> createState() => _ReportEntrySheetBodyState();
}

class _ReportEntrySheetBodyState extends State<_ReportEntrySheetBody> {
  int _selectedTab = 0;
  ReportPeriod _period = ReportPeriod.today;
  late DateTime _from;
  late DateTime _to;
  String? _dateError;

  static const _tabLabels = [
    _TabDef(0, Icons.summarize_outlined),
    _TabDef(1, Icons.route_outlined),
    _TabDef(2, Icons.timeline_outlined),
    _TabDef(3, Icons.pause_circle_outline_rounded),
    _TabDef(4, Icons.event_note_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _applyPeriod(ReportPeriod.today);
  }

  void _applyPeriod(ReportPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.today:
        _from = DateTime(now.year, now.month, now.day);
        _to = now;
      case ReportPeriod.yesterday:
        final y = now.subtract(const Duration(days: 1));
        _from = DateTime(y.year, y.month, y.day);
        _to = DateTime(y.year, y.month, y.day, 23, 59, 59);
      case ReportPeriod.thisWeek:
        final daysFromMonday = now.weekday - 1;
        _from = DateTime(now.year, now.month, now.day - daysFromMonday);
        _to = now;
      case ReportPeriod.thisMonth:
        _from = DateTime(now.year, now.month, 1);
        _to = now;
      case ReportPeriod.custom:
        break;
    }
    _period = period;
    _dateError = null;
  }

  List<String> _reportTypeLabels(AppLocalizations l10n) => [
        l10n.reportsSummary,
        l10n.reportsRoute,
        l10n.reportsTrips,
        l10n.reportsStops,
        l10n.reportsEvents,
      ];

  List<String> _periodLabels(AppLocalizations l10n) => [
        l10n.periodToday,
        l10n.periodYesterday,
        l10n.periodThisWeek,
        l10n.periodThisMonth,
        l10n.periodCustom,
      ];

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;

    final dt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      pickedTime?.hour ?? initial.hour,
      pickedTime?.minute ?? initial.minute,
    );

    setState(() {
      if (isStart) {
        _from = dt;
      } else {
        _to = dt;
      }
      _dateError = _from.isAfter(_to)
          ? AppLocalizations.of(context).invalidDateRange
          : null;
    });

    AppLogger.navigation(
        'ReportEntrySheet: custom ${isStart ? "from" : "to"} picked=$dt');
  }

  void _confirm() {
    if (_period == ReportPeriod.custom && _from.isAfter(_to)) {
      setState(() {
        _dateError = AppLocalizations.of(context).invalidDateRange;
      });
      AppLogger.navigation(
          'ReportEntrySheet: invalid date range from=$_from to=$_to');
      return;
    }

    final params = ReportsEntryParams(
      vehicleId: widget.vehicleId,
      vehicleName: widget.vehicleName,
      period: _period,
      from: _from,
      to: _to,
      tabIndex: _selectedTab,
    );

    AppLogger.navigation(
        'ReportEntrySheet: confirmed type=$_selectedTab period=$_period '
        'from=$_from to=$_to vehicleId=${widget.vehicleId}');

    Navigator.of(context).pop(params);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeLabels = _reportTypeLabels(l10n);
    final periodLabels = _periodLabels(l10n);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ─────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Title + vehicle name ───────────────────────────────────────
          Text(l10n.reportSheetTitle, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.directions_car_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.vehicleName,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryOf(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Report type ────────────────────────────────────────────────
          Text(l10n.selectReportType,
              style: AppTextStyles.labelMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_tabLabels.length, (i) {
              final selected = _selectedTab == i;
              return _SelectableChip(
                icon: _tabLabels[i].icon,
                label: typeLabels[i],
                selected: selected,
                onTap: () {
                  setState(() => _selectedTab = i);
                  AppLogger.navigation(
                      'ReportEntrySheet: type selected=${typeLabels[i]}');
                },
              );
            }),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Period ─────────────────────────────────────────────────────
          Text(l10n.selectPeriod,
              style: AppTextStyles.labelMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(ReportPeriod.values.length, (i) {
              final p = ReportPeriod.values[i];
              final selected = _period == p;
              return _SelectableChip(
                label: periodLabels[i],
                selected: selected,
                onTap: () {
                  setState(() => _applyPeriod(p));
                  AppLogger.navigation(
                      'ReportEntrySheet: period selected=${periodLabels[i]}');
                },
              );
            }),
          ),

          // ── Custom range pickers ───────────────────────────────────────
          if (_period == ReportPeriod.custom) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: l10n.startDateLabel,
                    value: _from,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.accent),
                ),
                Expanded(
                  child: _DateButton(
                    label: l10n.endDateLabel,
                    value: _to,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 6),
              Text(
                _dateError!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.rose, fontSize: 12),
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Generate button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(l10n.generateVehicleReport),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _TabDef {
  const _TabDef(this.index, this.icon);
  final int index;
  final IconData icon;
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.backgroundOf(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.borderOf(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondaryOf(context)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected
                      ? AppColors.accent
                      : AppColors.textSecondaryOf(context),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMutedOf(context),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatted,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
