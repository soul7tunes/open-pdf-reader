import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/recent_store.dart';
import 'viewer_screen.dart';

/// Home tab: open a PDF, scan the device for PDFs, recent files.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RecentFile> _recent = <RecentFile>[];
  List<File> _found = <File>[];
  bool _loadingRecent = true;
  bool _scanning = false;
  String? _scanNote;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final items = await RecentStore.load();
    if (!mounted) return;
    setState(() {
      _recent = items;
      _loadingRecent = false;
    });
  }

  Future<void> _openPdf(String path) async {
    await RecentStore.add(path);
    await _loadRecent();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(filePath: path),
      ),
    );
    await _loadRecent();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final path = picked.path;
    if (path != null) {
      await _openPdf(path);
    } else if (picked.bytes != null) {
      // Storage Access Framework sometimes returns bytes instead of a path.
      final dir = await Directory.systemTemp.createTemp('open_pdf_reader');
      final file = File('${dir.path}/${picked.name}');
      await file.writeAsBytes(picked.bytes!);
      await _openPdf(file.path);
    }
  }

  /// Asks for storage permission, then lists PDFs in Download/Documents.
  /// On Android 13+ the system limits automatic scanning, so the file
  /// picker ("Open a PDF") is always offered as the reliable fallback.
  Future<void> _scanDevice() async {
    setState(() {
      _scanning = true;
      _scanNote = null;
    });
    final status = await Permission.storage.request();
    if (!mounted) return;
    if (status.isPermanentlyDenied) {
      setState(() {
        _scanning = false;
        _scanNote =
            'Storage permission is off. Turn it on in App settings, or use "Open a PDF" instead.';
      });
      return;
    }
    final found = <File>[];
    const roots = <String>[
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
    ];
    for (final root in roots) {
      try {
        final dir = Directory(root);
        if (!await dir.exists()) continue;
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is File &&
              entity.path.toLowerCase().endsWith('.pdf')) {
            found.add(entity);
          }
        }
      } catch (_) {
        // One unreadable folder must not stop the scan.
      }
    }
    if (!mounted) return;
    setState(() {
      _found = found;
      _scanning = false;
      _scanNote = found.isEmpty
          ? 'No PDFs found in Download or Documents. '
              'On Android 13+ use "Open a PDF" to pick any file.'
          : 'Found ${found.length} PDF file(s) in Download / Documents.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open PDF Reader'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FilledButton.icon(
            onPressed: _pickPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Open a PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _scanning ? null : _scanDevice,
            icon: const Icon(Icons.search),
            label: Text(_scanning ? 'Scanning…' : 'Scan device for PDFs'),
          ),
          if (_scanNote != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_scanNote!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (_found.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('On this device',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._found.map(
              (file) => ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(file.path.split('/').last),
                subtitle: Text(file.path),
                onTap: () => _openPdf(file.path),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Recent files',
                  style: Theme.of(context).textTheme.titleMedium),
              if (_recent.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await RecentStore.clear();
                    await _loadRecent();
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingRecent)
            const Center(child: CircularProgressIndicator())
          else if (_recent.isEmpty)
            const Text(
              'No recent PDFs yet. Open a PDF to see it here.',
            )
          else
            ..._recent.map(
              (item) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(item.name),
                subtitle: Text(item.path),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove from recents',
                  onPressed: () async {
                    await RecentStore.remove(item.path);
                    await _loadRecent();
                  },
                ),
                onTap: () => _openPdf(item.path),
              ),
            ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Free forever • No ads • No subscription',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
