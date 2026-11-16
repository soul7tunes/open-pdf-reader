import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/pdf_tools.dart';
import '../services/recent_store.dart';
import '../theme/app_theme.dart';
import 'tool_detail_screen.dart';
import 'viewer_screen.dart';

/// Home tab V2: glass header with logo, big gradient Open button,
/// glass search, quick-tools bento grid, recent files as glass cards
/// with swipe-to-remove and staggered entrance.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _RecentView {
  const _RecentView(this.item, this.sizeLabel, this.dateLabel);

  final RecentFile item;
  final String sizeLabel;
  final String dateLabel;
}

class _HomeScreenState extends State<HomeScreen> {
  List<_RecentView> _recent = <_RecentView>[];
  List<File> _found = <File>[];
  bool _loadingRecent = true;
  bool _scanning = false;
  String? _scanNote;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecent();
    // V2.1 fix: scan automatically when Home first opens, so the PDFs
    // already on the device show up without the user tapping anything.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scanDevice(auto: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime at) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${at.day}/${at.month}/${at.year}';
  }

  Future<void> _loadRecent() async {
    final items = await RecentStore.load();
    final views = <_RecentView>[];
    for (final item in items) {
      var size = '';
      try {
        size = prettySize(await File(item.path).length());
      } catch (_) {
        size = '';
      }
      views.add(_RecentView(item, size, _dateLabel(item.openedAt)));
    }
    if (!mounted) return;
    setState(() {
      _recent = views;
      _loadingRecent = false;
    });
  }

  Future<void> _openPdf(String path) async {
    await RecentStore.add(path);
    await _loadRecent();
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => PdfViewerScreen(filePath: path),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
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
      final dir = await Directory.systemTemp.createTemp('open_pdf_reader');
      final file = File('${dir.path}/${picked.name}');
      await file.writeAsBytes(picked.bytes!);
      await _openPdf(file.path);
    }
  }

  /// Asks for storage permission, then lists PDFs in the common folders.
  /// V2.1: runs automatically when Home opens ([auto] true), covers
  /// Download/Documents/DCIM/Pictures/WhatsApp/Telegram plus the app's
  /// own folder where created PDFs are saved, and caps the list at 100
  /// files (newest first). On Android 13+ the system limits automatic
  /// scanning, so the file picker ("Open a PDF") is always offered as
  /// the reliable fallback.
  Future<void> _scanDevice({bool auto = false}) async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _scanNote = null;
    });
    final status = await Permission.storage.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _scanning = false;
        _scanNote = auto
            ? 'Storage permission is off, so device files cannot be listed. '
                'Use "Open a PDF" to pick a file, or turn permission on in '
                'App settings.'
            : 'Storage permission is off. Turn it on in App settings, or use "Open a PDF" instead.';
      });
      return;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final roots = <String>[
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Pictures',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Android/media/com.whatsapp.WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Telegram/Telegram Documents',
      '/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Documents',
      docsDir.path,
    ];
    final found = <File>[];
    final seen = <String>{};
    for (final root in roots) {
      try {
        final dir = Directory(root);
        if (!await dir.exists()) continue;
        await for (final entity
            in dir.list(recursive: true, followLinks: false)) {
          if (entity is File &&
              entity.path.toLowerCase().endsWith('.pdf') &&
              seen.add(entity.path)) {
            found.add(entity);
          }
        }
      } catch (_) {
        // One unreadable folder must not stop the scan.
      }
    }
    // Newest first, capped so a huge library does not flood the list.
    final withDates = <({File file, DateTime modified})>[];
    for (final f in found) {
      try {
        withDates.add((file: f, modified: await f.lastModified()));
      } catch (_) {
        withDates.add((file: f, modified: DateTime(2000)));
      }
    }
    withDates.sort((a, b) => b.modified.compareTo(a.modified));
    final newest = withDates.take(100).map((e) => e.file).toList();
    if (!mounted) return;
    setState(() {
      _found = newest;
      _scanning = false;
      _scanNote = newest.isEmpty
          ? 'No PDFs found on this device. '
              'On Android 13+ use "Open a PDF" to pick any file.'
          : 'Found ${newest.length} PDF file(s) on this device.';
    });
  }

  List<_RecentView> get _filteredRecent {
    if (_query.isEmpty) return _recent;
    final q = _query.toLowerCase();
    return _recent
        .where((v) => v.item.name.toLowerCase().contains(q))
        .toList();
  }

  List<File> get _filteredFound {
    if (_query.isEmpty) return _found;
    final q = _query.toLowerCase();
    return _found
        .where((f) => f.path.split('/').last.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = _filteredRecent;
    final found = _filteredFound;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/media-generation-open-pdf-reader-logo-0-58ab363c-35be-4eac-8392-cf66afd8768a.webp',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Open PDF Reader',
                    style: theme.textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Read, edit and share PDFs',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _scanDevice();
          await _loadRecent();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
          Text(
            'Your PDFs,\nbeautifully simple.',
            style: theme.textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          StaggeredIn(
            index: 0,
            child: GradientButton(
              label: 'Open a PDF',
              icon: Icons.picture_as_pdf,
              onPressed: _pickPdf,
            ),
          ),
          const SizedBox(height: 12),
          StaggeredIn(
            index: 1,
            child: GlassButton(
              label: _scanning ? 'Scanning…' : 'Scan device for PDFs',
              icon: Icons.search,
              enabled: !_scanning,
              onPressed: _scanDevice,
            ),
          ),
          if (_scanNote != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_scanNote!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 20),
          StaggeredIn(
            index: 2,
            child: GlassSearchBar(
              controller: _searchController,
              hint: 'Search your PDFs…',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Quick tools', style: theme.textTheme.titleLarge),
              Text(
                '${PdfTool.values.length} tools',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.pink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Fixed tall cells so two-line short titles (e.g.
              // "Image → PDF") never overflow the card.
              mainAxisExtent: 124,
            ),
            itemCount: PdfTool.values.length,
            itemBuilder: (context, i) {
              final tool = PdfTool.values[i];
              return StaggeredIn(
                index: 3 + i,
                child: PressScale(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ToolDetailScreen(tool: tool),
                    ),
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    radius: 22,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GradientIconChip(
                          icon: tool.icon,
                          size: 52,
                          gradient: tool.gradient,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tool.shortTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (found.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'On this device (${found.length})',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...found.asMap().entries.map(
              (entry) {
                final file = entry.value;
                final name = file.path.split('/').last;
                return StaggeredIn(
                  index: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FileCard(
                      name: name,
                      subtitle: file.path,
                      heroTag: 'pdf-icon-device-$name',
                      onTap: () => _openPdf(file.path),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Recent files', style: theme.textTheme.titleLarge),
              if (_recent.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await RecentStore.clear();
                    await _loadRecent();
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontFamily: AppType.headingFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingRecent)
            const Center(child: CircularProgressIndicator())
          else if (recent.isEmpty)
            GlassCard(
              child: Row(
                children: <Widget>[
                  const GradientIconChip(
                    icon: Icons.picture_as_pdf,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _query.isEmpty
                          ? 'No recent PDFs yet.\nOpen a PDF to see it here.'
                          : 'Nothing matches "$_query".',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recent.asMap().entries.map(
              (entry) {
                final view = entry.value;
                final subtitle = <String>[
                  if (view.sizeLabel.isNotEmpty) view.sizeLabel,
                  view.dateLabel,
                ].join('  •  ');
                return StaggeredIn(
                  index: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey<String>(view.item.path),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.pink.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (_) async {
                        await RecentStore.remove(view.item.path);
                        await _loadRecent();
                      },
                      child: _FileCard(
                        name: view.item.name,
                        subtitle: subtitle,
                        heroTag: 'pdf-icon-${view.item.path}',
                        onTap: () => _openPdf(view.item.path),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Open PDF Reader • Version 1.2.0',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// One glass file row with a gradient PDF icon chip.
class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.name,
    required this.subtitle,
    required this.heroTag,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressScale(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: <Widget>[
            Hero(
              tag: heroTag,
              child: const GradientIconChip(
                icon: Icons.picture_as_pdf,
                size: 52,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 26,
              color: context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
