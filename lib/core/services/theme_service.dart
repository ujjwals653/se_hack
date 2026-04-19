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
