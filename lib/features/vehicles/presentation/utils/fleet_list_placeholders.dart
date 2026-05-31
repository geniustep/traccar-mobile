import '../../../../core/l10n/app_localizations.dart';

/// Détecte les textes « placeholder » à ne jamais afficher sur la liste flotte.
abstract final class FleetListPlaceholders {
  FleetListPlaceholders._();

  static const _driverTokens = {
    'no driver assigned',
    'conducteur non assigné',
    'conducteur non assigne',
    'sin conductor asignado',
    'لا يوجد سائق',
    'لا يوجد سائق مخصّص',
    'aucun conducteur',
    'unassigned driver',
    'n/a',
    'na',
    '-',
    '—',
  };

  static const _maintenanceTokens = {
    'no maintenance',
    'aucune maintenance',
    'sin mantenimiento',
    'لا توجد صيانة',
    'pas de maintenance',
  };

  static bool isBlank(String? value) {
    if (value == null) return true;
    final t = value.trim();
    return t.isEmpty;
  }

  static bool isDriverPlaceholder(String? value, AppLocalizations l10n) {
    if (isBlank(value)) return true;
    final t = value!.trim();
    if (t == l10n.fleetCardNoDriver.trim()) return true;
    return _matchesToken(t, _driverTokens);
  }

  static bool isMaintenancePlaceholder(String? value, AppLocalizations l10n) {
    if (isBlank(value)) return true;
    final t = value!.trim();
    if (t == l10n.fleetCardNoMaintenance.trim()) return true;
    return _matchesToken(t, _maintenanceTokens);
  }

  static bool isDisplayableDriver(String? value, AppLocalizations l10n) {
    return !isDriverPlaceholder(value, l10n);
  }

  static bool isDisplayableMaintenance(String? value, AppLocalizations l10n) {
    return !isMaintenancePlaceholder(value, l10n);
  }

  static bool _matchesToken(String text, Set<String> tokens) {
    final lower = text.toLowerCase();
    if (tokens.contains(lower)) return true;
    for (final token in tokens) {
      if (lower.startsWith('$token ') || lower.endsWith(' $token')) {
        return true;
      }
    }
    return false;
  }
}
