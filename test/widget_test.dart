import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habittab/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const iosOnly = TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS});

  testWidgets('restores saved habits and colors', variant: iosOnly, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'habits': <String>['Stretch', 'Journal'],
      'habit_colors': <String>[
        const Color(0xFF0A6CF1).toARGB32().toString(),
        const Color(0xFF0A6CF1).toARGB32().toString(),
      ],
      'habit_checks': json.encode(<String, List<bool>>{}),
      'long_press_tip_shown': true,
    });

    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    expect(find.text('Stretch'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Drink Water'), findsNothing);
  });

  testWidgets('normalizes a shorter saved check list', variant: iosOnly, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    SharedPreferences.setMockInitialValues({
      'habits': <String>['One', 'Two', 'Three'],
      'habit_colors': <String>[
        const Color(0xFF0A6CF1).toARGB32().toString(),
        const Color(0xFF0A6CF1).toARGB32().toString(),
        const Color(0xFF0A6CF1).toARGB32().toString(),
      ],
      'habit_checks': json.encode(<String, List<bool>>{
        dateKey: <bool>[true],
      }),
      'long_press_tip_shown': true,
    });

    await tester.pumpWidget(const HabittabApp());
    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
