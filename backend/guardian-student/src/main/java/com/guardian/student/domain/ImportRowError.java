package com.guardian.student.domain;

import java.util.Objects;

/**
 * One line of an uploaded file that could not be enrolled (feature STU-002).
 *
 * <p>{@code rowNumber} is the line as the operator sees it in a spreadsheet — the header is line 1,
 * so the first student is line 2. "Row 17" in the console then points at the line to fix.
 *
 * <p>{@code code} is a stable identifier drawn from the platform's error catalogue
 * (docs/04-api/ERROR_CATALOG.md) — {@code STUDENT_ADMISSION_NO_EXISTS}, {@code
 * VALIDATION_INVALID_FORMAT} — so the console and the downloadable error report name the same
 * failure the rest of the API would. {@code field} is the offending column, or null when the whole
 * line is malformed.
 */
public record ImportRowError(int rowNumber, String field, String code, String message) {

  /** Matches {@code student_import_row_errors.message VARCHAR(500)} (V17). */
  private static final int MESSAGE_MAX_LENGTH = 500;

  public ImportRowError {
    if (rowNumber < 2) {
      throw new IllegalArgumentException(
          "rowNumber is 1-based and excludes the header: " + rowNumber);
    }
    Objects.requireNonNull(code, "code");
    Objects.requireNonNull(message, "message");
    if (message.length() > MESSAGE_MAX_LENGTH) {
      message = message.substring(0, MESSAGE_MAX_LENGTH);
    }
  }

  public static ImportRowError of(int rowNumber, String field, String code, String message) {
    return new ImportRowError(rowNumber, field, code, message);
  }
}
