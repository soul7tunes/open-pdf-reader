import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

/// Clamps a requested page into 1..[count] (count 0 means "unknown",
/// in which case page 1 is returned).
int clampPage(int page, int count) {
  if (count <= 0) return 1;
  return page.clamp(1, count);
}

/// Next rotation step: 0 -> 1 -> 2 -> 3 -> 0 (quarter turns).
int nextQuarterTurns(int current) => (current + 1) % 4;

/// PDF viewer V2.1: pinch zoom, page jump, share, rotate.
///
/// Page indicator fix (V2.1): V2 used PdfViewPinch, whose page number is
/// computed from the largest visible page area during layout — it could
/// report a stale/wrong page (e.g. 10 while page 1 was on screen) and the
/// page field only showed that value as a hint. V2.1 uses PdfView
/// (PageView-based): its page is a single source of truth driven by the
/// page in the centre of the viewport, `jumpToPage` is correctly 1-based
/// (PdfControllerPinch.jumpToPage added 1), the field holds the real page
/// number as text, and the indicator resets to 1 when a document loads.
/// Full-text search is not in V2.1 (pdfx has no text-search API); the
/// search box jumps to a page number, and anything else explains that.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({required this.filePath, super.key});

  final String filePath;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final Future<PdfDocument> _documentFuture;
  late final PdfController _controller;
  final TextEditingController _pageField =
      TextEditingController(text: '1');
  final FocusNode _pageFocus = FocusNode();
  final TextEditingController _searchField = TextEditingController();
  bool _showSearch = false;
  int _currentPage = 1;
  int _pageCount = 0;
  int _quarterTurns = 0;
  String? _error;

  String get _fileName => widget.filePath.split('/').last;

  @override
  void initState() {
    super.initState();
    _documentFuture = PdfDocument.openFile(widget.filePath);
    _controller = PdfController(document: _documentFuture);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageField.dispose();
    _pageFocus.dispose();
    _searchField.dispose();
    super.dispose();
  }

  /// The one place the indicator changes: the page PdfView reports as
  /// centred. The field text is synced too, unless the user is typing
  /// in it right now.
  void _onPageChanged(int page) {
    if (!mounted) return;
    setState(() {
      _currentPage = page;
      if (!_pageFocus.hasFocus) {
        _pageField.text = '$page';
        _pageField.selection = TextSelection.collapsed(
          offset: _pageField.text.length,
        );
      }
    });
  }

  void _onDocumentLoaded(PdfDocument document) {
    if (!mounted) return;
    setState(() {
      _pageCount = document.pagesCount;
      _currentPage = 1;
      _pageField.text = '1';
      _pageField.selection = const TextSelection.collapsed(offset: 1);
    });
  }

  void _goToPage(int page) {
    if (_pageCount == 0) return;
    final target = clampPage(page, _pageCount);
    _controller.jumpToPage(target);
    // jumpToPage is instant but onPageChanged may not fire if the page
    // is already current; keep the indicator in sync either way.
    _onPageChanged(target);
  }

  void _rotate() {
    setState(() => _quarterTurns = nextQuarterTurns(_quarterTurns));
  }

  void _onSearchSubmitted(String value) {
    final page = int.tryParse(value.trim());
    if (page != null) {
      _goToPage(page);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Text search is coming in the next update. '
          'Type a page number to jump to that page.',
        ),
      ),
    );
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(widget.filePath)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Hero(
              tag: 'pdf-icon-${widget.filePath}',
              child: const GradientIconChip(
                icon: Icons.picture_as_pdf,
                size: 40,
                iconSize: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fileName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Rotate page',
            onPressed: _rotate,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search / go to page',
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share this PDF',
            onPressed: _share,
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.glassFill,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.glassBorder),
                    ),
                    child: TextField(
                      controller: _searchField,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: _pageCount > 0
                            ? 'Page number (1–$_pageCount)…'
                            : 'Page number…',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: context.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _showSearch = false),
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not open this PDF.\n$_error',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          : RotatedBox(
              quarterTurns: _quarterTurns,
              child: PdfView(
                controller: _controller,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                onDocumentLoaded: _onDocumentLoaded,
                onDocumentError: (error) =>
                    setState(() => _error = error.toString()),
              ),
            ),
      bottomNavigationBar: _pageCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: FloatingGlassBar(
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 30),
                        tooltip: 'Previous page',
                        onPressed: _currentPage > 1
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.rotate_right, size: 26),
                        tooltip: 'Rotate page',
                        onPressed: _rotate,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 72,
                              height: 48,
                              decoration: BoxDecoration(
                                color: context.glassFillStrong,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: context.glassBorder,
                                ),
                              ),
                              child: TextField(
                                controller: _pageField,
                                focusNode: _pageFocus,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  final page = int.tryParse(value.trim());
                                  if (page != null) {
                                    _goToPage(page);
                                  } else {
                                    // Restore the real current page.
                                    setState(() {
                                      _pageField.text = '$_currentPage';
                                    });
                                  }
                                  _pageFocus.unfocus();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '/ $_pageCount',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 30),
                        tooltip: 'Next page',
                        onPressed: _currentPage < _pageCount
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
