import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StrkThemeMode { dark, light, custom }

enum CustomBgMode { dark, light }

class ThemeProvider extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'theme_accent';
  static const _customBgKey = 'theme_custom_bg';

  StrkThemeMode _mode = StrkThemeMode.dark;
  Color _customAccent = const Color(0xFFFF6B00);
  CustomBgMode _customBg = CustomBgMode.dark;

  StrkThemeMode get mode => _mode;
  Color get customAccent => _customAccent;
  CustomBgMode get customBg => _customBg;

  Color get accent {
    switch (_mode) {
      case StrkThemeMode.dark:
        return const Color(0xFFFF6B00);
      case StrkThemeMode.light:
        return const Color(0xFFFF6B00);
      case StrkThemeMode.custom:
        return _customAccent;
    }
  }

  bool get isLight {
    switch (_mode) {
      case StrkThemeMode.dark:
        return false;
      case StrkThemeMode.light:
        return true;
      case StrkThemeMode.custom:
        return _customBg == CustomBgMode.light;
    }
  }

  Color get bg => isLight ? const Color(0xFFF5F5F5) : const Color(0xFF0D0D0D);
  Color get surface =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
  Color get surfaceAlt =>
      isLight ? const Color(0xFFF0F0F0) : const Color(0xFF2C2C2C);
  Color get textPrimary =>
      isLight ? const Color(0xFF111111) : const Color(0xFFE8E8E8);
  Color get textSecondary => textPrimary.withValues(alpha: 0.5);
  Color get textHint => textPrimary.withValues(alpha: 0.25);
  Color get divider =>
      isLight ? const Color(0xFFDDDDDD) : const Color(0xFF222222);
  Color get inputFill =>
      isLight ? const Color(0xFFF0F0F0) : const Color(0xFF2C2C2C);
  Color get cardBorder => textPrimary.withValues(alpha: 0.06);

  ThemeData get themeData => ThemeData(
    brightness: isLight ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: isLight
        ? ColorScheme.light(
            primary: accent,
            secondary: accent,
            surface: surface,
          )
        : ColorScheme.dark(
            primary: accent,
            secondary: accent,
            surface: surface,
          ),
    fontFamily: 'SF Pro Display',
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? accent : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? accent.withValues(alpha: 0.3)
            : null,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
    appBarTheme: AppBarTheme(backgroundColor: bg, elevation: 0),
    dialogTheme: DialogThemeData(backgroundColor: surface),
  );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = StrkThemeMode.values[(prefs.getInt(_modeKey) ?? 0).clamp(0, 2)];
    _customAccent = Color(prefs.getInt(_accentKey) ?? 0xFFFF6B00);
    _customBg =
        CustomBgMode.values[(prefs.getInt(_customBgKey) ?? 0).clamp(0, 1)];
    notifyListeners();
  }

  Future<void> setMode(StrkThemeMode mode) async {
    _mode = mode;
    await SharedPreferences.getInstance().then(
      (p) => p.setInt(_modeKey, mode.index),
    );
    notifyListeners();
  }

  Future<void> setCustomAccent(Color color) async {
    _customAccent = color;
    await SharedPreferences.getInstance().then(
      (p) => p.setInt(_accentKey, color.toARGB32()),
    );
    notifyListeners();
  }

  Future<void> setCustomBg(CustomBgMode bg) async {
    _customBg = bg;
    await SharedPreferences.getInstance().then(
      (p) => p.setInt(_customBgKey, bg.index),
    );
    notifyListeners();
  }
}

class ThemeProviderScope extends InheritedNotifier<ThemeProvider> {
  const ThemeProviderScope({
    super.key,
    required ThemeProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static ThemeProvider of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(scope != null, 'ThemeProviderScope não encontrado na árvore');
    return scope!.notifier!;
  }
}
