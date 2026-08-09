import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../models/habit.dart';

/// Pushes the current habit list and today's checked state to the Android home
/// widget. The widget contract stays index-based: titles and checks are aligned
/// to habit list order. No-ops on platforms without a widget host.
Future<void> syncHomeWidget(
  List<Habit> habits,
  Set<String> todayChecked,
) async {
  final titles = habits.map((h) => h.name).toList();
  final checks = habits.map((h) => todayChecked.contains(h.id)).toList();
  try {
    await HomeWidget.saveWidgetData('habit_titles', json.encode(titles));
    await HomeWidget.saveWidgetData('habit_checks', json.encode(checks));
    await HomeWidget.updateWidget(name: 'HabitWidgetProvider');
  } on MissingPluginException {
    // Desktop/web: no home widget.
  } on PlatformException {
    // No widget host.
  }
}
