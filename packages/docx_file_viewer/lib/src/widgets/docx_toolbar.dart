import 'package:flutter/material.dart';

/// Toolbar widget for DocxView with zoom, print, and download controls.
class DocxToolbar extends StatelessWidget {
  final double currentZoom;
  final bool enableZoom;
  final bool enablePrint;
  final bool enableDownload;
  final bool enableShare;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomReset;
  final VoidCallback? onPrint;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const DocxToolbar({
    super.key,
    required this.currentZoom,
    this.enableZoom = true,
    this.enablePrint = true,
    this.enableDownload = true,
    this.enableShare = true,
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomReset,
    this.onPrint,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enableZoom) ...[
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 20),
              onPressed: onZoomOut,
              tooltip: 'Zoom out',
              visualDensity: VisualDensity.compact,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                onTap: onZoomReset,
                child: Text(
                  '${(currentZoom * 100).toInt()}%',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 20),
              onPressed: onZoomIn,
              tooltip: 'Zoom in',
              visualDensity: VisualDensity.compact,
            ),
            const VerticalDivider(width: 16),
          ],
          if (enablePrint)
            IconButton(
              icon: const Icon(Icons.print, size: 20),
              onPressed: onPrint,
              tooltip: 'Print',
              visualDensity: VisualDensity.compact,
            ),
          if (enableDownload)
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: onDownload,
              tooltip: 'Download as PDF',
              visualDensity: VisualDensity.compact,
            ),
          if (enableShare)
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              onPressed: onShare,
              tooltip: 'Share',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

