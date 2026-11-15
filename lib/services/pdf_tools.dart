import 'dart:io';

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
