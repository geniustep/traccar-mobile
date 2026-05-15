import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Result returned by the replay entry bottom sheet.
class ReplayEntryResult {
  const ReplayEntryResult({
    required this.vehicleId,
    required this.vehicleName,
    required this.from,
    required this.to,
  });

  final String vehicleId;
  final String vehicleName;
  final DateTime from;
  final DateTime to;
}

/// Shows the replay-entry bottom sheet from Vehicle Details.
///
/// Returns [ReplayEntryResult] if the user confirms, or `null` on dismiss.
Future<ReplayEntryResult?> showReplayEntrySheet(
  BuildContext context, {
  required String vehicleId,
  required String vehicleName,
}) {
  AppLogger.navigation(
      'ReplayEntrySheet opened: vehicleId=$vehicleId, name=$vehicleName');
  return showModalBottomSheet<ReplayEntryResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReplayEntrySheetBody(
      vehicleId: vehicleId,
      vehicleName: vehicleName,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

enum _ReplayPeriod { today, yesterday, custom }

class _ReplayEntrySheetBody extends StatefulWidget {
  const _ReplayEntrySheetBody({
    required this.vehicleId,
    required this.vehicleName,
  });

  final String vehicleId;
  final String vehicleName;

  @override
  State<_ReplayEntrySheetBody> createState() => _ReplayEntrySheetBodyState();
}

class _ReplayEntrySheetBodyState extends State<_ReplayEntrySheetBody> {
  _ReplayPeriod _period = _ReplayPeriod.today;
  late DateTime _from;
  late DateTime _to;
  String? _dateError;
  bool _rangeWarning = false;

  @override
  void initState() {
    super.initState();
    _applyPeriod(_ReplayPeriod.today);
  }

  void _applyPeriod(_ReplayPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case _ReplayPeriod.today:
        _from = DateTime(now.year, now.month, now.day);
        _to = now;
      case _ReplayPeriod.yesterday:
        final y = now.subtract(const Duration(days: 1));
        _from = DateTime(y.year, y.month, y.day);
        _to = DateTime(y.year, y.month, y.day, 23, 59, 59);
      case _ReplayPeriod.custom:
        break;
    }
    _period = period;
    _dateError = null;
    _rangeWarning = false;
  }

  void _checkRangeWarning() {
    final diff = _to.difference(_from);
    _rangeWarning = diff.inHours > 24;
  }

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
      _checkRangeWarning();
    });

    AppLogger.navigation(
        'ReplayEntrySheet: custom ${isStart ? "from" : "to"} picked=$dt');
  }

  void _confirm() {
    if (_period == _ReplayPeriod.custom && _from.isAfter(_to)) {
      setState(() {
        _dateError = AppLocalizations.of(context).invalidDateRange;
      });
      AppLogger.navigation(
          'ReplayEntrySheet: invalid date range from=$_from to=$_to');
      return;
    }

    final result = ReplayEntryResult(
      vehicleId: widget.vehicleId,
      vehicleName: widget.vehicleName,
      from: _from,
      to: _to,
    );

    AppLogger.navigation(
        'ReplayEntrySheet: confirmed period=$_period '
        'from=$_from to=$_to vehicleId=${widget.vehicleId}');

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final periodOptions = [
      (l10n.periodToday, _ReplayPeriod.today),
      (l10n.periodYesterday, _ReplayPeriod.yesterday),
      (l10n.periodCustom, _ReplayPeriod.custom),
    ];

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
          Text(l10n.replaySheetTitle, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.directions_car_rounded,
                  size: 14, color: AppColors.purple),
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

          // ── Period selector ─────────────────────────────────────────────
          Text(l10n.selectReplayPeriod,
              style: AppTextStyles.labelMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: periodOptions.map((e) {
              final (label, value) = e;
              final selected = _period == value;
              return _PeriodChip(
                label: label,
                selected: selected,
                onTap: () {
                  setState(() => _applyPeriod(value));
                  AppLogger.navigation(
                      'ReplayEntrySheet: period selected=$label');
                },
              );
            }).toList(),
          ),

          // ── Custom range pickers ───────────────────────────────────────
          if (_period == _ReplayPeriod.custom) ...[
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
                      size: 14, color: AppColors.purple),
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

          // ── Range warning ──────────────────────────────────────────────
          if (_rangeWarning) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.replayRangeTooLong,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.amberDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Start Replay button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _confirm,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(l10n.startReplay),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
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

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.purple.withValues(alpha: 0.12)
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
                  ? AppColors.purple
                  : AppColors.borderOf(context),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected
                  ? AppColors.purple
                  : AppColors.textSecondaryOf(context),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
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
                    size: 13, color: AppColors.purple),
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
