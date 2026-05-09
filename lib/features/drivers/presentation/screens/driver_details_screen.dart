import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../providers/drivers_providers.dart';

class DriverDetailsScreen extends ConsumerWidget {
  const DriverDetailsScreen({super.key, required this.driverId});

  final String driverId;

  static String _licenseLine(AppLocalizations l10n, DriverLicenseStatus s) =>
      switch (s) {
        DriverLicenseStatus.expired => l10n.licenseStatusExpired,
        DriverLicenseStatus.expiringSoon => l10n.licenseStatusSoon,
        DriverLicenseStatus.valid => l10n.licenseStatusValid,
        _ => l10n.licenseStatusUnknown,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final parsed = int.tryParse(driverId);
    if (parsed == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.driversLoadError)),
      );
    }

    final async = ref.watch(driverByIdProvider(parsed));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/drivers/$driverId/edit'),
          ),
        ],
      ),
      body: async.when(
        data: (driver) {
          if (driver == null) {
            return Center(child: Text(l10n.driversLoadError));
          }

          final lic = driver.licenseStatus(DateTime.now());

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text(driver.name,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${l10n.driverCodeLabel}: ${driver.uniqueId}'),
              const SizedBox(height: 12),
              if (driver.phone != null && driver.phone!.trim().isNotEmpty)
                Text('${l10n.driverPhoneLabel}: ${driver.phone}'),
              if (driver.email != null && driver.email!.trim().isNotEmpty)
                Text('${l10n.emailLabel}: ${driver.email}'),
              const SizedBox(height: 8),
              if (driver.licenseNumber != null &&
                  driver.licenseNumber!.trim().isNotEmpty)
                Text('${l10n.drivingLicenseLabel}: ${driver.licenseNumber}'),
              if (driver.licenseExpiry != null)
                Text('${l10n.licenseExpiryLabel}: ${driver.licenseExpiry}'),
              Text(_licenseLine(l10n, lic)),
              const SizedBox(height: 12),
              Text(
                l10n.driversLinkedVehicles,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                driver.linkedDeviceIds.isEmpty
                    ? l10n.geofenceNoVehiclesLinked
                    : driver.linkedDeviceIds.join(', '),
              ),
              if (driver.notes != null && driver.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.driverNotesLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(driver.notes!),
              ],
            ],
          );
        },
        loading: () => LoadingView(message: l10n.loading),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
