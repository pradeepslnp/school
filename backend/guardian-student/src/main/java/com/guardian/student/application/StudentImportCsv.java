package com.guardian.student.application;

import com.guardian.common.error.ErrorCode;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Turns an uploaded spreadsheet (exported as CSV) into rows the import use case can validate.
 *
 * <p>Scope is deliberately narrow: this reads the file structure, not its meaning. It decodes the
 * bytes, splits rows and fields per RFC 4180 (quoted fields may contain commas, doubled quotes, and
 * newlines), matches the header against the columns this version understands, and hands back one
 * {@link Row} per data line. Whether an admission number is well-formed or already taken is the use
 * case's job, not this class's.
 *
 * <p>It rejects the file as a whole only when it cannot be read at all — empty, or a header naming
 * a column that is not supported yet (a guardian or stop column). Enrolling students while silently
 * dropping columns the office believed it was providing is the more dangerous outcome, so an
 * unknown column stops the import rather than being ignored.
 */
public final class StudentImportCsv {

  /** A column this version can import. Everything else in a header stops the file. */
  public enum Column {
    ADMISSION_NO,
    FIRST_NAME,
    LAST_NAME,
    DATE_OF_BIRTH,
    TRANSPORT_ELIGIBLE
  }

  /**
   * Which header spellings map to which column. Compared after lower-casing and stripping spaces,
   * underscores, and hyphens — so {@code "Admission No"}, {@code admission_no} and {@code
   * AdmissionNo} are one column.
   */
  private static final Map<String, Column> HEADER_ALIASES = new LinkedHashMap<>();

  static {
    HEADER_ALIASES.put("admissionno", Column.ADMISSION_NO);
    HEADER_ALIASES.put("admissionnumber", Column.ADMISSION_NO);
    HEADER_ALIASES.put("firstname", Column.FIRST_NAME);
    HEADER_ALIASES.put("givenname", Column.FIRST_NAME);
    HEADER_ALIASES.put("lastname", Column.LAST_NAME);
    HEADER_ALIASES.put("surname", Column.LAST_NAME);
    HEADER_ALIASES.put("familyname", Column.LAST_NAME);
    HEADER_ALIASES.put("dateofbirth", Column.DATE_OF_BIRTH);
    HEADER_ALIASES.put("dob", Column.DATE_OF_BIRTH);
    HEADER_ALIASES.put("transporteligible", Column.TRANSPORT_ELIGIBLE);
    HEADER_ALIASES.put("transportrequired", Column.TRANSPORT_ELIGIBLE);
  }

  /** The line number a spreadsheet shows for a data row: the header is line 1. */
  public record Row(int lineNumber, Map<Column, String> values) {
    public String get(Column column) {
      return values.getOrDefault(column, "");
    }
  }

  private StudentImportCsv() {}

  public static List<Row> parse(byte[] content) {
    if (content == null || content.length == 0) {
      throw new StudentImportRejectedException(ErrorCode.STUDENT_IMPORT_FILE_EMPTY);
    }

    String text = stripBom(new String(content, StandardCharsets.UTF_8));
    if (text.indexOf('\0') >= 0) {
      // A NUL byte means this is not text — most often a spreadsheet saved as .xlsx and given a
      // .csv name, which would otherwise parse into one garbage "header" and a wall of row errors.
      throw new StudentImportRejectedException(ErrorCode.STUDENT_IMPORT_FILE_UNREADABLE);
    }
    List<List<String>> records = tokenize(text);
    if (records.isEmpty()) {
      throw new StudentImportRejectedException(ErrorCode.STUDENT_IMPORT_FILE_EMPTY);
    }

    List<Column> layout = resolveHeader(records.get(0));

    List<Row> rows = new ArrayList<>();
    for (int i = 1; i < records.size(); i++) {
      List<String> fields = records.get(i);
      if (isBlankRecord(fields)) {
        continue;
      }
      Map<Column, String> values = new EnumMap<>(Column.class);
      for (int c = 0; c < layout.size() && c < fields.size(); c++) {
        Column column = layout.get(c);
        // null is an empty header cell — a trailing separator on the header line. Skip it
        // rather than let it reach the EnumMap, which rejects a null key.
        if (column != null) {
          values.put(column, fields.get(c).trim());
        }
      }
      // Line number is 1-based and counts the header, so the first data record is line 2.
      rows.add(new Row(i + 1, values));
    }

    if (rows.isEmpty()) {
      throw new StudentImportRejectedException(ErrorCode.STUDENT_IMPORT_FILE_EMPTY);
    }
    return rows;
  }

  private static List<Column> resolveHeader(List<String> header) {
    List<Column> layout = new ArrayList<>(header.size());
    for (String raw : header) {
      String key = raw.toLowerCase(Locale.ROOT).replaceAll("[\\s_-]", "");
      if (key.isEmpty()) {
        // A trailing separator on the header line produces an empty cell — ignore it rather
        // than treat it as an unknown column.
        layout.add(null);
        continue;
      }
      Column column = HEADER_ALIASES.get(key);
      if (column == null) {
        throw new StudentImportRejectedException(
            ErrorCode.STUDENT_IMPORT_UNSUPPORTED_COLUMN, Map.of("column", raw.trim()));
      }
      layout.add(column);
    }
    if (!layout.contains(Column.ADMISSION_NO)
        || !layout.contains(Column.FIRST_NAME)
        || !layout.contains(Column.LAST_NAME)) {
      throw new StudentImportRejectedException(
          ErrorCode.STUDENT_IMPORT_UNSUPPORTED_COLUMN,
          Map.of("column", "admissionNo, firstName, lastName are all required"));
    }
    return layout;
  }

  /**
   * RFC 4180 tokenizer: comma-separated, {@code "} quoting, {@code ""} for a literal quote,
   * newlines permitted inside quotes. Bare CR, LF and CRLF all end a record.
   */
  private static List<List<String>> tokenize(String text) {
    List<List<String>> records = new ArrayList<>();
    List<String> current = new ArrayList<>();
    StringBuilder field = new StringBuilder();
    boolean inQuotes = false;

    for (int i = 0; i < text.length(); i++) {
      char ch = text.charAt(i);
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length() && text.charAt(i + 1) == '"') {
            field.append('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.append(ch);
        }
        continue;
      }
      switch (ch) {
        case '"' -> inQuotes = true;
        case ',' -> {
          current.add(field.toString());
          field.setLength(0);
        }
        case '\r' -> {
          // Swallow a following \n so CRLF is one break.
          if (i + 1 < text.length() && text.charAt(i + 1) == '\n') {
            i++;
          }
          current.add(field.toString());
          field.setLength(0);
          records.add(current);
          current = new ArrayList<>();
        }
        case '\n' -> {
          current.add(field.toString());
          field.setLength(0);
          records.add(current);
          current = new ArrayList<>();
        }
        default -> field.append(ch);
      }
    }
    // The last field / record if the file does not end with a newline.
    if (field.length() > 0 || !current.isEmpty()) {
      current.add(field.toString());
      records.add(current);
    }
    return records;
  }

  private static boolean isBlankRecord(List<String> fields) {
    return fields.stream().allMatch(f -> f == null || f.isBlank());
  }

  private static String stripBom(String text) {
    return text.startsWith("﻿") ? text.substring(1) : text;
  }
}
