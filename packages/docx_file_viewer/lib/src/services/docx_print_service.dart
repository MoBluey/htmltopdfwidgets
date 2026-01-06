import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:docx_creator/docx_creator.dart';

/// Service for printing and exporting DOCX documents as PDF.
///
/// Converts DOCX content to PDF format using docx_creator for parsing
/// and the dart pdf package for generation.
class DocxPrintService {
  /// Page format for PDF generation (default: A4)
  final PdfPageFormat pageFormat;

  /// Page margins
  final pw.EdgeInsets margins;

  /// Default font size in points
  final double defaultFontSize;

  DocxPrintService({
    this.pageFormat = PdfPageFormat.a4,
    this.margins = const pw.EdgeInsets.all(72), // 1 inch
    this.defaultFontSize = 11,
  });

  /// Print a DOCX document from raw bytes.
  ///
  /// Parses the DOCX, converts to PDF, and triggers the native print dialog.
  /// Returns true if printing was initiated successfully.
  Future<bool> printFromBytes(Uint8List docxBytes, {String? documentName}) async {
    try {
      final pdfBytes = await generatePdfFromBytes(docxBytes);
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: documentName ?? 'Document',
      );
      return true;
    } catch (e) {
      debugPrint('Error printing DOCX: $e');
      return false;
    }
  }

  /// Generate PDF bytes from DOCX bytes.
  ///
  /// Uses docx_creator to parse the document structure and converts
  /// to PDF format.
  Future<Uint8List> generatePdfFromBytes(Uint8List docxBytes) async {
    // Parse using docx_creator
    final doc = await DocxReader.loadFromBytes(docxBytes);

    // Create PDF document
    final pdf = pw.Document(
      title: 'DOCX Document',
      author: 'docx_file_viewer',
    );

    // Convert document elements to PDF pages
    final pdfWidgets = <pw.Widget>[];

    for (final element in doc.elements) {
      final widget = _convertElement(element);
      if (widget != null) {
        pdfWidgets.add(widget);
      }
    }

    // Add content to PDF with pagination
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: margins,
        build: (context) => pdfWidgets,
      ),
    );

    return pdf.save();
  }

  /// Convert a DocxNode element to a PDF widget.
  pw.Widget? _convertElement(DocxNode element) {
    if (element is DocxParagraph) {
      return _convertParagraph(element);
    } else if (element is DocxTable) {
      return _convertTable(element);
    } else if (element is DocxList) {
      return _convertList(element);
    }
    // Add more element types as needed
    return null;
  }

  /// Convert a DocxParagraph to PDF widgets.
  pw.Widget _convertParagraph(DocxParagraph paragraph) {
    if (paragraph.children.isEmpty) {
      return pw.SizedBox(height: defaultFontSize);
    }

    final spans = <pw.InlineSpan>[];

    for (final child in paragraph.children) {
      if (child is DocxText) {
        spans.add(pw.TextSpan(
          text: child.content,
          style: _convertTextStyle(child),
        ));
      } else if (child is DocxLineBreak) {
        spans.add(const pw.TextSpan(text: '\n'));
      } else if (child is DocxTab) {
        spans.add(const pw.TextSpan(text: '\t'));
      }
      // Handle other inline elements as needed
    }

    if (spans.isEmpty) {
      return pw.SizedBox(height: defaultFontSize);
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(children: spans),
        textAlign: _convertAlignment(paragraph.align),
      ),
    );
  }

  /// Convert DocxText style to PDF TextStyle.
  pw.TextStyle _convertTextStyle(DocxText text) {
    return pw.TextStyle(
      fontSize: text.fontSize ?? defaultFontSize,
      fontWeight: text.fontWeight == DocxFontWeight.bold
          ? pw.FontWeight.bold
          : pw.FontWeight.normal,
      fontStyle: text.fontStyle == DocxFontStyle.italic
          ? pw.FontStyle.italic
          : pw.FontStyle.normal,
      decoration: _getTextDecoration(text),
      color: text.color != null
          ? PdfColor.fromHex(text.color!.hex)
          : PdfColors.black,
    );
  }

  /// Get text decoration from DocxText properties.
  pw.TextDecoration? _getTextDecoration(DocxText text) {
    final decorations = <pw.TextDecoration>[];
    if (text.decoration == DocxTextDecoration.underline) {
      decorations.add(pw.TextDecoration.underline);
    }
    if (text.decoration == DocxTextDecoration.strikethrough) {
      decorations.add(pw.TextDecoration.lineThrough);
    }

    if (decorations.isEmpty) return null;
    return pw.TextDecoration.combine(decorations);
  }

  /// Convert alignment enum.
  pw.TextAlign _convertAlignment(DocxAlign alignment) {
    switch (alignment) {
      case DocxAlign.left:
        return pw.TextAlign.left;
      case DocxAlign.center:
        return pw.TextAlign.center;
      case DocxAlign.right:
        return pw.TextAlign.right;
      case DocxAlign.justify:
        return pw.TextAlign.justify;
    }
  }

  /// Convert a DocxTable to PDF table.
  pw.Widget _convertTable(DocxTable table) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: table.rows.map((row) {
        return pw.TableRow(
          children: row.cells.map((cell) {
            final cellWidgets = cell.children
                .map(_convertElement)
                .whereType<pw.Widget>()
                .toList();

            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: cellWidgets.isEmpty
                    ? [pw.SizedBox(height: defaultFontSize)]
                    : cellWidgets,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// Convert a DocxList to PDF widgets.
  pw.Widget? _convertList(DocxList list) {
    // For now, convert list items to simple paragraphs
    // This can be enhanced to show proper list formatting with bullets/numbers
    final widgets = <pw.Widget>[];
    for (final item in list.items) {
      // List items contain DocxInline elements (typically DocxText)
      final spans = <pw.InlineSpan>[];
      for (final child in item.children) {
        if (child is DocxText) {
          spans.add(pw.TextSpan(
            text: child.content,
            style: _convertTextStyle(child),
          ));
        }
      }
      if (spans.isNotEmpty) {
        final prefix = list.isOrdered
            ? '${list.items.indexOf(item) + list.startIndex}. '
            : '• ';
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4, left: 16),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: prefix),
                  ...spans,
                ],
              ),
            ),
          ),
        );
      }
    }
    if (widgets.isEmpty) return null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Show a print preview dialog.
  Future<void> showPrintPreview(
    BuildContext context,
    Uint8List docxBytes, {
    String? documentName,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(documentName ?? 'Print Preview'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: PdfPreview(
            build: (format) => generatePdfFromBytes(docxBytes),
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowPrinting: true,
            allowSharing: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Share a DOCX document as PDF.
  Future<void> shareAsPdf(Uint8List docxBytes, {String? documentName}) async {
    final pdfBytes = await generatePdfFromBytes(docxBytes);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${documentName ?? 'document'}.pdf',
    );
  }
}

