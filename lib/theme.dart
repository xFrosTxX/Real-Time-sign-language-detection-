import 'package:flutter/material.dart';

class Theme with ChangeNotifier {
  bool isDarkMode = false;
  ThemeMode get currentTheme => isDarkMode ? ThemeMode.dark : ThemeMode.light;
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
