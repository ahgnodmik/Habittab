import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habittab/app.dart';
import 'package:habittab/core/constants.dart';
import 'package:habittab/services/habit_store.dart';

/// On-device scenario coverage. Seeds a known v2 state so the run is
/// deterministic regardless of any data already on the device.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> seed() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      HabitStore.habitsKey,
      '[{"id":"seed-a","name":"Alpha","color":$kDefaultHabitColor},'
      '{"id":"seed-b","name":"Beta","color":$kDefaultHabitColor}]',
    );
    await prefs.setString(HabitStore.checksKey, '{}');
    await prefs.setBool('long_press_tip_shown', true);
    // Force English so text-based finders are locale-independent.
    await prefs.setString('locale', 'en');
  }

  testWidgets('launch, toggle, add and delete a habit', (tester) async {
    await seed();
    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    // Seeded habits render.
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    // Toggle Alpha, confirm it persisted under the id-based schema.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    final store = HabitStore();
    var state = await store.load();
    expect(state.isChecked(dateKey(DateTime.now()), 'seed-a'), isTrue);

    // Add a habit through the dialog.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ITEST');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(find.text('ITEST'), findsOneWidget);

    // The new habit got a generated id distinct from the seeds.
    state = await store.load();
    final added = state.habits.firstWhere((h) => h.name == 'ITEST');
    expect(added.id, isNot(anyOf('seed-a', 'seed-b')));

    // Delete it via the row overflow menu.
    final row = find.ancestor(
      of: find.text('ITEST'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('ITEST'), findsNothing);
  });

  testWidgets('navigate to badges and back', (tester) async {
    await seed();
    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Badges'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
  });
}
