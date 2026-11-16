import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pdf_reader/main.dart';
import 'package:open_pdf_reader/screens/tool_detail_screen.dart';
import 'package:open_pdf_reader/theme/app_theme.dart';
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

    // The V2 Home screen is taller than the default 800x600 test
    // viewport, so use a tall phone-sized surface: otherwise ListView
    // children below the fold are never built and finders miss them.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      expect(find.text('Create PDF'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Open PDF Reader'), findsWidgets);
      expect(find.text('Dark mode'), findsOneWidget);
    });
  });

  testWidgets('Tool detail screen uses the light background in light mode',
      (WidgetTester tester) async {
    PathProviderPlatform.instance = _FakePathProvider();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      // Light theme: the detail screen must paint the light background,
      // not black. (V2.1 regression test: the old transparent Scaffold
      // on an opaque route painted black in light mode.)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const ToolDetailScreen(tool: PdfTool.scan),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final scaffold =
          tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.lightBg);
      expect(find.text('Scan to PDF'), findsOneWidget);

      // Dark theme: the same screen must paint the dark background.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const ToolDetailScreen(tool: PdfTool.scan),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final darkScaffold =
          tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(darkScaffold.backgroundColor, AppColors.darkBg);
    });
  });
}
