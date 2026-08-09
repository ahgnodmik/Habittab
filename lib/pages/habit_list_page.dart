import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/constants.dart';
import '../models/habit.dart';
import '../services/habit_store.dart';
import '../services/widget_sync.dart';
import '../widgets/color_picker.dart';
import 'badges_page.dart';
import 'wide_checker_page.dart';

class HabitListPage extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  final Function(Locale)? onLocaleChanged;

  const HabitListPage({super.key, this.onThemeChanged, this.onLocaleChanged});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage>
    with WidgetsBindingObserver {
  final HabitStore _store = HabitStore();
  List<Habit> _habits = [];
  Map<String, Set<String>> _checked = {};

  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final ScrollController _listController = ScrollController();
  bool _showLongPressTip = false;
  bool _showAdBanner = true;
  bool _isDarkMode = false;
  String _appVersion = '';

  BannerAd? _bannerAd;
  Widget? _adWidget;
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
    _loadData();
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
      _loadData();
    }
  }

  String get _dateKey => dateKey(_selectedDate);

  Set<String> _checkedFor(String key) => _checked[key] ?? const <String>{};

  Future<void> _loadData() async {
    final state = await _store.load();
    if (!mounted) return;
    setState(() {
      _habits = state.habits;
      _checked = state.checkedByDate;
    });
    await _sync();
  }

  Future<void> _persist() async {
    await _store.save(HabitState(habits: _habits, checkedByDate: _checked));
    await _sync();
  }

  Future<void> _sync() async {
    final todayChecked = _checkedFor(dateKey(DateTime.now()));
    await syncHomeWidget(_habits, todayChecked);
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
                    (context, c, child) => ColorPicker(
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
        _habits.add(
          Habit(
            id: Habit.newId(),
            name: controller.text.trim(),
            color: color.value.toARGB32(),
          ),
        );
      });
      await _persist();
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
                        color: _habits[index].colorValue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      _habits[index].name,
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
      HabitStore.toggle(_checked, _dateKey, _habits[index].id);
    });
    _persist();
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
        final isChecked = _checkedFor(_dateKey).contains(_habits[index].id);
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
    final nameController = TextEditingController(text: _habits[index].name);
    Color selectedColor = _habits[index].colorValue;
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
                      ColorPicker(
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
        final name = nameController.text.trim();
        if (name.isNotEmpty) _habits[index].name = name;
        _habits[index].color = selectedColor.toARGB32();
      });
      await _persist();
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
        final removedId = _habits[index].id;
        _habits.removeAt(index);
        for (final ids in _checked.values) {
          ids.remove(removedId);
        }
        _checked.removeWhere((_, ids) => ids.isEmpty);
      });
      await _persist();
    }
  }

  Widget _buildHabitItem({required int index, required bool checked}) {
    final habit = _habits[index];
    return Dismissible(
      key: ValueKey('habit-${habit.id}-$_dateKey'),
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
                    habit.name,
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
        final isChecked = _checkedFor(_dateKey).contains(_habits[index].id);
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
    final id = _habits[index].id;
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
                      final isChecked = _checkedFor(dateKey(day)).contains(id);
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

  static String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportData() async {
    final l10n = context.l10n;
    final allDates = _checked.keys.toList()..sort();
    final buffer = StringBuffer();
    buffer.writeln('Date,${_habits.map((h) => _csvCell(h.name)).join(',')}');
    for (final date in allDates) {
      final ids = _checkedFor(date);
      buffer.writeln(
        '$date,${_habits.map((h) => ids.contains(h.id) ? '1' : '0').join(',')}',
      );
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
    _adWidget = null;
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
          setState(() {
            // Cache a single AdWidget so rebuilds reuse the same element
            // instead of re-inserting the ad ("already in the widget tree").
            _adWidget = AdWidget(ad: ad as BannerAd);
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = false;
              _adWidget = null;
            });
          }
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
    _listController.dispose();
    super.dispose();
  }

  /// Collapse/expand handle under the calendar. Toggles between the full
  /// month view and a compact single-week view. Large full-width tap target.
  Widget _buildCalendarHandle() {
    final l10n = context.l10n;
    final expanded = _calendarFormat == CalendarFormat.month;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _calendarFormat =
                expanded ? CalendarFormat.week : CalendarFormat.month;
          });
        },
        child: Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kPointColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: kPointColor,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expanded ? l10n.collapseCalendar : l10n.expandCalendar,
                    style: TextStyle(
                      color: kPointColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a date picker so the header acts as a month/year navigator.
  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final checkedToday = _checkedFor(_dateKey);
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
                            habits: List.of(_habits),
                            checkedByDate: {
                              for (final e in _checked.entries)
                                e.key: Set.of(e.value),
                            },
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
                            habits: List.of(_habits),
                            checkedByDate: {
                              for (final e in _checked.entries)
                                e.key: Set.of(e.value),
                            },
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
                  rowHeight: 42,
                  daysOfWeekHeight: 18,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() => _selectedDate = selectedDay);
                  },
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.week: 'Week',
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onHeaderTapped: (_) => _pickMonth(),
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
                      final ids = _checkedFor(dateKey(day));
                      if (ids.isEmpty) return null;
                      final colors =
                          <Color>[
                            for (final h in _habits)
                              if (ids.contains(h.id)) h.colorValue,
                          ].take(4).toList();
                      if (colors.isEmpty) return null;
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final c in colors)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: c,
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
              _buildCalendarHandle(),
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
                child: Scrollbar(
                  controller: _listController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _listController,
                    padding: EdgeInsets.only(
                      bottom:
                          _showAdBanner
                              ? 58 + MediaQuery.of(context).padding.bottom
                              : MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final checked = checkedToday.contains(_habits[index].id);
                      return Column(
                        children: [
                          _buildHabitItem(index: index, checked: checked),
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
                            _isBannerAdReady && _adWidget != null
                                ? _adWidget!
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
