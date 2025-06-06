import 'package:flutter/material.dart';
import 'package:mangax/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TheameProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  Color _accentColor = Colors.blueAccent; // Default accent color
  bool _isAmmoled = false;

  TheameProvider() {
    _initSettings();
  }

  Future<void> _initSettings() async {
    // Simulate fetching settings from shared preferences
    _prefs = await SharedPreferences.getInstance();
    _accentColor =
        _prefs.getString(Settings.accentColor.value) != null
            ? Color(int.parse(_prefs.getString(Settings.accentColor.value)!))
            : _accentColor;
    _isAmmoled = _prefs.getBool(Settings.isAmmoled.value) ?? _isAmmoled;
    notifyListeners();
  }

  ThemeData getTheme() {
    final colorscheme = ColorScheme.fromSeed(
      seedColor: _accentColor,
      brightness: Brightness.dark,
      primary: _accentColor,
      surface: _isAmmoled ? Colors.black : null,
      onSurface: Colors.white,
      surfaceContainerHighest:
          _isAmmoled ? Colors.black : Colors.black.withValues(alpha: 0.3),
    );
    return ThemeData(colorScheme: colorscheme, useMaterial3: true);
  }

  void setAccentColor(Color color) {
    // Save the accent color to shared preferences
    _prefs.setString(Settings.accentColor.value, color.toARGB32().toString());
    _accentColor = color;
    notifyListeners();
  }

  void setIsAmmoled(bool isAmmoled) {
    // Save the amoled setting to shared preferences
    _prefs.setBool(Settings.isAmmoled.value, isAmmoled);
    _isAmmoled = isAmmoled;
    notifyListeners();
  }
}
