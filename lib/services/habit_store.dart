import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/habit.dart';

/// Persists [HabitState] in SharedPreferences and migrates the legacy
/// index-based schema (`habits` / `habit_colors` / `habit_checks`) to the
/// id-based v2 schema on first load.
class HabitStore {
  static const habitsKey = 'habits_v2';
  static const checksKey = 'checks_v2';

  static const legacyHabitsKey = 'habits';
  static const legacyColorsKey = 'habit_colors';
  static const legacyChecksKey = 'habit_checks';

  Future<HabitState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getString(habitsKey);
    if (habitsJson != null) {
      return parse(habitsJson, prefs.getString(checksKey));
    }

    final legacy = migrateLegacy(
      habits: prefs.getStringList(legacyHabitsKey),
      colors: prefs.getStringList(legacyColorsKey),
      checksJson: prefs.getString(legacyChecksKey),
    );
    final state = legacy ?? HabitState.defaults();
    await save(state);
    return state;
  }

  Future<void> save(HabitState state) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(
        habitsKey,
        json.encode(state.habits.map((h) => h.toJson()).toList()),
      ),
      prefs.setString(checksKey, encodeChecks(state.checkedByDate)),
    ]);
  }

  // ── Pure helpers (unit-testable, no I/O) ──────────────────────────────────

  static String encodeChecks(Map<String, Set<String>> checks) {
    return json.encode(checks.map((date, ids) => MapEntry(date, ids.toList())));
  }

  static HabitState parse(String habitsJson, String? checksJson) {
    final habits = <Habit>[];
    try {
      final decoded = json.decode(habitsJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) habits.add(Habit.fromJson(item));
        }
      }
    } catch (_) {}

    final checkedByDate = <String, Set<String>>{};
    if (checksJson != null) {
      try {
        final decoded = json.decode(checksJson);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is List) {
              checkedByDate[entry.key] =
                  (entry.value as List).whereType<String>().toSet();
            }
          }
        }
      } catch (_) {}
    }

    if (habits.isEmpty) return HabitState.defaults();
    return HabitState(habits: habits, checkedByDate: checkedByDate);
  }

  /// Converts the legacy index-aligned schema to id-based [HabitState].
  /// Returns null when there is nothing to migrate.
  static HabitState? migrateLegacy({
    required List<String>? habits,
    required List<String>? colors,
    required String? checksJson,
  }) {
    final names =
        habits?.map((h) => h.trim()).where((h) => h.isNotEmpty).toList();
    if (names == null || names.isEmpty) return null;

    final colorInts = colors?.map(int.tryParse).toList() ?? const <int?>[];
    final models = <Habit>[
      for (int i = 0; i < names.length; i++)
        Habit(
          id: Habit.newId(),
          name: names[i],
          color:
              (i < colorInts.length ? colorInts[i] : null) ??
              kDefaultHabitColor,
        ),
    ];

    final checkedByDate = <String, Set<String>>{};
    if (checksJson != null) {
      try {
        final decoded = json.decode(checksJson);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is! List) continue;
            final bools = (entry.value as List);
            final ids = <String>{};
            for (int i = 0; i < models.length && i < bools.length; i++) {
              if (bools[i] == true) ids.add(models[i].id);
            }
            if (ids.isNotEmpty) checkedByDate[entry.key] = ids;
          }
        }
      } catch (_) {}
    }

    return HabitState(habits: models, checkedByDate: checkedByDate);
  }

  /// Toggles [habitId] on [key] within [checks], mutating and returning it.
  static Map<String, Set<String>> toggle(
    Map<String, Set<String>> checks,
    String key,
    String habitId,
  ) {
    final set = checks.putIfAbsent(key, () => <String>{});
    if (!set.remove(habitId)) set.add(habitId);
    if (set.isEmpty) checks.remove(key);
    return checks;
  }
}
