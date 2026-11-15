import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

/// PDF viewer V2: pinch zoom, page jump, share — with a floating glass
/// pill for page controls (Material 3 Expressive floating toolbar) and
/// a hero transition from the Home file card.
/// Full-text search is not in V2 (pdfx has no text-search API); the search
/// box jumps to a page number, and anything else explains that plainly.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({required this.filePath, super.key});

  final String filePath;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final Future<PdfDocument> _documentFuture;
  late final PdfControllerPinch _controller;
  final TextEditingController _pageField = TextEditingController();
  final TextEditingController _searchField = TextEditingController();
  bool _showSearch = false;
  int _currentPage = 1;
  int _pageCount = 0;
  String? _error;

  String get _fileName => widget.filePath.split('/').last;

  @override
  void initState() {
    super.initState();
    _documentFuture = PdfDocument.openFile(widget.filePath);
    _controller = PdfControllerPinch(document: _documentFuture);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageField.dispose();
    _searchField.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_pageCount == 0) return;
    final target = page.clamp(1, _pageCount);
    _controller.jumpToPage(target);
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
          : PdfViewPinch(
              controller: _controller,
              onPageChanged: (page) => setState(() => _currentPage = page),
              onDocumentLoaded: (document) =>
                  setState(() => _pageCount = document.pagesCount),
              onDocumentError: (error) =>
                  setState(() => _error = error.toString()),
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
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                                decoration: InputDecoration(
                                  hintText: '$_currentPage',
                                  hintStyle: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  final page = int.tryParse(value.trim());
                                  if (page != null) _goToPage(page);
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
