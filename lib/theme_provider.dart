import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _currentTheme = ThemeMode.light; // <-- THIS IS THE ONE YOU NEED

  ThemeMode get currentTheme => _currentTheme;

  bool get isDarkMode => _currentTheme == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _currentTheme = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
