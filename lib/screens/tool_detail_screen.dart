import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pdf_tools.dart';
import 'viewer_screen.dart';

/// One PDF tool. `readyInV1` tools do real work; the others let the user
/// pick input files and plainly say the work itself arrives in the next
/// update — no dead buttons, no fake progress.
enum PdfTool {
  merge(
    title: 'Merge PDF',
    description: 'Combine two or more PDFs into one file.',
    icon: Icons.merge_type,
    readyInV1: false,
  ),
  split(
    title: 'Split PDF',
    description: 'Take selected pages out of a PDF.',
    icon: Icons.call_split,
    readyInV1: false,
  ),
  compress(
    title: 'Compress PDF',
    description: 'Make a PDF smaller to share or store.',
    icon: Icons.compress,
    readyInV1: false,
  ),
  imageToPdf(
    title: 'Image to PDF',
    description: 'Turn photos into a PDF, one photo per page.',
    icon: Icons.image,
    readyInV1: true,
  ),
  pdfToImage(
    title: 'PDF to Image',
    description: 'Save a PDF page as a PNG picture.',
    icon: Icons.photo,
    readyInV1: true,
  ),
  scan(
    title: 'Scan to PDF',
    description: 'Photograph pages with the camera and save them as a PDF.',
    icon: Icons.document_scanner,
    readyInV1: true,
  );

  const PdfTool({
    required this.title,
    required this.description,
    required this.icon,
    required this.readyInV1,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool readyInV1;
}

class ToolDetailScreen extends StatefulWidget {
  const ToolDetailScreen({required this.tool, super.key});

  final PdfTool tool;

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  List<String> _pickedPdfs = <String>[];
  List<String> _pickedImages = <String>[];
  int _pageNumber = 1;
  int? _pageCount;
  File? _result;
  bool _working = false;
  String? _status;

  Future<void> _pickPdfs({bool multiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      allowMultiple: multiple,
    );
    if (result == null) return;
    final paths = result.files
        .map((f) => f.path)
        .whereType<String>()
        .toList();
    setState(() {
      _pickedPdfs = paths;
      _pageCount = null;
    });
    if (paths.length == 1) {
      final count = await pdfPageCount(paths.first);
      if (mounted) setState(() => _pageCount = count);
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() {
      _pickedImages = result.files
          .map((f) => f.path)
          .whereType<String>()
          .toList();
    });
  }

  Future<void> _scanWithCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() => _pickedImages = <String>[photo.path]);
  }

  Future<void> _run() async {
    setState(() {
      _working = true;
      _status = null;
      _result = null;
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
        case PdfTool.split:
        case PdfTool.compress:
          setState(
            () => _status =
                '${widget.tool.title} is coming in the next update. '
                'Your files are picked and ready — this screen will do the '
                'work as soon as the tool lands. No payment, ever.',
          );
      }
    } catch (e) {
      setState(() => _status = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _shareResult() async {
    if (_result == null) return;
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(_result!.path)]),
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
    return Scaffold(
      appBar: AppBar(title: Text(tool.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(tool.description),
          const SizedBox(height: 8),
          if (!tool.readyInV1)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Coming in the next update. This screen already lets you '
                  'pick the files, so the tool will be one tap away when it '
                  'lands — still free, no subscription.',
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (tool == PdfTool.merge || tool == PdfTool.pdfToImage) ...<Widget>[
            FilledButton.icon(
              onPressed: () => _pickPdfs(multiple: tool == PdfTool.merge),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(tool == PdfTool.merge
                  ? 'Pick PDFs to merge'
                  : 'Pick a PDF'),
            ),
          ],
          if (tool == PdfTool.split || tool == PdfTool.compress) ...<Widget>[
            FilledButton.icon(
              onPressed: () => _pickPdfs(),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Pick a PDF'),
            ),
          ],
          if (tool == PdfTool.imageToPdf) ...<Widget>[
            FilledButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick images'),
            ),
          ],
          if (tool == PdfTool.scan) ...<Widget>[
            FilledButton.icon(
              onPressed: _scanWithCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take a photo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Or pick images from gallery'),
            ),
          ],
          if (_pickedPdfs.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ..._pickedPdfs.map(
              (p) => ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(fileNameOf(p)),
                subtitle: Text(p),
              ),
            ),
          ],
          if (_pickedImages.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ..._pickedImages.map(
              (p) => ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(fileNameOf(p)),
                subtitle: Text(p),
              ),
            ),
          ],
          if (tool == PdfTool.pdfToImage && _pageCount != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                const Text('Page: '),
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
                Text('$_pageNumber / $_pageCount'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _working ? null : _run,
            child: Text(_working ? 'Working…' : _runLabel(tool)),
          ),
          if (_status != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_status!),
          ],
          if (_result != null) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                if (_result!.path.toLowerCase().endsWith('.pdf'))
                  FilledButton.tonalIcon(
                    onPressed: _openResultPdf,
                    icon: const Icon(Icons.visibility),
                    label: const Text('Open'),
                  ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _shareResult,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Saved on this device at:\n${_result!.path}',
                style: Theme.of(context).textTheme.bodySmall),
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
