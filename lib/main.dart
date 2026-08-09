import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habittab/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

final Color kPointColor = const Color(0xFF0A6CF1);
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
const String _habitsKey = 'habits';
const String _habitColorsKey = 'habit_colors';
const String _habitChecksKey = 'habit_checks';

List<bool> _normalizedChecks(List<bool>? checks, int habitCount) {
  final normalized = List<bool>.from(checks ?? const <bool>[]);
  if (normalized.length > habitCount) {
    normalized.removeRange(habitCount, normalized.length);
  }
  while (normalized.length < habitCount) {
    normalized.add(false);
  }
  return normalized;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
    await MobileAds.instance.initialize();
  }
  runApp(const HabittabApp());
}

class HabittabApp extends StatefulWidget {
  const HabittabApp({super.key});

  @override
  State<HabittabApp> createState() => _HabittabAppState();
}

class _HabittabAppState extends State<HabittabApp> {
  bool _isDarkMode = false;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadLocale();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('is_dark_mode');
    if (saved != null && mounted) {
      setState(() => _isDarkMode = saved);
    }
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    // 기존 is_korean 키 마이그레이션
    final isKorean = prefs.getBool('is_korean');
    if (isKorean != null) {
      final locale = isKorean ? const Locale('ko') : const Locale('en');
      await prefs.setString('locale', locale.languageCode);
      await prefs.remove('is_korean');
      if (mounted) setState(() => _locale = locale);
      return;
    }
    final code = prefs.getString('locale');
    if (code != null && mounted) {
      setState(() => _locale = Locale(code));
    }
  }

  void _updateTheme(bool isDarkMode) {
    setState(() => _isDarkMode = isDarkMode);
  }

  void _updateLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habittab',
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPointColor,
          primary: kPointColor,
          secondary: kPointColor,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0E3830),
          iconTheme: IconThemeData(color: Color(0xFF0E3830)),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPointColor,
          primary: kPointColor,
          secondary: kPointColor,
          surface: const Color(0xFF1E1E1E),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1E1E1E)),
        useMaterial3: true,
      ),
      home: HabitListPage(
        onThemeChanged: _updateTheme,
        onLocaleChanged: _updateLocale,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}

class HabitListPage extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;

  const HabitListPage({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage>
    with WidgetsBindingObserver {
  final List<String> _habits = [
    'Drink Water',
    'Morning Exercise',
    'Read a Book',
  ];
  final List<Color> _habitColors = [
    const Color(0xFF0A6CF1),
    const Color(0xFF0A6CF1),
    const Color(0xFF0A6CF1),
  ];

  Map<String, List<bool>> _habitChecks = {};
  DateTime _selectedDate = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showLongPressTip = false;
  bool _showAdBanner = true;
  bool _isDarkMode = false;
  String _appVersion = '';

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  static const String _releaseBannerAdUnitId =
      'ca-app-pub-8527804772343765/3592237283';
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  String get _bannerAdUnitId =>
      kReleaseMode ? _releaseBannerAdUnitId : _testBannerAdUnitId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChecks();
    _loadTheme();
    _loadAppVersion();
    _maybeShowLongPressTooltip();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _loadBannerAd();
    } else {
      _showAdBanner = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadChecks(persist: false);
    }
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  List<bool> _checksFor(String key) {
    return _normalizedChecks(_habitChecks[key], _habits.length);
  }

  Future<void> _loadChecks({bool persist = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHabits = prefs.getStringList(_habitsKey);
    final savedColors = prefs.getStringList(_habitColorsKey);
    final data = prefs.getString(_habitChecksKey);

    final loadedHabits =
        savedHabits?.map((h) => h.trim()).where((h) => h.isNotEmpty).toList();
    final loadedColors =
        savedColors?.map(int.tryParse).whereType<int>().map(Color.new).toList();
    final loadedChecks = <String, List<bool>>{};

    if (data != null) {
      try {
        final decoded = json.decode(data);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is List) {
              loadedChecks[entry.key] = List<bool>.from(entry.value as List);
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      if (loadedHabits != null) {
        _habits
          ..clear()
          ..addAll(loadedHabits);
      }
      if (loadedColors != null && loadedColors.length == _habits.length) {
        _habitColors
          ..clear()
          ..addAll(loadedColors);
      } else {
        _habitColors
          ..clear()
          ..addAll(List<Color>.filled(_habits.length, kPointColor));
      }
      _habitChecks = loadedChecks.map(
        (key, checks) =>
            MapEntry(key, _normalizedChecks(checks, _habits.length)),
      );
    });

    if (persist) await _saveHabitData();
    await _updateHomeWidget();
  }

  Future<void> _saveHabitData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setStringList(_habitsKey, _habits),
      prefs.setStringList(
        _habitColorsKey,
        _habitColors.map((c) => c.toARGB32().toString()).toList(),
      ),
      prefs.setString(_habitChecksKey, json.encode(_habitChecks)),
    ]);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('is_dark_mode');
    if (saved != null && mounted) {
      setState(() => _isDarkMode = saved);
    }
  }

  Future<void> _saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDarkMode);
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  Future<void> _maybeShowLongPressTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('long_press_tip_shown') ?? false;
    if (shown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _showLongPressTip = true);
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() => _showLongPressTip = false);
      await prefs.setBool('long_press_tip_shown', true);
    });
  }

  void _changeLanguage() async {
    final l10n = context.l10n;
    final currentCode = Localizations.localeOf(context).languageCode;
    final selected = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.selectLanguage),
            content: RadioGroup<String>(
              groupValue: currentCode,
              onChanged: (v) => Navigator.pop(ctx, v),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(value: 'ko', title: Text('한국어')),
                  RadioListTile<String>(value: 'en', title: Text('English')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
            ],
          ),
    );
    if (selected != null) {
      widget.onLocaleChanged?.call(Locale(selected));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.languageUpdated)));
    }
  }

  void _changeTheme() async {
    final l10n = context.l10n;
    final selected = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.selectTheme),
            content: RadioGroup<bool>(
              groupValue: _isDarkMode,
              onChanged: (v) => Navigator.pop(ctx, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    value: false,
                    title: Text(l10n.lightMode),
                  ),
                  RadioListTile<bool>(value: true, title: Text(l10n.darkMode)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
            ],
          ),
    );
    if (selected != null) {
      setState(() => _isDarkMode = selected);
      _saveTheme(selected);
      widget.onThemeChanged?.call(selected);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.themeUpdated)));
    }
  }

  void _showUserGuide() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.userGuide),
            content: SingleChildScrollView(child: Text(l10n.userGuideContent)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
            ],
          ),
    );
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationName: 'Habittab',
      applicationVersion: _appVersion,
      applicationLegalese: '© 2024 Habittab. All rights reserved.',
      children: [
        const SizedBox(height: 8),
        Text(context.l10n.appInfoDescription),
      ],
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Habittab',
      applicationVersion: _appVersion,
      applicationLegalese: '© 2024 Habittab',
    );
  }

  void _addHabit() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final color = ValueNotifier<Color>(kPointColor);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final textColor =
            Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
        return AlertDialog(
          backgroundColor: Theme.of(ctx).dialogTheme.backgroundColor,
          title: Text(l10n.addHabit, style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: l10n.habitName,
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.color, style: TextStyle(color: textColor)),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<Color>(
                valueListenable: color,
                builder:
                    (_, c, __) => _ColorPicker(
                      selected: c,
                      onSelected: (picked) => color.value = picked,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel, style: TextStyle(color: kPointColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.add, style: TextStyle(color: kPointColor)),
            ),
          ],
        );
      },
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      setState(() {
        _habits.add(controller.text.trim());
        _habitColors.add(color.value);
        for (final key in _habitChecks.keys.toList()) {
          _habitChecks[key] = _checksFor(key);
        }
      });
      await _saveHabitData();
      await _updateHomeWidget();
    }
  }

  Future<void> _openEditHabitPicker() async {
    final l10n = context.l10n;
    if (_habits.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noHabitsToEdit)));
      return;
    }
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final textColor =
            Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
        return AlertDialog(
          backgroundColor: Theme.of(ctx).dialogTheme.backgroundColor,
          title: Text(
            l10n.selectHabitToEdit,
            style: TextStyle(color: textColor),
          ),
          content: SizedBox(
            width: 320,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _habits.length,
              itemBuilder:
                  (_, index) => ListTile(
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _habitColors[index % _habitColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      _habits[index],
                      style: TextStyle(color: textColor),
                    ),
                    onTap: () => Navigator.pop(ctx, index),
                  ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close, style: TextStyle(color: kPointColor)),
            ),
          ],
        );
      },
    );
    if (selectedIndex != null) {
      _editHabit(selectedIndex);
    }
  }

  void _toggleHabit(int index) {
    setState(() {
      final checks = _checksFor(_dateKey);
      checks[index] = !checks[index];
      _habitChecks[_dateKey] = checks;
    });
    _saveHabitData();
    _updateHomeWidget();
  }

  void _toggleHabitWithHaptics(int index) {
    HapticFeedback.selectionClick();
    _toggleHabit(index);
  }

  void _onHabitLongPress(int index) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isChecked = _checksFor(_dateKey)[index];
        final textColor =
            Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: kPointColor,
                ),
                title: Text(
                  isChecked ? l10n.uncheckHabit : l10n.checkHabit,
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleHabitWithHaptics(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: kPointColor),
                title: Text(l10n.editHabit, style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editHabit(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  l10n.deleteHabit,
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteHabit(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: kPointColor),
                title: Text(l10n.details, style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editHabit(int index) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: _habits[index]);
    Color selectedColor = _habitColors[index % _habitColors.length];
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: Text(l10n.editHabitTitle),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: l10n.habitName),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l10n.color),
                      ),
                      const SizedBox(height: 10),
                      _ColorPicker(
                        selected: selectedColor,
                        onSelected:
                            (picked) =>
                                setDialogState(() => selectedColor = picked),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
          ),
    );
    if (result == true) {
      setState(() {
        _habits[index] =
            nameController.text.trim().isEmpty
                ? _habits[index]
                : nameController.text.trim();
        _habitColors[index] = selectedColor;
      });
      await _saveHabitData();
      await _updateHomeWidget();
    }
  }

  Future<void> _deleteHabit(int index) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.deleteHabitTitle),
            content: Text(l10n.deleteHabitConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
    if (confirm == true) {
      setState(() {
        final oldCount = _habits.length;
        for (final key in _habitChecks.keys.toList()) {
          final checks = _normalizedChecks(_habitChecks[key], oldCount);
          if (index < checks.length) {
            checks.removeAt(index);
            _habitChecks[key] = checks;
          }
        }
        _habits.removeAt(index);
        _habitColors.removeAt(index);
      });
      await _saveHabitData();
      await _updateHomeWidget();
    }
  }

  Widget _buildHabitItem({
    required int index,
    required bool checked,
    required String habit,
  }) {
    return Dismissible(
      key: ValueKey('habit-$index-$_dateKey'),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: kPointColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.check, color: kPointColor),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: kPointColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.check, color: kPointColor),
      ),
      confirmDismiss: (direction) async {
        _toggleHabitWithHaptics(index);
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleHabitWithHaptics(index),
          onLongPress: () => _onHabitLongPress(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  checked
                      ? kPointColor.withValues(alpha: 0.08)
                      : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: checked ? kPointColor : Theme.of(context).dividerColor,
                width: 1,
              ),
              boxShadow: [
                if (checked)
                  BoxShadow(
                    color: kPointColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: checked ? kPointColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPointColor, width: 2),
                  ),
                  child:
                      checked
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          checked
                              ? kPointColor
                              : Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showHabitMoreMenu(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  splashRadius: 18,
                  icon: Icon(
                    Icons.more_vert,
                    color:
                        checked
                            ? kPointColor
                            : Theme.of(context).iconTheme.color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHabitMoreMenu(int index) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isChecked = _checksFor(_dateKey)[index];
        final textColor =
            Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: kPointColor),
                title: Text(l10n.editHabit, style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _editHabit(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_view_week, color: kPointColor),
                title: Text(l10n.thisWeek, style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showHabitWeek(index);
                },
              ),
              ListTile(
                leading: Icon(
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: kPointColor,
                ),
                title: Text(
                  isChecked ? l10n.uncheckHabit : l10n.checkHabit,
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleHabitWithHaptics(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  l10n.deleteHabit,
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteHabit(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHabitWeek(int index) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.thisWeekTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final day in days)
                  Builder(
                    builder: (context) {
                      final key = DateFormat('yyyy-MM-dd').format(day);
                      final isChecked = _checksFor(key)[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isChecked
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isChecked ? kPointColor : Colors.grey,
                        ),
                        title: Text(DateFormat('EEE, MMM d').format(day)),
                      );
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
            ],
          ),
    );
  }

  Future<void> _updateHomeWidget() async {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final checks = _checksFor(todayKey);
    try {
      await HomeWidget.saveWidgetData('habit_titles', json.encode(_habits));
      await HomeWidget.saveWidgetData('habit_checks', json.encode(checks));
      await HomeWidget.updateWidget(name: 'HabitWidgetProvider');
    } on MissingPluginException {
      // Desktop/web 환경에서는 홈 위젯 미지원
    } on PlatformException {
      // 위젯 호스트 없음
    }
  }

  static String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportData() async {
    final l10n = context.l10n;
    final allDates = _habitChecks.keys.toList()..sort();
    final buffer = StringBuffer();
    buffer.writeln('Date,${_habits.map(_csvCell).join(',')}');
    for (final date in allDates) {
      final checks = _checksFor(date);
      buffer.writeln('$date,${checks.map((e) => e ? '1' : '0').join(',')}');
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/habits_export.csv');
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Habittab export'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, err) {
          if (mounted) setState(() => _isBannerAdReady = false);
          ad.dispose();
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _showAdBanner) _loadBannerAd();
          });
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final checks = _checksFor(_dateKey);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myHabits),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _exportData,
            tooltip: l10n.export,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habittab',
                      style: TextStyle(
                        fontSize: 24,
                        color: kPointColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _appVersion.isEmpty ? 'Habittab' : 'Version $_appVersion',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '© 2024 Habittab. All rights reserved.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.changeLanguage),
                onTap: () {
                  Navigator.pop(context);
                  _changeLanguage();
                },
              ),
              ListTile(
                leading: Icon(
                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.changeTheme),
                onTap: () {
                  Navigator.pop(context);
                  _changeTheme();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.addHabit),
                onTap: () {
                  Navigator.pop(context);
                  _addHabit();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.userGuide),
                onTap: () {
                  Navigator.pop(context);
                  _showUserGuide();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.emoji_events_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.badges),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => BadgesPage(
                            habits: _habits,
                            habitChecks: _habitChecks,
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.calendar_view_month,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.wideChecker),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => WideCheckerPage(
                            habits: _habits,
                            habitChecks: _habitChecks,
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_note_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.editHabits),
                onTap: () {
                  Navigator.pop(context);
                  _openEditHabitPicker();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.appInfo),
                onTap: () {
                  Navigator.pop(context);
                  _showAppInfo();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.article_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                title: Text(l10n.openSourceLicenses),
                onTap: () {
                  Navigator.pop(context);
                  _showLicenses();
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _selectedDate,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() => _selectedDate = selectedDay);
                  },
                  calendarFormat: _calendarFormat,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: kPointColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: kPointColor,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: kPointColor,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final key = DateFormat('yyyy-MM-dd').format(day);
                      final checks = _checksFor(key);
                      final doneIndices = <int>[];
                      for (int i = 0; i < checks.length; i++) {
                        if (checks[i]) doneIndices.add(i);
                      }
                      if (doneIndices.isEmpty) return null;
                      final toShow = doneIndices.take(4).toList();
                      return Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final idx in toShow)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color:
                                      _habitColors[idx % _habitColors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: kPointColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kPointColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: kPointColor),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kPointColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    bottom:
                        _showAdBanner
                            ? 58 + MediaQuery.of(context).padding.bottom
                            : MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final checked = checks[index];
                    return Column(
                      children: [
                        _buildHabitItem(
                          index: index,
                          checked: checked,
                          habit: habit,
                        ),
                        if (index == _habits.length - 1)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                            child: OutlinedButton.icon(
                              onPressed: _addHabit,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addHabit),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (_showLongPressTip)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showLongPressTip ? 1 : 0,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app, color: Colors.white70),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.longPressTip,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_showAdBanner)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        child:
                            _isBannerAdReady && _bannerAd != null
                                ? AdWidget(ad: _bannerAd!)
                                : Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: kPointColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: kPointColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.ad,
                                      style: TextStyle(
                                        color: kPointColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showAdBanner = false),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).iconTheme.color,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Wide Checker ─────────────────────────────────────────────────────────────

class WideCheckerPage extends StatefulWidget {
  final List<String> habits;
  final Map<String, List<bool>> habitChecks;
  const WideCheckerPage({
    super.key,
    required this.habits,
    required this.habitChecks,
  });

  @override
  State<WideCheckerPage> createState() => _WideCheckerPageState();
}

class _WideCheckerPageState extends State<WideCheckerPage> {
  int _selectedHabitIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wideChecker)),
        body: Center(child: Text(l10n.noHabitsYet)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wideChecker)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<int>(
              value: _selectedHabitIndex,
              items: List.generate(widget.habits.length, (index) {
                return DropdownMenuItem<int>(
                  value: index,
                  child: Text(widget.habits[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) setState(() => _selectedHabitIndex = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: kPointColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: kPointColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: kPointColor,
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) {
                  final key = DateFormat('yyyy-MM-dd').format(day);
                  final checks = _normalizedChecks(
                    widget.habitChecks[key],
                    widget.habits.length,
                  );
                  return checks[_selectedHabitIndex];
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final key = DateFormat('yyyy-MM-dd').format(day);
                    final checks = _normalizedChecks(
                      widget.habitChecks[key],
                      widget.habits.length,
                    );
                    if (checks[_selectedHabitIndex]) {
                      return Container(
                        decoration: BoxDecoration(
                          color: kPointColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: kPointColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: kPointColor),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: kPointColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class BadgesPage extends StatelessWidget {
  final List<String> habits;
  final Map<String, List<bool>> habitChecks;
  const BadgesPage({
    super.key,
    required this.habits,
    required this.habitChecks,
  });

  int _computeStreak(int habitIndex) {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      final checks = habitChecks[key] ?? List.filled(habits.length, false);
      if (habitIndex >= checks.length || !checks[habitIndex]) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _computeWeeklyBest(int habitIndex) {
    int best = 0;
    final start = DateTime.now();
    for (int w = 0; w < 8; w++) {
      int count = 0;
      for (int i = 0; i < 7; i++) {
        final day = start.subtract(Duration(days: w * 7 + i));
        final key = DateFormat('yyyy-MM-dd').format(day);
        final checks = habitChecks[key] ?? List.filled(habits.length, false);
        if (habitIndex < checks.length && checks[habitIndex]) count++;
      }
      if (count > best) best = count;
    }
    return best;
  }

  int _computeTotal(int habitIndex) {
    int total = 0;
    for (final entry in habitChecks.entries) {
      final checks = entry.value;
      if (habitIndex < checks.length && checks[habitIndex]) total++;
    }
    return total;
  }

  List<_Badge> _badgesFor(int streak, AppLocalizations l10n) {
    return [
      if (streak >= 1)
        _Badge(l10n.badgeDay1Title, l10n.badgeDay1Subtitle, Icons.star_border),
      if (streak >= 3)
        _Badge(l10n.badge3DaysTitle, l10n.badge3DaysSubtitle, Icons.star_half),
      if (streak >= 7)
        _Badge(l10n.badge7DaysTitle, l10n.badge7DaysSubtitle, Icons.star),
      if (streak >= 14)
        _Badge(
          l10n.badge14DaysTitle,
          l10n.badge14DaysSubtitle,
          Icons.emoji_events_outlined,
        ),
      if (streak >= 30)
        _Badge(
          l10n.badge30DaysTitle,
          l10n.badge30DaysSubtitle,
          Icons.military_tech_outlined,
        ),
      if (streak >= 60)
        _Badge(
          l10n.badge60DaysTitle,
          l10n.badge60DaysSubtitle,
          Icons.workspace_premium_outlined,
        ),
      if (streak >= 90)
        _Badge(
          l10n.badge90DaysTitle,
          l10n.badge90DaysSubtitle,
          Icons.workspace_premium,
        ),
      if (streak >= 180)
        _Badge(
          l10n.badge180DaysTitle,
          l10n.badge180DaysSubtitle,
          Icons.verified,
        ),
      if (streak >= 365)
        _Badge(
          l10n.badge365DaysTitle,
          l10n.badge365DaysSubtitle,
          Icons.verified_user,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (habits.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.badges)),
        body: Center(child: Text(l10n.noHabitsYet)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.badges)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final streak = _computeStreak(index);
          final badges = _badgesFor(streak, l10n);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: kPointColor),
                      const SizedBox(width: 8),
                      Text(
                        habits[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.streakCount(streak),
                        style: TextStyle(
                          color: kPointColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_week,
                        size: 18,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.weeklyBestTotal(
                          _computeWeeklyBest(index),
                          _computeTotal(index),
                        ),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        badges.isEmpty
                            ? [
                              Text(
                                l10n.noBadgesYet,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ]
                            : badges
                                .map(
                                  (b) => GestureDetector(
                                    onTap: () => _showBadgeDetail(context, b),
                                    child: Chip(
                                      avatar: Icon(
                                        b.icon,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: Text(b.title),
                                      backgroundColor: kPointColor,
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Badge(this.title, this.subtitle, this.icon);
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;
  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in kHabitPalette)
          GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      c.toARGB32() == selected.toARGB32()
                          ? Colors.black
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child:
                  c.toARGB32() == selected.toARGB32()
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
          ),
      ],
    );
  }
}

void _showBadgeDetail(BuildContext context, _Badge badge) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(badge.icon, color: kPointColor),
              const SizedBox(width: 8),
              Text(badge.title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.whatshot, size: 72, color: kPointColor),
              const SizedBox(height: 12),
              Text(badge.subtitle),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.ok),
            ),
          ],
        ),
  );
}

// ─── Background callback (홈 위젯) ────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host != 'toggle') return;
  final index = int.tryParse(uri?.queryParameters['index'] ?? '');
  if (index == null) return;

  final prefs = await SharedPreferences.getInstance();
  final habits = prefs.getStringList(_habitsKey) ?? const <String>[];
  if (index < 0 || index >= habits.length) return;

  final data = prefs.getString(_habitChecksKey);
  final checksByDate = <String, List<bool>>{};
  if (data != null) {
    try {
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          if (entry.value is List) {
            checksByDate[entry.key] = List<bool>.from(entry.value as List);
          }
        }
      }
    } catch (_) {
      return;
    }
  }

  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final todayChecks = _normalizedChecks(checksByDate[todayKey], habits.length);
  todayChecks[index] = !todayChecks[index];
  checksByDate[todayKey] = todayChecks;

  await prefs.setString(_habitChecksKey, json.encode(checksByDate));
  await HomeWidget.saveWidgetData('habit_titles', json.encode(habits));
  await HomeWidget.saveWidgetData('habit_checks', json.encode(todayChecks));
  await HomeWidget.updateWidget(name: 'HabitWidgetProvider');
}
