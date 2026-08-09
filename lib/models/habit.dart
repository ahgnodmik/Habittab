import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';

/// A single habit with a stable identity independent of list position.
class Habit {
  final String id;
  String name;
  int color;

  Habit({required this.id, required this.name, required this.color});

  Color get colorValue => Color(color);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    color: (json['color'] as num).toInt(),
  );

  static final Random _rng = Random();

  /// Generates a process-unique id. Combines a monotonic timestamp with a
  /// random suffix so two habits created in the same microsecond still differ.
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(1 << 32)}';
}

/// The full in-memory habit dataset: ordered habits plus, per calendar day,
/// the set of habit ids checked that day. Keying checks by id (not list index)
/// keeps them correct across reordering and deletion.
class HabitState {
  final List<Habit> habits;
  final Map<String, Set<String>> checkedByDate;

  HabitState({required this.habits, required this.checkedByDate});

  factory HabitState.defaults() => HabitState(
    habits: [
      Habit(id: Habit.newId(), name: 'Drink Water', color: kDefaultHabitColor),
      Habit(
        id: Habit.newId(),
        name: 'Morning Exercise',
        color: kDefaultHabitColor,
      ),
      Habit(id: Habit.newId(), name: 'Read a Book', color: kDefaultHabitColor),
    ],
    checkedByDate: {},
  );

  Set<String> checkedOn(String key) => checkedByDate[key] ?? const <String>{};

  bool isChecked(String key, String habitId) =>
      checkedOn(key).contains(habitId);
}
