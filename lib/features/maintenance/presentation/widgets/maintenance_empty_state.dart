import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';

class MaintenanceEmptyState extends StatelessWidget {
  const MaintenanceEmptyState({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: l10n.maintenanceEmptyTitle,
      message: l10n.maintenanceEmptyMessage,
    );
  }
}
