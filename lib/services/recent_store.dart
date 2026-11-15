import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One recently opened PDF. Stored locally only.
class RecentFile {
  const RecentFile({
    required this.path,
    required this.name,
    required this.openedAt,
  });

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        path: json['path'] as String,
        name: json['name'] as String,
        openedAt: DateTime.tryParse(json['openedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String path;
  final String name;
  final DateTime openedAt;

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'openedAt': openedAt.toIso8601String(),
      };
}

/// Persists the recent-files list as JSON in the app documents directory.
/// Keeps at most 20 entries, newest first. No data leaves the device.
class RecentStore {
  static const int _maxEntries = 20;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/recents.json');
  }

  static Future<List<RecentFile>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return <RecentFile>[];
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      final items = data
          .map((e) => RecentFile.fromJson(e as Map<String, dynamic>))
          .toList();
      // Drop entries whose file no longer exists.
      final existing = <RecentFile>[];
      for (final item in items) {
        if (await File(item.path).exists()) existing.add(item);
      }
      return existing;
    } catch (_) {
      return <RecentFile>[];
    }
  }

  static Future<void> add(String path) async {
    final name = path.split('/').last;
    final items = await load();
    items.removeWhere((e) => e.path == path);
    items.insert(
      0,
      RecentFile(path: path, name: name, openedAt: DateTime.now()),
    );
    await _save(items.take(_maxEntries).toList());
  }

  static Future<void> remove(String path) async {
    final items = await load();
    items.removeWhere((e) => e.path == path);
    await _save(items);
  }

  static Future<void> clear() async {
    await _save(<RecentFile>[]);
  }

  static Future<void> _save(List<RecentFile> items) async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Recents are a convenience; failing to save must not break the app.
    }
  }
}
