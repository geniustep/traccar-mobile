// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use the WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elmogps/app/app.dart';
import 'package:elmogps/shared/providers/core_providers.dart';
import 'package:elmogps/shared/providers/traccar_providers.dart';

void main() {
  testWidgets('ElmoApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Match main.dart: SharedPreferences must resolve before the tree builds
    // (providers like [authRepositoryProvider] assume prefs are ready), and the
    // socket service must be wired to the concrete implementation.
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) async => prefs),
        traccarSocketServiceProvider.overrideWith(
          (ref) => ref.read(concreteSocketServiceProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sharedPreferencesProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ElmoApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(ElmoApp), findsOneWidget);
  });
}
