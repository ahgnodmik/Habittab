// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myHabits => 'My Habits';

  @override
  String get export => 'Export';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get themeUpdated => 'Theme updated';

  @override
  String get userGuide => 'User Guide';

  @override
  String get userGuideContent =>
      '1) Tap a habit to toggle check.\n2) Pick a date to view/edit other days.\n3) Drawer → Wide Checker to view monthly marks.\n4) Export to save CSV in documents.';

  @override
  String get appInfoDescription => 'A simple habit tracker.';

  @override
  String get addHabit => 'Add Habit';

  @override
  String get habitName => 'Habit name';

  @override
  String get color => 'Color';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get selectHabitToEdit => 'Select Habit to Edit';

  @override
  String get noHabitsToEdit => 'No habits to edit';

  @override
  String get uncheckHabit => 'Uncheck habit';

  @override
  String get checkHabit => 'Check habit';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get editHabitTitle => 'Edit Habit';

  @override
  String get deleteHabit => 'Delete habit';

  @override
  String get deleteHabitTitle => 'Delete Habit';

  @override
  String get deleteHabitConfirm =>
      'Are you sure you want to delete this habit?';

  @override
  String get details => 'Details';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisWeekTitle => 'This Week';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get changeTheme => 'Change Theme';

  @override
  String get badges => 'Badges';

  @override
  String get wideChecker => 'Wide Checker';

  @override
  String get editHabits => 'Edit Habits';

  @override
  String get appInfo => 'App Info';

  @override
  String get openSourceLicenses => 'Open-source Licenses';

  @override
  String get ad => 'Ad';

  @override
  String get longPressTip => 'Tip: Long-press an item to edit';

  @override
  String get noHabitsYet => 'No habits yet';

  @override
  String get noBadgesYet => 'No badges yet';

  @override
  String weeklyBestTotal(int best, int total) {
    return 'Weekly best: ${best}d  ·  Total: $total';
  }

  @override
  String streakCount(int count) {
    return '${count}d';
  }

  @override
  String get badgeDay1Title => 'Day 1';

  @override
  String get badgeDay1Subtitle => 'First step';

  @override
  String get badge3DaysTitle => '3 Days';

  @override
  String get badge3DaysSubtitle => '3-day streak';

  @override
  String get badge7DaysTitle => '7 Days';

  @override
  String get badge7DaysSubtitle => '1-week streak';

  @override
  String get badge14DaysTitle => '14 Days';

  @override
  String get badge14DaysSubtitle => '2-week streak';

  @override
  String get badge30DaysTitle => '30 Days';

  @override
  String get badge30DaysSubtitle => '1-month streak';

  @override
  String get badge60DaysTitle => '60 Days';

  @override
  String get badge60DaysSubtitle => '2-month streak';

  @override
  String get badge90DaysTitle => '90 Days';

  @override
  String get badge90DaysSubtitle => '3-month streak';

  @override
  String get badge180DaysTitle => '180 Days';

  @override
  String get badge180DaysSubtitle => '6-month streak';

  @override
  String get badge365DaysTitle => '365 Days';

  @override
  String get badge365DaysSubtitle => '1-year streak';
}
