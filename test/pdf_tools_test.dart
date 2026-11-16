import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_pdf_reader/screens/viewer_screen.dart';
import 'package:open_pdf_reader/services/pdf_tools.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdf/pdf.dart';

/// path_provider_android uses JNI in widget tests; answer with the
/// system temp directory instead (same fake as widget_test.dart).
class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  setUp(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  group('clampPage', () {
    test('clamps into 1..count', () {
      expect(clampPage(0, 16), 1);
      expect(clampPage(1, 16), 1);
      expect(clampPage(10, 16), 10);
      expect(clampPage(17, 16), 16);
      expect(clampPage(100, 16), 16);
    });

    test('unknown page count returns 1', () {
      expect(clampPage(10, 0), 1);
    });
  });

  group('nextQuarterTurns', () {
    test('cycles 0 -> 1 -> 2 -> 3 -> 0', () {
      expect(nextQuarterTurns(0), 1);
      expect(nextQuarterTurns(1), 2);
      expect(nextQuarterTurns(2), 3);
      expect(nextQuarterTurns(3), 0);
    });
  });

  group('createTextPdf', () {
    test('writes a real PDF file with a title and body', () async {
      final file = await createTextPdf(
        title: 'My Notes',
        body: 'Hello world.\nSecond paragraph here.',
        pageFormat: PdfPageFormat.a4,
        fontSize: 14,
      );
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(500));
      final bytes = await file.readAsBytes();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      await file.delete();
    });

    test('long body makes a bigger file than a short body', () async {
      final short = await createTextPdf(
        title: 'Short',
        body: 'One line.',
        pageFormat: PdfPageFormat.a4,
        fontSize: 14,
      );
      final long = await createTextPdf(
        title: 'Long',
        body: List.filled(200, 'A paragraph of text to fill the page. ')
            .join('\n'),
        pageFormat: PdfPageFormat.a4,
        fontSize: 14,
      );
      expect(await long.length(), greaterThan(await short.length()));
      await short.delete();
      await long.delete();
    });
  });
}
