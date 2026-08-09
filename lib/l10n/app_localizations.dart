import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @myHabits.
  ///
  /// In en, this message translates to:
  /// **'My Habits'**
  String get myHabits;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @expandCalendar.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expandCalendar;

  /// No description provided for @collapseCalendar.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseCalendar;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @themeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme updated'**
  String get themeUpdated;

  /// No description provided for @userGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get userGuide;

  /// No description provided for @userGuideContent.
  ///
  /// In en, this message translates to:
  /// **'1) Tap a habit to toggle check.\n2) Pick a date to view/edit other days.\n3) Drawer → Wide Checker to view monthly marks.\n4) Export to save CSV in documents.'**
  String get userGuideContent;

  /// No description provided for @appInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple habit tracker.'**
  String get appInfoDescription;

  /// No description provided for @addHabit.
  ///
  /// In en, this message translates to:
  /// **'Add Habit'**
  String get addHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @selectHabitToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select Habit to Edit'**
  String get selectHabitToEdit;

  /// No description provided for @noHabitsToEdit.
  ///
  /// In en, this message translates to:
  /// **'No habits to edit'**
  String get noHabitsToEdit;

  /// No description provided for @uncheckHabit.
  ///
  /// In en, this message translates to:
  /// **'Uncheck habit'**
  String get uncheckHabit;

  /// No description provided for @checkHabit.
  ///
  /// In en, this message translates to:
  /// **'Check habit'**
  String get checkHabit;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabit;

  /// No description provided for @editHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Habit'**
  String get editHabitTitle;

  /// No description provided for @deleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete habit'**
  String get deleteHabit;

  /// No description provided for @deleteHabitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Habit'**
  String get deleteHabitTitle;

  /// No description provided for @deleteHabitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this habit?'**
  String get deleteHabitConfirm;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekTitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeTheme;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @wideChecker.
  ///
  /// In en, this message translates to:
  /// **'Wide Checker'**
  String get wideChecker;

  /// No description provided for @editHabits.
  ///
  /// In en, this message translates to:
  /// **'Edit Habits'**
  String get editHabits;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @ad.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get ad;

  /// No description provided for @longPressTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Long-press an item to edit'**
  String get longPressTip;

  /// No description provided for @noHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYet;

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges yet'**
  String get noBadgesYet;

  /// No description provided for @weeklyBestTotal.
  ///
  /// In en, this message translates to:
  /// **'Weekly best: {best}d  ·  Total: {total}'**
  String weeklyBestTotal(int best, int total);

  /// No description provided for @streakCount.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String streakCount(int count);

  /// No description provided for @badgeDay1Title.
  ///
  /// In en, this message translates to:
  /// **'Day 1'**
  String get badgeDay1Title;

  /// No description provided for @badgeDay1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get badgeDay1Subtitle;

  /// No description provided for @badge3DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'3 Days'**
  String get badge3DaysTitle;

  /// No description provided for @badge3DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get badge3DaysSubtitle;

  /// No description provided for @badge7DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get badge7DaysTitle;

  /// No description provided for @badge7DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1-week streak'**
  String get badge7DaysSubtitle;

  /// No description provided for @badge14DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'14 Days'**
  String get badge14DaysTitle;

  /// No description provided for @badge14DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'2-week streak'**
  String get badge14DaysSubtitle;

  /// No description provided for @badge30DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get badge30DaysTitle;

  /// No description provided for @badge30DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1-month streak'**
  String get badge30DaysSubtitle;

  /// No description provided for @badge60DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'60 Days'**
  String get badge60DaysTitle;

  /// No description provided for @badge60DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'2-month streak'**
  String get badge60DaysSubtitle;

  /// No description provided for @badge90DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get badge90DaysTitle;

  /// No description provided for @badge90DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'3-month streak'**
  String get badge90DaysSubtitle;

  /// No description provided for @badge180DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'180 Days'**
  String get badge180DaysTitle;

  /// No description provided for @badge180DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'6-month streak'**
  String get badge180DaysSubtitle;

  /// No description provided for @badge365DaysTitle.
  ///
  /// In en, this message translates to:
  /// **'365 Days'**
  String get badge365DaysTitle;

  /// No description provided for @badge365DaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1-year streak'**
  String get badge365DaysSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
