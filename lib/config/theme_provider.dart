import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _fontSize = 'medium';
  bool _voiceGuidance = false;

  bool get isDarkMode => _isDarkMode;
  String get fontSize => _fontSize;
  bool get voiceGuidance => _voiceGuidance;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _fontSize = prefs.getString('fontSize') ?? 'medium';
    _voiceGuidance = prefs.getBool('voiceGuidance') ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', value);
      notifyListeners();
    }
  }

  Future<void> setFontSize(String value) async {
    if (_fontSize != value) {
      _fontSize = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fontSize', value);
      notifyListeners();
    }
  }

  Future<void> setVoiceGuidance(bool value) async {
    if (_voiceGuidance != value) {
      _voiceGuidance = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voiceGuidance', value);
      notifyListeners();
    }
  }

  ThemeData get currentTheme {
    final baseTheme = _isDarkMode ? _darkTheme : _lightTheme;
    return _applyFontSize(baseTheme);
  }

  ThemeData _applyFontSize(ThemeData theme) {
    final scaleFactor = _getFontScaleFactor();
    
    // Create a new TextTheme with scaled font sizes
    final baseTextTheme = theme.textTheme;
    final scaledTextTheme = TextTheme(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: (baseTextTheme.displayLarge?.fontSize ?? 32) * scaleFactor,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: (baseTextTheme.displayMedium?.fontSize ?? 28) * scaleFactor,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: (baseTextTheme.displaySmall?.fontSize ?? 24) * scaleFactor,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 22) * scaleFactor,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 20) * scaleFactor,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 18) * scaleFactor,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: (baseTextTheme.titleLarge?.fontSize ?? 16) * scaleFactor,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: (baseTextTheme.titleMedium?.fontSize ?? 14) * scaleFactor,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: (baseTextTheme.titleSmall?.fontSize ?? 12) * scaleFactor,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: (baseTextTheme.labelSmall?.fontSize ?? 10) * scaleFactor,
      ),
    );
    
    return theme.copyWith(textTheme: scaledTextTheme);
  }

  double _getFontScaleFactor() {
    switch (_fontSize) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.2;
      case 'medium':
      default:
        return 1.0;
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4), // Teal/Turquoise
      primary: const Color(0xFF00BCD4),
      secondary: const Color(0xFF0097A7),
      brightness: Brightness.light,
    ),
    primaryColor: const Color(0xFF00BCD4),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF333333),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00BCD4),
        side: const BorderSide(color: Color(0xFF00BCD4), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF333333),
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF666666),
        fontFamily: 'Poppins',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4),
      primary: const Color(0xFF00BCD4),
      secondary: const Color(0xFF0097A7),
      brightness: Brightness.dark,
    ),
    primaryColor: const Color(0xFF00BCD4),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800, width: 1),
      ),
      color: const Color(0xFF2C2C2C),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00BCD4),
        side: const BorderSide(color: Color(0xFF00BCD4), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFFB0B0B0),
        fontFamily: 'Poppins',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(color: Color(0xFF666666)),
    ),
  );
}
