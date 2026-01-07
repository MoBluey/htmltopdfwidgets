import 'dart:io';
import 'dart:typed_data';

import 'package:docx_creator/docx_creator.dart';
import 'package:flutter/material.dart';

import 'docx_view_config.dart';
import 'font_loader/embedded_font_loader.dart';
import 'search/docx_search_controller.dart';
import 'services/docx_print_service.dart';
import 'theme/docx_view_theme.dart';
import 'widget_generator/docx_widget_generator.dart';
import 'widgets/docx_toolbar.dart';

/// A Flutter widget for viewing DOCX files.
///
/// Renders Word documents using native Flutter widgets for best performance.
///
/// ## Example
/// ```dart
/// DocxView(
///   file: myDocxFile,
///   config: DocxViewConfig(
///     enableSearch: true,
///     enableZoom: true,
///   ),
/// )
/// ```
class DocxView extends StatefulWidget {
  /// The DOCX file to display. Provide one of: [file], [bytes], or [path].
  final File? file;

  /// Raw DOCX bytes to display.
  final Uint8List? bytes;

  /// Path to a DOCX file.
  final String? path;

  /// Configuration for the viewer.
  final DocxViewConfig config;

  /// Optional search controller for external control.
  final DocxSearchController? searchController;

  /// Callback when document loading completes.
  final VoidCallback? onLoaded;

  /// Callback when document loading fails.
  final void Function(Object error)? onError;

  /// Callback when print is triggered. If null, uses default print behaviour.
  final VoidCallback? onPrint;

  /// Callback when download/save is triggered. If null, uses default save dialog.
  final VoidCallback? onDownload;

  /// Callback when share is triggered.
  final VoidCallback? onShare;

  /// Callback when zoom level changes.
  final ValueChanged<double>? onZoomChanged;

  const DocxView({
    super.key,
    this.file,
    this.bytes,
    this.path,
    this.config = const DocxViewConfig(),
    this.searchController,
    this.onLoaded,
    this.onError,
    this.onPrint,
    this.onDownload,
    this.onShare,
    this.onZoomChanged,
  }) : assert(
          file != null || bytes != null || path != null,
          'Must provide either file, bytes, or path',
        );

  /// Create from file.
  factory DocxView.file(
    File file, {
    Key? key,
    DocxViewConfig config = const DocxViewConfig(),
    DocxSearchController? searchController,
  }) {
    return DocxView(
      key: key,
      file: file,
      config: config,
      searchController: searchController,
    );
  }

  /// Create from bytes.
  factory DocxView.bytes(
    Uint8List bytes, {
    Key? key,
    DocxViewConfig config = const DocxViewConfig(),
    DocxSearchController? searchController,
  }) {
    return DocxView(
      key: key,
      bytes: bytes,
      config: config,
      searchController: searchController,
    );
  }

  /// Create from path.
  factory DocxView.path(
    String path, {
    Key? key,
    DocxViewConfig config = const DocxViewConfig(),
    DocxSearchController? searchController,
  }) {
    return DocxView(
      key: key,
      path: path,
      config: config,
      searchController: searchController,
    );
  }

  @override
  State<DocxView> createState() => _DocxViewState();
}

class _DocxViewState extends State<DocxView> {
  List<Widget>? _widgets;
  List<String>? _textIndex;
  bool _isLoading = true;
  Object? _error;

  late DocxSearchController _searchController;
  late DocxWidgetGenerator _generator;
  double _currentZoom = 1.0;
  Uint8List? _documentBytes;
  bool _hasCalculatedFitToWidth = false;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? DocxSearchController();
    _searchController.addListener(_onSearchChanged);
    _loadDocument();
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _searchController.dispose();
    } else {
      _searchController.removeListener(_onSearchChanged);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(DocxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file != widget.file ||
        oldWidget.bytes != widget.bytes ||
        oldWidget.path != widget.path ||
        oldWidget.config.fitToWidth != widget.config.fitToWidth ||
        oldWidget.config.pageWidth != widget.config.pageWidth) {
      _hasCalculatedFitToWidth = false;
      _currentZoom = 1.0;
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasCalculatedFitToWidth = false;
      _currentZoom = 1.0;
    });

    try {
      Uint8List bytes;
      if (widget.bytes != null) {
        bytes = widget.bytes!;
      } else if (widget.file != null) {
        bytes = await widget.file!.readAsBytes();
      } else if (widget.path != null) {
        bytes = await File(widget.path!).readAsBytes();
      } else {
        throw ArgumentError('No document source provided');
      }

      _documentBytes = bytes; // Store for print/download

      // Load document using docx_creator
      final doc = await DocxReader.loadFromBytes(bytes);

      for (final font in doc.fonts) {
        await EmbeddedFontLoader.loadFont(
          font.familyName,
          font.bytes,
          obfuscationKey: font.obfuscationKey,
        );
      }

      // Pre-process notes for quick lookup
      final footnoteMap = {for (var f in doc.footnotes ?? []) f.footnoteId: f};
      final endnoteMap = {for (var e in doc.endnotes ?? []) e.endnoteId: e};

      // Initialize widget generator
      _generator = DocxWidgetGenerator(
        config: widget.config,
        theme: widget.config.theme,
        docxTheme: doc.theme,
        searchController: widget.config.enableSearch ? _searchController : null,
        onFootnoteTap: (id) =>
            _showNoteContent('Footnote', footnoteMap[id]?.content),
        onEndnoteTap: (id) =>
            _showNoteContent('Endnote', endnoteMap[id]?.content),
      );

      // Generate widgets
      final widgets = _generator.generateWidgets(doc);

      // Build search index
      final textIndex = _generator.extractTextForSearch(doc);

      setState(() {
        _widgets = widgets;
        _textIndex = textIndex;
        _isLoading = false;
      });

      widget.onLoaded?.call();
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
      widget.onError?.call(e);
    }
  }

  void _showNoteContent(String title, List<DocxBlock>? content) {
    if (content == null || content.isEmpty || !mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        // Generate widgets for the note content
        // We use a temporary generator just for this content
        final noteWidgets = _generator.generateWidgets(DocxBuiltDocument(
          elements: content,
          // Empty dummy section/etc
          section: const DocxSectionDef(),
        ));

        // Filter out dividers/headers/etc that handle method might add?
        // generateWidgets handles 'doc' which includes section logic.
        // If we pass content as 'elements', it will be in the body. That's fine.

        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: noteWidgets,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged() {
    if (_textIndex != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.config.theme ?? DocxViewTheme.light();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_widgets == null || _widgets!.isEmpty) {
      return const Center(child: Text('Empty document'));
    }

    // Use theme's background color, fallback to config, then to white
    final backgroundColor =
        widget.config.backgroundColor ?? theme.backgroundColor ?? Colors.white;

    Widget content;
    final list = ListView.builder(
      // If page mode, padding is handled by the page container mostly, but we keep config padding inside
      padding: widget.config.padding,
      itemCount: _widgets!.length,
      itemBuilder: (context, index) {
        final child = _widgets![index];
        if (widget.config.pageMode == DocxPageMode.paged) {
          return Center(child: child);
        }
        return child;
      },
    );

    if (widget.config.pageMode == DocxPageMode.paged) {
      // Paged View: Canvas style
      content = Container(
        color: widget.config.backgroundColor ?? const Color(0xFFE0E0E0),
        child: list,
      );
    } else if (widget.config.pageWidth != null) {
      // Page Layout Mode (Legacy constrained continuous)
      content = Container(
        color: widget.config.backgroundColor ?? const Color(0xFFF0F0F0),
        alignment: Alignment.topCenter,
        child: Container(
          width: widget.config.pageWidth,
          margin: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: list,
        ),
      );
    } else {
      // Standard Responsive Mode
      content = Container(
        color: backgroundColor,
        child: list,
      );
    }

    // Wrap everything in LayoutBuilder to get viewport width for fit-to-width calculation
    return LayoutBuilder(
      builder: (context, constraints) {
        double zoomToUse = _currentZoom;
        
        // Calculate fit-to-width zoom if enabled
        if (widget.config.fitToWidth && 
            widget.config.enableZoom && 
            widget.config.pageWidth != null &&
            !_hasCalculatedFitToWidth) {
          // Calculate zoom to fit document width to viewport width minus padding
          final padding = widget.config.padding;
          final availableWidth = constraints.maxWidth - padding.left - padding.right;
          final documentWidth = widget.config.pageWidth!;
          
          if (availableWidth > 0 && documentWidth > 0) {
            final calculatedZoom = availableWidth / documentWidth;
            // Clamp zoom to valid range
            final clampedZoom = calculatedZoom.clamp(
              widget.config.minScale,
              widget.config.maxScale,
            );
            
            // Use calculated zoom immediately for rendering
            zoomToUse = clampedZoom;
            
            // Update state asynchronously to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasCalculatedFitToWidth) {
                setState(() {
                  _currentZoom = clampedZoom;
                  _hasCalculatedFitToWidth = true;
                });
                widget.onZoomChanged?.call(_currentZoom);
              }
            });
          }
        }
        
        // Build content with calculated zoom (use zoomToUse for immediate rendering)
        return _buildContentWithZoomAndZoomValue(content, zoomToUse);
      },
    );
  }

  Widget _buildContentWithZoomAndZoomValue(Widget content, double zoomValue) {
    // Apply zoom transformation if zoom is enabled
    // Note: We don't use InteractiveViewer to avoid interference with mouse wheel scrolling
    if (widget.config.enableZoom && zoomValue != 1.0) {
      content = Transform.scale(
        scale: zoomValue,
        child: content,
      );
    }

    // Wrap with toolbar if enabled (always show toolbar, don't conditionally hide it)
    if (widget.config.showToolbar) {
      content = _buildWithToolbar(content, zoomValue);
    }

    return content;
  }

  Widget _buildWithToolbar(Widget content, [double? zoomValue]) {
    final currentZoom = zoomValue ?? _currentZoom;
    final toolbar = DocxToolbar(
      currentZoom: currentZoom,
      enableZoom: widget.config.enableZoom,
      enablePrint: widget.config.enablePrint,
      enableDownload: widget.config.enableDownload,
      enableShare: widget.config.enableShare,
      onZoomIn: () => _setZoom(_currentZoom + 0.25),
      onZoomOut: () => _setZoom(_currentZoom - 0.25),
      onZoomReset: () => _setZoom(1.0),
      onPrint: _handlePrint,
      onDownload: _handleDownload,
      onShare: _handleShare,
    );

    switch (widget.config.toolbarPosition) {
      case ToolbarPosition.top:
        return Column(children: [toolbar, Expanded(child: content)]);
      case ToolbarPosition.bottom:
        return Column(children: [Expanded(child: content), toolbar]);
      case ToolbarPosition.floating:
        return Stack(
          children: [
            content,
            Positioned(top: 8, right: 8, child: toolbar),
          ],
        );
    }
  }


  void _setZoom(double zoom) {
    setState(() {
      _currentZoom = zoom.clamp(
        widget.config.minScale,
        widget.config.maxScale,
      );
    });
    widget.onZoomChanged?.call(_currentZoom);
  }

  Future<void> _handlePrint() async {
    if (widget.onPrint != null) {
      widget.onPrint!();
      return;
    }
    if (_documentBytes == null) return;

    final printService = DocxPrintService();
    await printService.printFromBytes(_documentBytes!);
  }

  Future<void> _handleDownload() async {
    if (widget.onDownload != null) {
      widget.onDownload!();
      return;
    }
    // Default implementation: trigger share as PDF
    await _handleShare();
  }

  Future<void> _handleShare() async {
    if (widget.onShare != null) {
      widget.onShare!();
      return;
    }
    if (_documentBytes == null) return;

    final printService = DocxPrintService();
    await printService.shareAsPdf(_documentBytes!);
  }
}

/// Widget extension for adding a search bar.
class DocxViewWithSearch extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;
  final String? path;
  final DocxViewConfig config;

  const DocxViewWithSearch({
    super.key,
    this.file,
    this.bytes,
    this.path,
    this.config = const DocxViewConfig(),
  });

  @override
  State<DocxViewWithSearch> createState() => _DocxViewWithSearchState();
}

class _DocxViewWithSearchState extends State<DocxViewWithSearch> {
  final DocxSearchController _searchController = DocxSearchController();
  final TextEditingController _textController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        if (_showSearch)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      // Trigger search
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _searchController.previousMatch,
                  tooltip: 'Previous match',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: _searchController.nextMatch,
                  tooltip: 'Next match',
                ),
                ListenableBuilder(
                  listenable: _searchController,
                  builder: (context, _) {
                    if (_searchController.matchCount > 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${_searchController.currentMatchIndex + 1}/${_searchController.matchCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showSearch = false;
                      _searchController.clear();
                      _textController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        // Document view
        Expanded(
          child: Stack(
            children: [
              DocxView(
                file: widget.file,
                bytes: widget.bytes,
                path: widget.path,
                config: widget.config,
                searchController: _searchController,
              ),
              // Search FAB
              if (!_showSearch)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _showSearch = true;
                      });
                    },
                    child: const Icon(Icons.search),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
