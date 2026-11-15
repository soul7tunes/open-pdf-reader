import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// App-wide settings, stored as a small JSON file in the app documents
/// directory. No account, no tracking, everything stays on the device.
class AppSettings extends ChangeNotifier {
  bool darkMode = false;

  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/settings.json');
      if (await file.exists()) {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        darkMode = data['darkMode'] == true;
      }
    } catch (_) {
      // First run or unreadable file: keep defaults.
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    notifyListeners();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/settings.json');
      await file.writeAsString(jsonEncode({'darkMode': value}));
    } catch (_) {
      // Settings stay in memory for this session if saving fails.
    }
  }
}
