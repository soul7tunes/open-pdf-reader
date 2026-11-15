import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pdf_tools.dart';
import '../theme/app_theme.dart';
import 'viewer_screen.dart';

/// One PDF tool. In V2 every tool does real work — no placeholders.
enum PdfTool {
  merge(
    title: 'Merge PDF',
    shortTitle: 'Merge',
    description: 'Combine two or more PDFs into one file.',
    icon: Icons.merge_type,
    gradient: LinearGradient(
      colors: <Color>[AppColors.violet, AppColors.blue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  split(
    title: 'Split PDF',
    shortTitle: 'Split',
    description: 'Take selected pages out of a PDF.',
    icon: Icons.call_split,
    gradient: LinearGradient(
      colors: <Color>[AppColors.pink, AppColors.violet],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  compress(
    title: 'Compress PDF',
    shortTitle: 'Compress',
    description: 'Make a PDF smaller to share or store.',
    icon: Icons.compress,
    gradient: LinearGradient(
      colors: <Color>[AppColors.blue, AppColors.violet],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  imageToPdf(
    title: 'Image to PDF',
    shortTitle: 'Image → PDF',
    description: 'Turn photos into a PDF, one photo per page.',
    icon: Icons.image,
    gradient: LinearGradient(
      colors: <Color>[AppColors.violet, AppColors.pink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  pdfToImage(
    title: 'PDF to Image',
    shortTitle: 'PDF → Image',
    description: 'Save a PDF page as a PNG picture.',
    icon: Icons.photo,
    gradient: LinearGradient(
      colors: <Color>[AppColors.pink, AppColors.blue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  scan(
    title: 'Scan to PDF',
    shortTitle: 'Scan',
    description: 'Photograph pages with the camera and save them as a PDF.',
    icon: Icons.document_scanner,
    gradient: LinearGradient(
      colors: <Color>[AppColors.blue, AppColors.pink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  const PdfTool({
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String shortTitle;
  final String description;
  final IconData icon;
  final Gradient gradient;
}

class ToolDetailScreen extends StatefulWidget {
  const ToolDetailScreen({required this.tool, super.key});

  final PdfTool tool;

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

enum _CompressLevel { small, balanced, best }

extension on _CompressLevel {
  String get label {
    switch (this) {
      case _CompressLevel.small:
        return 'Small';
      case _CompressLevel.balanced:
        return 'Balanced';
      case _CompressLevel.best:
        return 'Best';
    }
  }

  int get quality {
    switch (this) {
      case _CompressLevel.small:
        return 45;
      case _CompressLevel.balanced:
        return 70;
      case _CompressLevel.best:
        return 90;
    }
  }

  int get maxWidth {
    switch (this) {
      case _CompressLevel.small:
        return 900;
      case _CompressLevel.balanced:
        return 1240;
      case _CompressLevel.best:
        return 1600;
    }
  }
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  List<String> _pickedPdfs = <String>[];
  List<String> _pickedImages = <String>[];
  List<int> _pickedPageCounts = <int>[];
  int _pageNumber = 1;
  int? _pageCount;
  File? _result;
  List<File> _results = <File>[];
  bool _working = false;
  String? _status;

  // Split controls.
  final TextEditingController _fromField = TextEditingController(text: '1');
  final TextEditingController _toField = TextEditingController(text: '1');
  bool _onePerPage = false;

  // Compress control.
  _CompressLevel _compressLevel = _CompressLevel.balanced;

  @override
  void dispose() {
    _fromField.dispose();
    _toField.dispose();
    super.dispose();
  }

  Future<void> _pickPdfs({bool multiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      allowMultiple: multiple,
    );
    if (result == null) return;
    final paths =
        result.files.map((f) => f.path).whereType<String>().toList();
    final counts = <int>[];
    for (final p in paths) {
      counts.add(await pdfPageCount(p) ?? 0);
    }
    setState(() {
      _pickedPdfs = paths;
      _pickedPageCounts = counts;
      _pageCount = paths.length == 1 && counts.isNotEmpty ? counts.first : null;
      if (_pageCount != null && _pageCount! > 0) {
        _pageNumber = 1;
        _fromField.text = '1';
        _toField.text = '$_pageCount';
      }
    });
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() {
      _pickedImages =
          result.files.map((f) => f.path).whereType<String>().toList();
    });
  }

  Future<void> _scanWithCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() => _pickedImages = <String>[photo.path]);
  }

  void _movePdf(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _pickedPdfs.length) return;
    setState(() {
      final path = _pickedPdfs.removeAt(index);
      final count = _pickedPageCounts.removeAt(index);
      _pickedPdfs.insert(next, path);
      _pickedPageCounts.insert(next, count);
    });
  }

  Future<void> _run() async {
    setState(() {
      _working = true;
      _status = null;
      _result = null;
      _results = <File>[];
    });
    try {
      switch (widget.tool) {
        case PdfTool.imageToPdf:
        case PdfTool.scan:
          if (_pickedImages.isEmpty) {
            setState(() => _status = 'Pick at least one image first.');
            return;
          }
          final pdf = await imagesToPdf(_pickedImages);
          setState(() {
            _result = pdf;
            _status = 'PDF created: ${fileNameOf(pdf.path)}';
          });
        case PdfTool.pdfToImage:
          if (_pickedPdfs.isEmpty) {
            setState(() => _status = 'Pick a PDF first.');
            return;
          }
          final image = await pdfPageToImage(_pickedPdfs.first, _pageNumber);
          setState(() {
            _result = image;
            _status = 'Page $_pageNumber saved as a PNG image.';
          });
        case PdfTool.merge:
          if (_pickedPdfs.length < 2) {
            setState(() => _status = 'Pick at least two PDFs to merge.');
            return;
          }
          final merged = await mergePdfs(_pickedPdfs);
          final totalPages =
              _pickedPageCounts.fold<int>(0, (a, b) => a + b);
          setState(() {
            _result = merged;
            _status =
                'Merged $totalPages pages from ${_pickedPdfs.length} PDFs into one file.';
          });
        case PdfTool.split:
          if (_pickedPdfs.isEmpty || _pageCount == null) {
            setState(() => _status = 'Pick a PDF first.');
            return;
          }
          final from = int.tryParse(_fromField.text.trim()) ?? 1;
          final to = int.tryParse(_toField.text.trim()) ?? _pageCount!;
          if (from < 1 || to < from || to > _pageCount!) {
            setState(
              () => _status =
                  'Enter a valid page range: 1 to $_pageCount, start before end.',
            );
            return;
          }
          final files = await splitPdf(
            _pickedPdfs.first,
            from: from,
            to: to,
            onePerPage: _onePerPage,
          );
          setState(() {
            _results = files;
            _result = files.first;
            _status = _onePerPage
                ? 'Split into ${files.length} separate PDFs.'
                : 'Pages $from–$to saved as a new PDF.';
          });
        case PdfTool.compress:
          if (_pickedPdfs.isEmpty) {
            setState(() => _status = 'Pick a PDF first.');
            return;
          }
          final before = await File(_pickedPdfs.first).length();
          final compressed = await compressPdf(
            _pickedPdfs.first,
            quality: _compressLevel.quality,
            maxWidth: _compressLevel.maxWidth,
          );
          final after = await compressed.length();
          final saved = before > 0
              ? ((1 - after / before) * 100).round()
              : 0;
          setState(() {
            _result = compressed;
            _status =
                'Done: ${prettySize(before)} → ${prettySize(after)}'
                ' ($saved% smaller).';
          });
      }
    } catch (e) {
      setState(() => _status = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _shareResult() async {
    final files = _results.isNotEmpty
        ? _results
        : (_result == null ? <File>[] : <File>[_result!]);
    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(files: files.map((f) => XFile(f.path)).toList()),
    );
  }

  void _openResultPdf() {
    if (_result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(filePath: _result!.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(tool.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          GlassCard(
            child: Row(
              children: <Widget>[
                GradientIconChip(
                  icon: tool.icon,
                  size: 60,
                  iconSize: 30,
                  gradient: tool.gradient,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    tool.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (tool == PdfTool.merge || tool == PdfTool.pdfToImage) ...<Widget>[
            GradientButton(
              label: tool == PdfTool.merge
                  ? 'Pick PDFs to merge'
                  : 'Pick a PDF',
              icon: Icons.picture_as_pdf,
              onPressed: () => _pickPdfs(multiple: tool == PdfTool.merge),
            ),
          ],
          if (tool == PdfTool.split || tool == PdfTool.compress) ...<Widget>[
            GradientButton(
              label: 'Pick a PDF',
              icon: Icons.picture_as_pdf,
              onPressed: () => _pickPdfs(),
            ),
          ],
          if (tool == PdfTool.imageToPdf) ...<Widget>[
            GradientButton(
              label: 'Pick images',
              icon: Icons.photo_library,
              onPressed: _pickImages,
            ),
          ],
          if (tool == PdfTool.scan) ...<Widget>[
            GradientButton(
              label: 'Take a photo',
              icon: Icons.camera_alt,
              onPressed: _scanWithCamera,
            ),
            const SizedBox(height: 12),
            GlassButton(
              label: 'Or pick images from gallery',
              icon: Icons.photo_library,
              onPressed: _pickImages,
            ),
          ],
          if (_pickedPdfs.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            ..._pickedPdfs.asMap().entries.map(
              (entry) {
                final i = entry.key;
                final p = entry.value;
                final pages = i < _pickedPageCounts.length
                    ? _pickedPageCounts[i]
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    radius: 20,
                    child: Row(
                      children: <Widget>[
                        const GradientIconChip(
                          icon: Icons.picture_as_pdf,
                          size: 48,
                          iconSize: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                fileNameOf(p),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pages > 0 ? '$pages pages' : p,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (tool == PdfTool.merge) ...<Widget>[
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 22),
                            tooltip: 'Move up',
                            onPressed: () => _movePdf(i, -1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 22),
                            tooltip: 'Move down',
                            onPressed: () => _movePdf(i, 1),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          tooltip: 'Remove',
                          onPressed: () => setState(() {
                            _pickedPdfs.removeAt(i);
                            if (i < _pickedPageCounts.length) {
                              _pickedPageCounts.removeAt(i);
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          if (_pickedImages.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            ..._pickedImages.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  radius: 20,
                  child: Row(
                    children: <Widget>[
                      const GradientIconChip(
                        icon: Icons.image_outlined,
                        size: 48,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileNameOf(p),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (tool == PdfTool.pdfToImage && _pageCount != null) ...<Widget>[
            const SizedBox(height: 20),
            Text('Choose a page', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GlassCard(
              radius: 20,
              child: Row(
                children: <Widget>[
                  Text('Page ', style: theme.textTheme.bodyLarge),
                  Expanded(
                    child: Slider(
                      value: _pageNumber.toDouble(),
                      min: 1,
                      max: _pageCount!.toDouble(),
                      divisions: _pageCount! - 1,
                      label: '$_pageNumber',
                      onChanged: (v) =>
                          setState(() => _pageNumber = v.round()),
                    ),
                  ),
                  Text(
                    '$_pageNumber / $_pageCount',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
          if (tool == PdfTool.split && _pageCount != null) ...<Widget>[
            const SizedBox(height: 20),
            Text('Page range', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GlassCard(
              radius: 20,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _PageField(
                      label: 'From',
                      controller: _fromField,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PageField(
                      label: 'To',
                      controller: _toField,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '/ $_pageCount',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              radius: 20,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'One file per page',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: _onePerPage,
                    onChanged: (v) => setState(() => _onePerPage = v),
                  ),
                ],
              ),
            ),
          ],
          if (tool == PdfTool.compress) ...<Widget>[
            const SizedBox(height: 20),
            Text('Quality', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: _CompressLevel.values.map((level) {
                final selected = level == _compressLevel;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PressScale(
                      onTap: () =>
                          setState(() => _compressLevel = level),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: selected
                              ? AppColors.brandGradient
                              : null,
                          color: selected ? null : context.glassFill,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : context.glassBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          level.label,
                          style: TextStyle(
                            fontFamily: AppType.headingFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Small: tiniest file · Balanced: good quality, much smaller · Best: near-original quality',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: _working ? 'Working…' : _runLabel(tool),
            icon: _working ? null : Icons.play_arrow,
            enabled: !_working,
            onPressed: _run,
          ),
          if (_working) ...<Widget>[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_status != null) ...<Widget>[
            const SizedBox(height: 16),
            GlassCard(
              child: Text(_status!, style: theme.textTheme.bodyLarge),
            ),
          ],
          if (_result != null) ...<Widget>[
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                if (_result!.path.toLowerCase().endsWith('.pdf'))
                  Expanded(
                    child: GradientButton(
                      label: 'Open',
                      icon: Icons.visibility,
                      height: 54,
                      onPressed: _openResultPdf,
                    ),
                  ),
                if (_result!.path.toLowerCase().endsWith('.pdf'))
                  const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: 'Share',
                    icon: Icons.share,
                    onPressed: _shareResult,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Saved on this device at:\n${_result!.path}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _runLabel(PdfTool tool) {
    switch (tool) {
      case PdfTool.merge:
        return 'Merge PDFs';
      case PdfTool.split:
        return 'Split PDF';
      case PdfTool.compress:
        return 'Compress PDF';
      case PdfTool.imageToPdf:
      case PdfTool.scan:
        return 'Create PDF';
      case PdfTool.pdfToImage:
        return 'Save page as image';
    }
  }
}

/// Small number field used for the split page range.
class _PageField extends StatelessWidget {
  const _PageField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: context.glassFillStrong,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.glassBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
