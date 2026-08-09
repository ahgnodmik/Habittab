import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'l10n/app_localizations.dart';
import 'pages/habit_list_page.dart';

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
    // Migrate the old is_korean flag.
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
