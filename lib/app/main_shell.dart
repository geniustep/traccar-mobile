import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/app_localizations.dart';
import '../features/alerts/presentation/providers/alerts_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _paths = ['/dashboard', '/vehicles', '/map', '/alerts', '/settings'];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.map_rounded,
    Icons.notifications_rounded,
    Icons.person_rounded,
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.map_outlined,
    Icons.notifications_outlined,
    Icons.person_outline_rounded,
  ];

  int _locationToIndex(String location) {
    for (var i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final l10n = context.l10n;

    final labels = [
      l10n.navHome,
      l10n.navFleet,
      l10n.navMap,
      l10n.navAlerts,
      l10n.navProfile,
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_paths[i]),
          destinations: List.generate(_paths.length, (i) {
            final isSelected = i == currentIndex;
            Widget icon = Icon(isSelected ? _activeIcons[i] : _icons[i]);

            if (_paths[i] == '/alerts' && unreadAlerts > 0) {
              icon = Badge(
                label: Text('$unreadAlerts'),
                backgroundColor: const Color(0xFFFF4757),
                child: icon,
              );
            }

            return NavigationDestination(
              icon: icon,
              selectedIcon: Icon(_activeIcons[i]),
              label: labels[i],
            );
          }),
        ),
      ),
    );
  }
}
