import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/constants.dart';
import 'services/habit_store.dart';
import 'services/widget_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
    await MobileAds.instance.initialize();
  }
  runApp(const HabittabApp());
}

/// Handles taps from the Android home widget. `habittab://toggle?index=N`
/// toggles today's check for the habit at list position N, using the same
/// id-based store the app uses (so schema stays consistent).
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host != 'toggle') return;
  final index = int.tryParse(uri?.queryParameters['index'] ?? '');
  if (index == null) return;

  final store = HabitStore();
  final state = await store.load();
  if (index < 0 || index >= state.habits.length) return;

  final todayKey = dateKey(DateTime.now());
  HabitStore.toggle(state.checkedByDate, todayKey, state.habits[index].id);
  await store.save(state);
  await syncHomeWidget(state.habits, state.checkedOn(todayKey));
}
