import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../domain/entities/driver.dart';
import '../providers/drivers_providers.dart';

class DriverEditorScreen extends ConsumerStatefulWidget {
  const DriverEditorScreen({super.key, required this.driverId});

  /// القيمة `new` تنشئ سائقًا جديدًا، وخلاف ذلك رقم حقيقي.
  final String driverId;

  @override
  ConsumerState<DriverEditorScreen> createState() =>
      _DriverEditorScreenState();
}

class _DriverEditorScreenState extends ConsumerState<DriverEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _code;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _license;
  late TextEditingController _notes;
  DateTime? _expiry;
  Set<int> _devices = {};
  bool _busy = false;

  bool get _isNew => widget.driverId == 'new';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _code = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _license = TextEditingController();
    _notes = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _phone.dispose();
    _email.dispose();
    _license.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 20),
    );
    if (d != null) setState(() => _expiry = d);
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final repo = ref.read(driversRepositoryProvider);

    try {
      final prev = _isNew ? const <int>[] : List<int>.from(_previousDeviceIds);

      final entity = DriverEntity(
        id: _isNew ? 0 : int.parse(widget.driverId),
        name: _name.text.trim(),
        uniqueId: _code.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        licenseNumber:
            _license.text.trim().isEmpty ? null : _license.text.trim(),
        licenseExpiry: _expiry,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        linkedDeviceIds: _devices.toList()..sort(),
        rawAttributes: Map<String, dynamic>.from(_seedTemplate?.rawAttributes ?? {}),
      );

      final DriverEntity saved;
      if (_isNew) {
        saved = await repo.createDriver(entity);
      } else {
        saved = await repo.updateDriver(entity);
      }

      await repo.syncLinkedDevices(
        driverId: saved.id,
        desiredIds: _devices.toList()..sort(),
        previousIds: prev,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.driversSave)));
      await ref.read(driversListProvider.notifier).refresh();
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  DriverEntity? _seedTemplate;
  List<int> _previousDeviceIds = const [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!_isNew) {
      final id = int.tryParse(widget.driverId);
      if (id == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(l10n.driversLoadError)),
        );
      }

      final async = ref.watch(driverByIdProvider(id));
      return async.when(
        data: (d) {
          if (d == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.driversEdit)),
              body: Center(child: Text(l10n.driversLoadError)),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _seedTemplate?.id == d.id) return;
            setState(() {
              _seedTemplate = d;
              _previousDeviceIds = List<int>.from(d.linkedDeviceIds);
              _name.text = d.name;
              _code.text = d.uniqueId;
              _phone.text = d.phone ?? '';
              _email.text = d.email ?? '';
              _license.text = d.licenseNumber ?? '';
              _notes.text = d.notes ?? '';
              _expiry = d.licenseExpiry;
              _devices = d.linkedDeviceIds.toSet();
            });
          });

          return _buildForm(l10n, title: l10n.driversEdit);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l10n.driversEdit)),
          body: LoadingView(message: l10n.loading),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.driversEdit)),
          body: Center(child: Text('$e')),
        ),
      );
    }

    return _buildForm(l10n, title: l10n.driversAdd);
  }

  Widget _buildForm(AppLocalizations l10n, {required String title}) {
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
              onPressed: () => _save(l10n),
              child: Text(l10n.driversSave),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.driverNameLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            TextFormField(
              controller: _code,
              decoration: InputDecoration(labelText: l10n.driverCodeLabel),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l10n.driverPhoneLabel),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _license,
              decoration:
                  InputDecoration(labelText: l10n.drivingLicenseLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.licenseExpiryLabel),
              subtitle: Text(
                _expiry == null ? l10n.noData : '$_expiry',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.date_range_rounded),
                onPressed: _pickDate,
              ),
            ),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l10n.driverNotesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.driversSelectVehiclesHint,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            vehiclesAsync.when(
              data: (list) => Column(
                children: list.map((v) => _vehicleTile(v)).toList(),
              ),
              loading: () => LoadingView(message: l10n.loading),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleTile(VehicleEntity v) {
    final id = int.tryParse(v.id);
    if (id == null) return const SizedBox.shrink();
    final checked = _devices.contains(id);
    return CheckboxListTile(
      value: checked,
      title: Text(v.name),
      subtitle: Text(v.plateNumber),
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _devices.add(id);
          } else {
            _devices.remove(id);
          }
        });
      },
    );
  }
}
