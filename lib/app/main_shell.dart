import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../features/alerts/presentation/providers/alerts_provider.dart';
import '../features/notifications/presentation/providers/notifications_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavItem('/dashboard', Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem('/vehicles', Icons.directions_car_rounded,
        Icons.directions_car_outlined, 'Fleet'),
    _NavItem('/map', Icons.map_rounded, Icons.map_outlined, 'Map'),
    _NavItem('/alerts', Icons.notifications_rounded,
        Icons.notifications_outlined, 'Alerts'),
    _NavItem('/settings', Icons.person_rounded, Icons.person_outline_rounded,
        'Profile'),
  ];

  int _locationToIndex(String location) {
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) {
            context.go(_destinations[i].path);
          },
          destinations: _destinations.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isSelected = i == currentIndex;

            Widget icon = Icon(isSelected ? item.activeIcon : item.icon);

            // Badge for alerts tab
            if (item.path == '/alerts' && unreadAlerts > 0) {
              icon = Badge(
                label: Text('$unreadAlerts'),
                backgroundColor: AppColors.error,
                child: icon,
              );
            }

            return NavigationDestination(
              icon: icon,
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.activeIcon, this.icon, this.label);

  final String path;
  final IconData activeIcon;
  final IconData icon;
  final String label;
}
