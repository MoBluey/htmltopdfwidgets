## 1.1.0

### Added
- **Print functionality**: Print DOCX documents as PDF using cross-platform printing
- **Download/Export**: Download documents as PDF files
- **Share functionality**: Share documents via platform share dialog
- **Toolbar widget**: Built-in toolbar with zoom, print, download, and share controls
- **Fit-to-width feature**: Automatically fit document width to viewport on initial load
- **Zoom callbacks**: `onZoomChanged` callback for tracking zoom level changes
- **Print service**: `DocxPrintService` for programmatic PDF generation and printing
- **Toolbar configuration**: `showToolbar`, `enablePrint`, `enableDownload`, `enableShare`, `toolbarPosition` options

### Changed
- **Zoom behavior**: Disabled pinch-to-zoom to prevent interference with mouse wheel scrolling
- Zoom now controlled via toolbar buttons or programmatically
- Improved mouse wheel scrolling experience

### Fixed
- Fixed fit-to-width initial load issue (no more default width then jump)
- Fixed toolbar persistence during initial load and zoom changes

## 1.0.0
- Migrated architecture to latest standards.
## 0.0.8

*  Fix: Bullet alignment improved
*  Fix: Heading styles 
## 0.0.7

*  feat:now text alignment from styles are now parsed
*  feat: background color borders are now parsed properly for paragraph and text elements
## 0.0.6

*  Fix:styles are too much bigger than expected
*  Fix: if color is defined than don't apply default color
## 0.0.5

*  Feat:styles are now parsed from file for paragraph and character
*  Feat:text align are now parsed from file
## 0.0.4

*  fixed order and unordered lists
## 0.0.3
### Fixed
- Resolved an issue where the divider was not being added correctly in the widget.
### Breaking Changes
- Removed a static function to facilitate easier addition of new features in the future.


## 0.0.2

*  fixed tag based text not rendered.
## 0.0.1

*  initial release.