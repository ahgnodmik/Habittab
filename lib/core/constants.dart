import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Brand accent color.
final Color kPointColor = const Color(0xFF0A6CF1);

/// Default habit color as an ARGB int (matches [kPointColor]).
const int kDefaultHabitColor = 0xFF0A6CF1;

/// Preset swatches offered by the color picker.
const List<Color> kHabitPalette = [
  Color(0xFF0A6CF1),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFF6B7280),
];

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Canonical storage/display key for a calendar day.
String dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
