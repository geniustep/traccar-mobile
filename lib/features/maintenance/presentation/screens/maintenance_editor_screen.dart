import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../domain/entities/maintenance_record.dart';
import '../../domain/maintenance_type_codes.dart';
import '../providers/maintenance_providers.dart';

class MaintenanceEditorScreen extends ConsumerStatefulWidget {
  const MaintenanceEditorScreen({super.key, required this.recordId});

  final String recordId;

  @override
  ConsumerState<MaintenanceEditorScreen> createState() =>
      _MaintenanceEditorScreenState();
}

class _MaintenanceEditorScreenState
    extends ConsumerState<MaintenanceEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _odo;
  late TextEditingController _notes;
  String _vehicleKey = '';
  String _typeCode = ElmoMaintenanceTypeCode.other;
  DateTime? _dueDate;
  bool _completed = false;
  bool _busy = false;
  MaintenanceRecordEntity? _seed;

  bool get _isNew => widget.recordId == 'new';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _odo = TextEditingController();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _odo.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final base = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? base,
      firstDate: DateTime(base.year - 5),
      lastDate: DateTime(base.year + 15),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isNew && _vehicleKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationRequired)),
      );
      return;
    }

    setState(() => _busy = true);
    final repo = ref.read(maintenanceRepositoryProvider);

    final deviceId = _isNew ? int.parse(_vehicleKey) : _seed!.deviceId;

    final parsedOdom = double.tryParse(_odo.text.trim().replaceAll(',', '.'));

    final entity = MaintenanceRecordEntity(
      id: _isNew ? 0 : int.parse(widget.recordId),
      deviceId: deviceId,
      name: _title.text.trim(),
      rawAttributes: Map<String, dynamic>.from(_seed?.rawAttributes ?? {}),
      traccarType: _seed?.traccarType ?? 'mileage',
      traccarStart: _seed?.traccarStart ?? 0,
      traccarPeriod: (_seed?.traccarPeriod ?? 0) <= 0
          ? 999999
          : _seed!.traccarPeriod,
      maintenanceTypeCode: _typeCode,
      dueDate: _dueDate,
      dueOdometerKm: parsedOdom,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      completedAt: _completed ? DateTime.now() : null,
    );

    try {
      if (_isNew) {
        await repo.createRecord(entity);
      } else {
        await repo.updateRecord(entity);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.driversSave)));
      await ref.read(maintenanceListProvider.notifier).refresh();
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!_isNew) {
      final id = int.tryParse(widget.recordId);
      if (id == null) {
        return Scaffold(
          body: Center(child: Text(l10n.maintenanceLoadError)),
        );
      }

      final async = ref.watch(maintenanceByIdProvider(id));
      return async.when(
        data: (row) {
          if (row == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.maintenanceEdit)),
              body: Center(child: Text(l10n.maintenanceLoadError)),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _seed?.id == row.id) return;
            setState(() {
              _seed = row;
              _title.text = row.name;
              _vehicleKey = '${row.deviceId}';
              _typeCode =
                  row.maintenanceTypeCode ?? ElmoMaintenanceTypeCode.other;
              _dueDate = row.dueDate;
              _odo.text =
                  row.dueOdometerKm != null ? '${row.dueOdometerKm}' : '';
              _notes.text = row.notes ?? '';
              _completed = row.isCompleted;
            });
          });

          return _formScaffold(l10n, title: l10n.maintenanceEdit);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.maintenanceEdit)),
          body: LoadingView(message: l10n.loading),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('$e')),
        ),
      );
    }

    return _formScaffold(l10n, title: l10n.maintenanceAdd);
  }

  Widget _formScaffold(AppLocalizations l10n, {required String title}) {
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () => _submit(l10n),
              child: Text(l10n.driversSave),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            vehiclesAsync.when(
              data: (vv) {
                if (!_isNew &&
                    _vehicleKey.isEmpty &&
                    _seed != null &&
                    vv.any((x) => x.id == '${_seed!.deviceId}')) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _vehicleKey = '${_seed!.deviceId}');
                    }
                  });
                }
                if (_isNew && _vehicleKey.isEmpty && vv.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _vehicleKey.isEmpty) {
                      setState(() => _vehicleKey = vv.first.id);
                    }
                  });
                }

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: l10n.maintenanceFilterVehicle,
                  ),
                  initialValue:
                      vv.any((x) => x.id == _vehicleKey) ? _vehicleKey : null,
                  items: vv
                      .map(
                        (v) => DropdownMenuItem<String>(
                          value: v.id,
                          child: Text(v.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isNew
                      ? (v) =>
                          setState(() => _vehicleKey = v ?? _vehicleKey)
                      : null,
                  validator: (v) => _isNew && (v == null || v.isEmpty)
                      ? l10n.validationRequired
                      : null,
                );
              },
              loading: () => LoadingView(message: l10n.loading),
              error: (e, _) => Text('$e'),
            ),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                hintText: l10n.maintenanceDetailTitle,
                labelText: l10n.maintenanceTitle,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? l10n.validationRequired
                      : null,
            ),
            DropdownButtonFormField<String>(
              decoration:
                  InputDecoration(labelText: l10n.maintenanceTypeLabelField),
              initialValue: ElmoMaintenanceTypeCode.allOrdered.contains(_typeCode)
                  ? _typeCode
                  : ElmoMaintenanceTypeCode.other,
              items: ElmoMaintenanceTypeCode.allOrdered
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(l10n.maintenanceTypeLocalized(c)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _typeCode = v ?? ElmoMaintenanceTypeCode.other),
            ),
            ListTile(
              title: Text(l10n.maintenanceDueDateLabel),
              subtitle:
                  Text(_dueDate?.toIso8601String().split('T').first ?? '—'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: _pickDue,
              ),
            ),
            TextField(
              controller: _odo,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: l10n.maintenanceDueOdometerLabel),
            ),
            SwitchListTile(
              title: Text(l10n.maintenanceMarkCompletedHint),
              value: _completed,
              onChanged: (v) => setState(() => _completed = v),
            ),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l10n.driverNotesLabel),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
