import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habittab/app.dart';
import 'package:habittab/core/constants.dart';
import 'package:habittab/services/habit_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _habitJson(String id, String name) => {
  'id': id,
  'name': name,
  'color': kDefaultHabitColor,
};

void main() {
  const iosOnly = TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS});

  group('HabitStore pure logic', () {
    test('migrateLegacy maps index-based checks to habit ids', () {
      final today = dateKey(DateTime.now());
      final state = HabitStore.migrateLegacy(
        habits: ['One', 'Two', 'Three'],
        colors: null,
        checksJson: json.encode({
          today: [true, false, true],
        }),
      );
      expect(state, isNotNull);
      expect(state!.habits.map((h) => h.name), ['One', 'Two', 'Three']);
      final checked = state.checkedOn(today);
      expect(checked, {state.habits[0].id, state.habits[2].id});
    });

    test('migrateLegacy returns null with no legacy habits', () {
      expect(
        HabitStore.migrateLegacy(habits: null, colors: null, checksJson: null),
        isNull,
      );
    });

    test('toggle adds then removes, dropping empty days', () {
      final checks = <String, Set<String>>{};
      HabitStore.toggle(checks, '2026-01-01', 'a');
      expect(checks['2026-01-01'], {'a'});
      HabitStore.toggle(checks, '2026-01-01', 'a');
      expect(checks.containsKey('2026-01-01'), isFalse);
    });

    test('parse round-trips habits and checks', () {
      final habitsJson = json.encode([
        _habitJson('a', 'Alpha'),
        _habitJson('b', 'Beta'),
      ]);
      final checksJson = HabitStore.encodeChecks({
        '2026-01-01': {'a'},
      });
      final state = HabitStore.parse(habitsJson, checksJson);
      expect(state.habits.map((h) => h.id), ['a', 'b']);
      expect(state.isChecked('2026-01-01', 'a'), isTrue);
      expect(state.isChecked('2026-01-01', 'b'), isFalse);
    });
  });

  testWidgets('renders habits from stored v2 state', variant: iosOnly, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'habits_v2': json.encode([
        _habitJson('a', 'Stretch'),
        _habitJson('b', 'Journal'),
      ]),
      'checks_v2': json.encode(<String, List<String>>{}),
      'long_press_tip_shown': true,
    });

    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    expect(find.text('Stretch'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Drink Water'), findsNothing);
  });

  testWidgets('migrates legacy schema on first load', variant: iosOnly, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = dateKey(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'habits': <String>['One', 'Two', 'Three'],
      'habit_checks': json.encode(<String, List<bool>>{
        today: <bool>[true],
      }),
      'long_press_tip_shown': true,
    });

    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('habits_v2'), isNotNull);
  });

  testWidgets('tapping a habit persists its checked state', variant: iosOnly, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'habits_v2': json.encode([
        _habitJson('a', 'Alpha'),
        _habitJson('b', 'Beta'),
      ]),
      'checks_v2': json.encode(<String, List<String>>{}),
      'long_press_tip_shown': true,
    });

    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final decoded =
        json.decode(prefs.getString('checks_v2')!) as Map<String, dynamic>;
    final today = (decoded[dateKey(DateTime.now())] as List).cast<String>();
    expect(today, ['a']);
  });
}
