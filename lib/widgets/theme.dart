import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  static const String _themeKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false; 
    notifyListeners();
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  void toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _saveThemePreference(isDark);
    notifyListeners();
  }
}

enum PageType {
  calendar,
  recommendation,
  home,
  jobs,
  settings,
}

class MyTheme {
  static const Color lightPrimary = Color(0xFF6F4F7E);
  static const Color lightSecondary = Color(0xFFAA74C3);
  static const Color lightAccent = Color(0xFF87A236);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE0E0E0);

  static const Color darkPrimary = Color(0xFF8A6B9A);
  static const Color darkSecondary = Color(0xFFAA74C3);
  static const Color darkAccent = Color(0xFF87A236);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkBorder = Color(0xFF333333);

  static const Map<PageType, LinearGradient> _lightModeGradients = {
    PageType.calendar: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2B1735),
        Color(0xFF582A6D),
        Color(0xFFFFFFFF),
      ],
      stops: [0.0, 0.39, 0.74],
    ),
    PageType.recommendation: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF3E1E4C),
        Color(0xFF582A6D),
        Color(0xFF813BA1),
      ],
      stops: [0.0, 0.39, 0.74],
    ),
    PageType.home: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2B1735),
        Color(0xFF582A6D),
        Color(0xFFFFFFFF),
      ],
      stops: [0.0, 0.39, 0.88],
    ),
    PageType.jobs: LinearGradient(
      colors: [Color(0xFF582A6D), Color(0xFF2B1735)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    PageType.settings: LinearGradient(
      colors: [Color(0xFF582A6D), Color(0xFF2B1735)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  };

  static const Map<PageType, LinearGradient> _darkModeGradients = {
    PageType.calendar: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF100729),
        Color(0xFF392A4F),
        Color(0xFFE8E0E8),
      ],
      stops: [0.0, 0.39, 0.74],
    ),
    PageType.recommendation: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF100729),
        Color(0xFF2B2141),
        Color(0xFF392A4F),
      ],
      stops: [0.0, 0.39, 0.74],
    ),
    PageType.home: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF100729),
        Color(0xFF422E5A),
        Color(0xFFE8E0E8),
      ],
      stops: [0.10, 0.39, 0.87],
    ),
    PageType.jobs: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF100729),
        Color(0xFF2B2141),
        Color(0xFF392A4F),
      ],
      stops: [0.0, 0.59, 0.84],
    ),
    PageType.settings: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF100729),
        Color(0xFF2B2141),
        Color(0xFF392A4F),
      ],
      stops: [0.00, 0.59, 0.84],
    ),
  };

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: MaterialColor(0xFF6F4F7E, {
      50: Color(0xFFF3F0F4),
      100: Color(0xFFE1DAE4),
      200: Color(0xFFCDC1D2),
      300: Color(0xFFB9A8C0),
      400: Color(0xFFAA95B2),
      500: Color(0xFF9B82A4),
      600: Color(0xFF8A6B9A),
      700: Color(0xFF7A5A8A),
      800: Color(0xFF6F4F7E),
      900: Color(0xFF5A3E65),
    }),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightText,
      elevation: 0,
      iconTheme: IconThemeData(color: lightText),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    iconTheme: IconThemeData(color: Color(0xFFFEFEFE)),
    dividerColor: lightBorder,
    colorScheme: ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightText,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(0xFF8A6B9A, {
      50: Color(0xFF04053C),
      100: Color(0xFF6F4F7E),
      200: Color(0xFF7A5A8A),
      300: Color(0xFF8A6B9A),
      400: Color(0xFF9B82A4),
      500: Color(0xFFAA95B2),
      600: Color(0xFFB9A8C0),
      700: Color(0xFFCDC1D2),
      800: Color(0xFFE1DAE4),
      900: Color(0xFFF3F0F4),
    }),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      iconTheme: IconThemeData(color: darkText),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: darkText, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: darkText, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: darkText),
      bodyMedium: TextStyle(color: darkText),
      bodySmall: TextStyle(color: darkTextSecondary),
    ),
    iconTheme: IconThemeData(color: Color(0xFFE8E0E8)),
    dividerColor: darkBorder,
    colorScheme: ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkText,
    ),
  );

  static Color getSettingsTextColor(bool isDark) {
    return isDark ? Color(0xFFE8E0E8) : Color(0xFFFFFFFF);
  }

  static Color getSettingsSecondaryTextColor(bool isDark) {
    return isDark ? darkTextSecondary : lightTextSecondary;
  }

  static Color getSettingsSectionTitleColor(bool isDark) {
    return isDark ? Color(0xFFB89FDA) : Color(0xFFE1ADFF);
  }

  static Color getCardBackgroundColor(bool isDark) {
    return isDark ? Color.fromARGB(26, 255, 255, 255) : Color.fromARGB(26, 0, 0, 0);
  }

  static Color getAccentGreen() {
    return darkAccent; 
  }

  static Color getDeleteRed() {
    return Colors.redAccent; 
  }

  static Color getProfileColor() {
    return Color(0xFFAA74C3);
  }

  static LinearGradient getPageGradient(PageType pageType, bool isDark) {
    return isDark
        ? _darkModeGradients[pageType]!
        : _lightModeGradients[pageType]!;
  }

  static BoxDecoration getPageBackground(PageType pageType, bool isDark) {
    return BoxDecoration(
      gradient: getPageGradient(pageType, isDark),
    );
  }

  static BoxDecoration getCalendarBackground(bool isDark) {
    return getPageBackground(PageType.calendar, isDark);
  }

  static BoxDecoration getRecommendationBackground(bool isDark) {
    return getPageBackground(PageType.recommendation, isDark);
  }

  static BoxDecoration getHomeBackground(bool isDark) {
    return getPageBackground(PageType.home, isDark);
  }

  static BoxDecoration getJobsBackground(bool isDark) {
    return getPageBackground(PageType.jobs, isDark);
  }

  static BoxDecoration getSettingsBackground(bool isDark) {
    return getPageBackground(PageType.settings, isDark);
  }
}