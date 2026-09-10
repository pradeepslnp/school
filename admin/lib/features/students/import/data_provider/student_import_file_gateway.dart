import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/student_import_models.dart';

/// The two browser operations bulk import needs and a Flutter Web build cannot do without
/// touching the DOM: let the operator choose a spreadsheet, and hand one back for them to save.
///
/// **This is the only file in the console that imports `package:web`.** It is a transport
/// concern — the boundary between the app and the browser — so it sits in the data-provider
/// layer, and nothing above it (repository, bloc, widgets) knows a browser type exists. ADR-0003
/// already fixes this client to the web; there is no non-web path to guard.
class StudentImportFileGateway {
  const StudentImportFileGateway();

  /// Opens the browser's file picker and reads the chosen file into memory.
  ///
  /// Returns null when the operator dismisses the picker without choosing — the browser fires
  /// no event for a cancel, so this completes only on an actual selection or a read error, and
  /// the caller simply stays on the "choose a file" step.
  Future<PickedCsv?> pickCsv() {
    final completer = Completer<PickedCsv?>();

    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.csv,text/csv';

    input.onchange = (web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0)!;
      final reader = web.FileReader();
      reader.onload = (web.Event _) {
        final result = reader.result;
        if (result.isA<JSArrayBuffer>()) {
          final bytes = (result as JSArrayBuffer).toDart.asUint8List();
          if (!completer.isCompleted) {
            completer.complete(PickedCsv(name: file.name, bytes: bytes));
          }
        } else if (!completer.isCompleted) {
          completer.complete(null);
        }
      }.toJS;
      reader.onerror = (web.Event _) {
        if (!completer.isCompleted) completer.complete(null);
      }.toJS;
      reader.readAsArrayBuffer(file);
    }.toJS;

    input.click();
    return completer.future;
  }

  /// Triggers a browser download of [content] under [fileName].
  ///
  /// Used for the "download error rows" file the office corrects and re-uploads. Builds an
  /// object URL, clicks a detached anchor, and revokes the URL straight after so the blob is
  /// not held for the life of the tab.
  void downloadCsv({required String fileName, required String content}) {
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
