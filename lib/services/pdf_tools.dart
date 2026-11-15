import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';

/// Folder inside the app documents directory where files created by the
/// app are saved (created PDFs and exported page images).
Future<Directory> createdFilesDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/Open PDF Reader');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

String _timestamp() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}_'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
}

/// Creates a real PDF from a list of image files (one image per page).
/// Used by "Image to PDF" and "Scan to PDF".
Future<File> imagesToPdf(List<String> imagePaths) async {
  final doc = pw.Document();
  for (final path in imagePaths) {
    final bytes = await File(path).readAsBytes();
    final image = pw.MemoryImage(bytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  final dir = await createdFilesDir();
  final out = File('${dir.path}/OpenPDFReader_${_timestamp()}.pdf');
  await out.writeAsBytes(await doc.save());
  return out;
}

/// Renders one page of a PDF to a PNG image file. Used by "PDF to Image".
Future<File> pdfPageToImage(String pdfPath, int pageNumber) async {
  final doc = await PdfDocument.openFile(pdfPath);
  try {
    final page = await doc.getPage(pageNumber);
    final scale = 1080 / page.width;
    final image = await page.render(
      width: 1080,
      height: page.height * scale,
      format: PdfPageImageFormat.png,
    );
    final dir = await createdFilesDir();
    final base = pdfPath.split('/').last.replaceAll('.pdf', '');
    final out = File('${dir.path}/${base}_page$pageNumber.png');
    await out.writeAsBytes(image!.bytes);
    return out;
  } finally {
    await doc.close();
  }
}

/// Returns the number of pages in a PDF, or null if it cannot be opened.
Future<int?> pdfPageCount(String pdfPath) async {
  try {
    final doc = await PdfDocument.openFile(pdfPath);
    final count = doc.pagesCount;
    await doc.close();
    return count;
  } catch (_) {
    return null;
  }
}

String fileNameOf(String path) => path.split('/').last;

/// One rendered PDF page: JPEG bytes plus its pixel size (for the page
/// aspect ratio when the new PDF is composed).
class _RenderedPage {
  const _RenderedPage(this.bytes, this.width, this.height);

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Renders pages [from]–[to] (1-based, inclusive) of a PDF to JPEG images.
/// Pages are rendered one at a time and closed right away, so memory stays
/// low even for long documents.
Future<List<_RenderedPage>> _renderPages(
  String pdfPath, {
  required int maxWidth,
  required int quality,
  int from = 1,
  int? to,
}) async {
  final doc = await PdfDocument.openFile(pdfPath);
  try {
    final last = (to ?? doc.pagesCount).clamp(1, doc.pagesCount);
    final first = from.clamp(1, last);
    final pages = <_RenderedPage>[];
    for (var i = first; i <= last; i++) {
      final page = await doc.getPage(i);
      try {
        final scale = maxWidth / page.width;
        final image = await page.render(
          width: maxWidth.toDouble(),
          height: page.height * scale,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: quality,
        );
        if (image != null) {
          pages.add(
            _RenderedPage(
              image.bytes,
              image.width ?? maxWidth,
              image.height ?? (page.height * scale).round(),
            ),
          );
        }
      } finally {
        await page.close();
      }
    }
    return pages;
  } finally {
    await doc.close();
  }
}

/// Composes rendered JPEG pages into a PDF, keeping each page's aspect
/// ratio at a fixed 595pt (A4) width.
pw.Document _composePdf(List<_RenderedPage> pages) {
  final doc = pw.Document();
  for (final page in pages) {
    final aspect = page.height / page.width;
    final image = pw.MemoryImage(page.bytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(595, 595 * aspect),
        build: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(image, fit: pw.BoxFit.fill),
        ),
      ),
    );
  }
  return doc;
}

Future<File> _savePdf(pw.Document doc, String prefix) async {
  final dir = await createdFilesDir();
  final out = File('${dir.path}/${prefix}_${_timestamp()}.pdf');
  await out.writeAsBytes(await doc.save());
  return out;
}

/// Merges two or more PDFs into one, in the given order.
/// Note: pages are re-rendered as images, so the merged file keeps the
/// exact look of every page but its text is not selectable.
Future<File> mergePdfs(List<String> pdfPaths) async {
  final pages = <_RenderedPage>[];
  for (final path in pdfPaths) {
    pages.addAll(
      await _renderPages(path, maxWidth: 1240, quality: 85),
    );
  }
  if (pages.isEmpty) throw StateError('No pages found in the PDFs.');
  return _savePdf(_composePdf(pages), 'Merged');
}

/// Extracts pages [from]–[to] of a PDF. With [onePerPage] true, returns
/// one PDF per page instead of a single file.
Future<List<File>> splitPdf(
  String pdfPath, {
  required int from,
  required int to,
  bool onePerPage = false,
}) async {
  final pages = await _renderPages(
    pdfPath,
    maxWidth: 1240,
    quality: 85,
    from: from,
    to: to,
  );
  if (pages.isEmpty) throw StateError('No pages in that range.');
  if (!onePerPage) {
    return <File>[await _savePdf(_composePdf(pages), 'Split')];
  }
  final files = <File>[];
  for (var i = 0; i < pages.length; i++) {
    files.add(
      await _savePdf(
        _composePdf(<_RenderedPage>[pages[i]]),
        'Split_page${from + i}',
      ),
    );
  }
  return files;
}

/// Re-renders every page of a PDF at a lower resolution and JPEG quality,
/// producing a much smaller file. [quality] 45 = Small, 70 = Balanced,
/// 90 = Best. The output keeps the exact look of the pages; text is not
/// selectable in the compressed file.
Future<File> compressPdf(
  String pdfPath, {
  required int quality,
  required int maxWidth,
}) async {
  final pages = await _renderPages(
    pdfPath,
    maxWidth: maxWidth,
    quality: quality,
  );
  if (pages.isEmpty) throw StateError('No pages found in the PDF.');
  return _savePdf(_composePdf(pages), 'Compressed');
}

/// Human-readable file size, e.g. "2.4 MB".
String prettySize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
