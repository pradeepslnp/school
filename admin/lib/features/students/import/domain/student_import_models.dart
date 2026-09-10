import 'package:equatable/equatable.dart';

/// The result of a bulk student upload (STU-002, screen A-12).
///
/// Contract: `STUDENTS_GUARDIANS_API.md` §POST /students/import. The valid rows are already
/// enrolled by the time this is returned — [errors] is every line that was not, for the office
/// to fix and re-upload.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class StudentImportResult extends Equatable {
  const StudentImportResult({
    required this.jobId,
    required this.status,
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  final String jobId;

  /// `COMPLETED` for any file that was processed. The whole-file rejections (empty, unknown
  /// column, too large) come back as an [Failure], not as a result with a status.
  final String status;

  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<StudentImportRowError> errors;

  /// Every data row enrolled, nothing to fix.
  bool get allImported => errorCount == 0 && successCount > 0;

  /// The file parsed but held nothing to enrol — every row failed, or there were no rows.
  bool get nothingImported => successCount == 0;

  @override
  List<Object?> get props => [
    jobId,
    status,
    totalRows,
    successCount,
    errorCount,
    errors,
  ];
}

/// One line of an uploaded file that could not be enrolled.
///
/// [row] is the spreadsheet line the operator sees — the header is line 1, so the first
/// student is line 2. [code] is a value from `ERROR_CATALOG.md`; [message] is a server-supplied
/// fallback string, shown as-is because the per-row codes are not in this console's [ErrorCode]
/// enum (they are additive detail, not outcomes any screen switches on).
class StudentImportRowError extends Equatable {
  const StudentImportRowError({
    required this.row,
    required this.code,
    required this.message,
    this.field,
  });

  final int row;
  final String? field;
  final String code;
  final String message;

  @override
  List<Object?> get props => [row, field, code, message];
}

/// The failed rows as a CSV — `row,field,code,message`, one line each.
///
/// Built from what is already on screen rather than by re-fetching
/// `GET /students/import/{jobId}/errors.csv`: the rows came back with the import response, and
/// serialising what the operator can already see is not a new data export. The office reads the
/// line numbers against their master spreadsheet, fixes those, and re-uploads.
String studentImportErrorRowsCsv(StudentImportResult result) {
  final buffer = StringBuffer('row,field,code,message\r\n');
  for (final error in result.errors) {
    buffer.write(
      '${error.row},'
      '${_csvField(error.field ?? '')},'
      '${_csvField(error.code)},'
      '${_csvField(error.message)}\r\n',
    );
  }
  return buffer.toString();
}

/// RFC 4180: quote a field containing a comma, quote, or newline; double any inner quote.
String _csvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// A file the operator chose from their machine, read into memory.
class PickedCsv extends Equatable {
  const PickedCsv({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;

  @override
  List<Object?> get props => [name, bytes.length];
}
