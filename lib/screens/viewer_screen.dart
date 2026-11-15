import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

/// PDF viewer: pinch zoom, page jump, page-number search, share.
/// Full-text search is not in V1 (pdfx has no text-search API); the search
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName, overflow: TextOverflow.ellipsis),
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
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: TextField(
                    controller: _searchField,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: _pageCount > 0
                          ? 'Page number (1–$_pageCount)…'
                          : 'Page number…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _showSearch = false),
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous page',
                      onPressed: _currentPage > 1
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 64,
                            child: TextField(
                              controller: _pageField,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '$_currentPage',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (value) {
                                final page = int.tryParse(value.trim());
                                if (page != null) _goToPage(page);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('/ $_pageCount'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next page',
                      onPressed: _currentPage < _pageCount
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
