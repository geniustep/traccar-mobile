import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

class GeofenceVehicleSelector extends StatelessWidget {
  const GeofenceVehicleSelector({
    super.key,
    required this.vehicles,
    required this.selectedIds,
    required this.onChanged,
    required this.l10n,
  });

  final List<VehicleEntity> vehicles;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final AppLocalizations l10n;

  Future<void> _openSheet(BuildContext context) async {
    final temp = Set<int>.from(selectedIds);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, scroll) {
            return StatefulBuilder(
              builder: (ctx2, setSt) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => setSt(() => temp.clear()),
                            child: Text(l10n.geofenceVehiclesClear),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              onChanged(temp);
                              Navigator.pop(ctx2);
                            },
                            child: Text(l10n.confirm),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                      controller: scroll,
                      itemCount: vehicles.length,
                      itemBuilder: (_, i) {
                        final v = vehicles[i];
                        final id = int.tryParse(v.id) ?? 0;
                        final checked = temp.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(v.name),
                          subtitle: Text(v.plateNumber),
                          onChanged: (c) {
                            setSt(() {
                              if (c == true) {
                                temp.add(id);
                              } else {
                                temp.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = selectedIds.isEmpty
        ? l10n.geofenceNoVehiclesLinked
        : l10n.geofenceVehiclesSelectedCount(selectedIds.length);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.geofenceLinkedVehicles),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _openSheet(context),
    );
  }
}
