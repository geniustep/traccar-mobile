import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';

class DriverEmptyState extends StatelessWidget {
  const DriverEmptyState({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: l10n.driversEmptyTitle,
      message: l10n.driversEmptyMessage,
    );
  }
}
