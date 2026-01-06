# docx_file_viewer

[![pub package](https://img.shields.io/pub/v/docx_file_viewer.svg)](https://pub.dev/packages/docx_file_viewer)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0.0-blue)](https://flutter.dev)

A **native Flutter DOCX viewer** that renders Word documents using Flutter widgets. No WebView, no PDF conversion—just pure Flutter rendering for maximum performance.

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎯 **Native Rendering** | Pure Flutter widgets, no WebView or PDF |
| 📖 **Full DOCX Support** | Paragraphs, tables, lists, images, shapes |
| 🔍 **Search** | Find and highlight text in documents |
| 🔎 **Zoom** | Programmatic zoom via toolbar (no pinch-to-zoom interference) |
| 📄 **Print & Export** | Print documents or export as PDF |
| 💾 **Download** | Download/save documents as PDF |
| 📤 **Share** | Share documents via platform share dialog |
| 🛠️ **Toolbar** | Built-in toolbar with zoom, print, download, and share controls |
| 📏 **Fit to Width** | Automatically fit document width to viewport |
| ✂️ **Selection** | Select and copy text |
| 🎨 **Theming** | Light/dark themes, customizable |
| 🔤 **Fonts** | Embedded font loading with OOXML deobfuscation |

## 📦 Installation

Add `docx_file_viewer` to your `pubspec.yaml`:

```yaml
dependencies:
  docx_file_viewer: ^1.0.0
```

## 🚀 Quick Start

```dart
import 'package:docx_file_viewer/docx_viewer.dart';

// From file
DocxView.file(myFile)

// From bytes
DocxView.bytes(docxBytes)

// From path
DocxView.path('/path/to/document.docx')

// With configuration
DocxView(
  file: myFile,
  config: DocxViewConfig(
    enableSearch: true,
    enableZoom: true,
    theme: DocxViewTheme.light(),
    customFontFallbacks: ['Roboto', 'Arial'],
  ),
)
```

## 📖 Usage

### Basic Viewer

```dart
Scaffold(
  body: DocxView.file(
    File('document.docx'),
    config: DocxViewConfig(
      enableZoom: true,
      backgroundColor: Colors.white,
    ),
  ),
)
```

### With Search Bar

```dart
Scaffold(
  body: DocxViewWithSearch(
    file: myDocxFile,
    config: DocxViewConfig(
      enableSearch: true,
      searchHighlightColor: Colors.yellow,
    ),
  ),
)
```

### Dark Theme

```dart
DocxView(
  bytes: docxBytes,
  config: DocxViewConfig(
    theme: DocxViewTheme.dark(),
    backgroundColor: Color(0xFF1E1E1E),
  ),
)
```

### With Toolbar (Print, Download, Share)

```dart
DocxView.file(
  file,
  config: DocxViewConfig(
    showToolbar: true,
    enablePrint: true,
    enableDownload: true,
    enableShare: true,
    toolbarPosition: ToolbarPosition.top, // or bottom, floating
  ),
  onPrint: () async {
    // Custom print handler (optional)
  },
  onDownload: () async {
    // Custom download handler (optional)
  },
  onShare: () async {
    // Custom share handler (optional)
  },
)
```

### Fit to Width

```dart
DocxView.file(
  file,
  config: DocxViewConfig(
    pageWidth: 793,      // A4 width in pixels
    fitToWidth: true,    // Automatically fit to viewport width
    enableZoom: true,
    padding: EdgeInsets.all(16.0),
  ),
)
```

### With Zoom Callbacks

```dart
DocxView.file(
  file,
  config: DocxViewConfig(
    showToolbar: true,
    enableZoom: true,
  ),
  onZoomChanged: (zoom) {
    print('Current zoom: ${(zoom * 100).toInt()}%');
  },
)
```

### With Search Controller

```dart
final searchController = DocxSearchController();

// Widget
DocxView(
  file: myFile,
  searchController: searchController,
)

// Programmatic control
searchController.search('keyword', textIndex);
searchController.nextMatch();
searchController.previousMatch();
searchController.clear();
```

## ⚙️ Configuration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `enableSearch` | `bool` | `true` | Enable search functionality |
| `enableZoom` | `bool` | `true` | Enable zoom (via toolbar buttons) |
| `enableSelection` | `bool` | `true` | Enable text selection |
| `minScale` | `double` | `0.5` | Minimum zoom scale |
| `maxScale` | `double` | `4.0` | Maximum zoom scale |
| `showToolbar` | `bool` | `false` | Show toolbar with controls |
| `enablePrint` | `bool` | `true` | Enable print in toolbar |
| `enableDownload` | `bool` | `true` | Enable download in toolbar |
| `enableShare` | `bool` | `true` | Enable share in toolbar |
| `toolbarPosition` | `ToolbarPosition` | `top` | Toolbar position (top, bottom, floating) |
| `fitToWidth` | `bool` | `false` | Auto-fit document width to viewport |
| `pageWidth` | `double?` | `null` | Fixed page width (required for fitToWidth) |
| `pageMode` | `DocxPageMode` | `paged` | Layout mode (continuous or paged) |
| `customFontFallbacks` | `List<String>` | `['Roboto', 'Arial', 'Helvetica']` | Font fallbacks |
| `theme` | `DocxViewTheme?` | Light | Rendering theme |
| `padding` | `EdgeInsets` | `16.0` | Document padding |
| `backgroundColor` | `Color?` | White | Background color |
| `searchHighlightColor` | `Color` | Yellow | Search highlight |

### Callbacks

| Callback | Type | Description |
|----------|------|-------------|
| `onPrint` | `VoidCallback?` | Called when print is triggered |
| `onDownload` | `VoidCallback?` | Called when download is triggered |
| `onShare` | `VoidCallback?` | Called when share is triggered |
| `onZoomChanged` | `ValueChanged<double>?` | Called when zoom level changes |
| `onLoaded` | `VoidCallback?` | Called when document finishes loading |
| `onError` | `void Function(Object)?` | Called when document loading fails |

## 🎨 Theming

```dart
DocxViewTheme(
  defaultTextStyle: TextStyle(fontSize: 14, color: Colors.black87),
  headingStyles: {
    1: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    2: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    // ...
  },
  codeBlockBackground: Color(0xFFF5F5F5),
  codeTextStyle: TextStyle(fontFamily: 'monospace'),
  tableBorderColor: Color(0xFFDDDDDD),
  linkStyle: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
)

// Presets
DocxViewTheme.light()
DocxViewTheme.dark()
```

## 🔗 Integration with docx_creator

This package uses [docx_creator](https://pub.dev/packages/docx_creator) for parsing:

```dart
import 'package:docx_creator/docx_creator.dart';

// Create document
final doc = docx()
  .h1('Title')
  .p('Content')
  .build();

// Export to bytes
final bytes = await DocxExporter().exportToBytes(doc);

// View immediately
DocxView.bytes(bytes)
```

## 🖨️ Print & Export

The package includes built-in print and PDF export functionality:

```dart
import 'package:docx_file_viewer/docx_file_viewer.dart';

// Print service (also used internally by toolbar)
final printService = DocxPrintService();

// Print from bytes
await printService.printFromBytes(docxBytes, documentName: 'My Document');

// Generate PDF bytes
final pdfBytes = await printService.generatePdfFromBytes(docxBytes);

// Share as PDF
await printService.shareAsPdf(docxBytes, documentName: 'My Document');

// Show print preview dialog
await printService.showPrintPreview(context, docxBytes);
```

## 📝 Notes

- **Zoom Behavior**: Pinch-to-zoom is disabled to prevent interference with mouse wheel scrolling. Zoom is controlled via toolbar buttons or programmatically.
- **Fit to Width**: Requires `pageWidth` to be set in config. Calculates zoom to fit document width to viewport width minus padding.
- **Print/Export**: Uses the `pdf` and `printing` packages for cross-platform PDF generation and printing.

## 📋 Supported Elements

| Element | Support |
|---------|---------|
| Headings (H1-H6) | ✅ |
| Paragraphs | ✅ |
| Bold, Italic, Underline | ✅ |
| Colors & Backgrounds | ✅ |
| Hyperlinks | ✅ |
| Bullet Lists | ✅ |
| Numbered Lists | ✅ |
| Nested Lists | ✅ |
| Tables | ✅ |
| Images | ✅ |
| Shapes | ✅ |
| Code Blocks | ✅ |
| Embedded Fonts | ✅ |

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

MIT License - see [LICENSE](LICENSE) for details.
