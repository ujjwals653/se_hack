import 'package:flutter/material.dart';

/// A simple [ChangeNotifier] that toggles between light and dark mode.
///
/// Provided at the root of the widget tree so any descendant can read
/// or toggle the current [ThemeMode].
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

/// Extension on [BuildContext] to quickly grab dark-mode aware colors
/// without importing Theme everywhere or writing verbose ternaries.
///
/// Usage:
///   context.scaffoldBg
///   context.cardBg
///   context.textPrimary
///   context.isDark
extension DarkThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  Color get scaffoldBg => isDark ? const Color(0xFF121212) : Colors.white;
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get surfaceBg => isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
  Color get headerBg => isDark ? const Color(0xFF1A1A2E) : const Color(0xFF4C4D7B);

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get textPrimary => isDark ? Colors.white : Colors.black;
  Color get textSecondary => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get textTertiary => isDark ? Colors.grey.shade500 : Colors.grey;
  Color get textOnHeader => Colors.white;

  // ── Borders / Dividers ───────────────────────────────────────────────────
  Color get dividerColor => isDark ? Colors.grey.shade800 : Colors.grey.shade200;
  Color get borderColor => isDark ? Colors.grey.shade700 : Colors.grey.shade200;
  Color get shimmerBase => isDark ? Colors.grey.shade800 : Colors.grey.shade200;
  Color get shimmerHighlight => isDark ? Colors.grey.shade700 : Colors.grey.shade100;

  // ── Chat ─────────────────────────────────────────────────────────────────
  Color get chatInputBg => isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
  Color get chatOtherBubbleBg => isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
  Color get chatInputBarBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  // ── Common app colors (always the same) ──────────────────────────────────
  static const Color primary = Color(0xFF4C4D7B);
  static const Color accent = Color(0xFF7B61FF);
}
