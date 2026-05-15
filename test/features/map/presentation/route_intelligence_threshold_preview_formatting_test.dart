import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/route_intelligence_threshold_resolution.dart';
import 'package:elmogps/features/map/presentation/utils/route_intelligence_threshold_preview_formatting.dart';

void main() {
  group('routeIntelFormatSourceLabel', () {
    test('maps all enum values (en)', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(
        routeIntelFormatSourceLabel(
            RouteIntelligenceThresholdSource.device, l10n),
        l10n.routeIntelSourceDevice,
      );
      expect(
        routeIntelFormatSourceLabel(RouteIntelligenceThresholdSource.group, l10n),
        l10n.routeIntelSourceGroup,
      );
      expect(
        routeIntelFormatSourceLabel(RouteIntelligenceThresholdSource.user, l10n),
        l10n.routeIntelSourceUser,
      );
      expect(
        routeIntelFormatSourceLabel(RouteIntelligenceThresholdSource.local, l10n),
        l10n.routeIntelSourceLocal,
      );
      expect(
        routeIntelFormatSourceLabel(
            RouteIntelligenceThresholdSource.defaults, l10n),
        l10n.routeIntelSourceDefault,
      );
    });
  });

  group('routeIntelFormatBool', () {
    test('enabled / disabled (en)', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(routeIntelFormatBool(true, l10n), l10n.routeIntelEnabled);
      expect(routeIntelFormatBool(false, l10n), l10n.routeIntelDisabled);
    });
  });

  group('routeIntelFormatSpeedDisplay', () {
    test('integer km/h omits fraction (en)', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(
        routeIntelFormatSpeedDisplay(90, l10n),
        l10n.routeIntelSpeedKmh('90'),
      );
    });
  });

  group('routeIntelThresholdPreviewRows', () {
    test('sources follow resolution for overspeed', () {
      final l10n = AppLocalizations(const Locale('en'));
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
        groupAttributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
        },
      );
      final rows = routeIntelThresholdPreviewRows(r, l10n);
      final ov = rows.firstWhere(
        (x) => x.label == l10n.routeIntelOverspeedThreshold,
      );
      expect(ov.source, RouteIntelligenceThresholdSource.group);
      expect(ov.value, contains('90'));
    });

    test('seven rows', () {
      final l10n = AppLocalizations(const Locale('en'));
      final r =
          RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources();
      expect(routeIntelThresholdPreviewRows(r, l10n).length, 7);
    });
  });
}
