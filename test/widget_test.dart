import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_pdf_reader/main.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// path_provider_android 2.3 uses JNI, which never resolves in widget
/// tests, so the app's async settings/recents load would spin forever.
/// This fake answers with the system temp directory instead.
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
  testWidgets('Open PDF Reader shows Home, Tools and Settings tabs',
      (WidgetTester tester) async {
    PathProviderPlatform.instance = _FakePathProvider();

    // The app's startup load does real file I/O (recents/settings JSON).
    // Real async work does not complete inside the tester's fake-async
    // zone, so pump the app inside runAsync. Fixed-duration pumps are
    // used instead of pumpAndSettle, which does not work reliably
    // inside runAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(const OpenPdfReaderApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Open PDF Reader'), findsWidgets);
      expect(find.text('Open a PDF'), findsOneWidget);
      expect(find.text('Recent files'), findsOneWidget);

      await tester.tap(find.text('Tools'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Merge PDF'), findsOneWidget);
      expect(find.text('Image to PDF'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Free forever'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
    });
  });
}
