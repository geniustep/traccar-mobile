import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/geofence_area_codec.dart';
import '../../data/datasources/geofences_remote_datasource.dart';
import '../../domain/entities/geofence.dart';
import '../providers/geofences_providers.dart';
import '../widgets/geofence_map_picker.dart';

class GeofenceDetailsScreen extends ConsumerWidget {
  const GeofenceDetailsScreen({super.key, required this.geofenceId});

  final String geofenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = int.tryParse(geofenceId);
    final async = ref.watch(geofencesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.geofenceDetailsTitle),
        actions: [
          if (id != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/geofences/$id/edit'),
            ),
        ],
      ),
      body: async.when(
        data: (list) {
          GeofenceEntity? g;
          if (id != null) {
            for (final e in list) {
              if (e.id == id) {
                g = e;
                break;
              }
            }
          }
          if (g == null) {
            return Center(child: Text(l10n.geofenceNotFound));
          }
          final p = GeofencesRemoteDataSource.parseStoredNotificationIds(g.attributes);
          final hasN = p.$1 != null || p.$2 != null;

          LatLng? c;
          double r = 200;
          final poly = <LatLng>[];
          if (g.isCircle) {
            final cd = GeofenceAreaCodec.decodeCircle(g.area);
            if (cd != null) {
              c = LatLng(cd.latitude, cd.longitude);
              r = cd.radiusMeters;
            }
          } else {
            poly.addAll(GeofenceAreaCodec.decodePolygon(g.area));
            if (poly.isNotEmpty) c = poly.first;
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text(g.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                g.isCircle ? l10n.geofenceTypeCircle : l10n.geofenceTypePolygon,
              ),
              const SizedBox(height: 8),
              Text('${l10n.geofenceLinkedVehicles}: ${g.linkedDeviceIds.length}'),
              const SizedBox(height: 8),
              Text(
                hasN ? l10n.geofenceAlertStatusOn : l10n.geofenceAlertStatusOff,
              ),
              const SizedBox(height: 16),
              if (c != null)
                GeofenceMapPicker(
                  kind: g.isCircle ? GeofenceDrawKind.circle : GeofenceDrawKind.polygon,
                  center: g.isCircle ? c : null,
                  radiusMeters: r,
                  polygonPoints: g.isPolygon ? poly : const [],
                  strokeColor: g.fillColor.withValues(alpha: 0.95),
                  fillColor: g.fillColor,
                  fitNonce: g.id,
                  mapTitle: g.name,
                  interactive: false,
                  onMapTap: (_) {},
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
