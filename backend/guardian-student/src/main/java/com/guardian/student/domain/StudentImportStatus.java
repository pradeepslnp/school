package com.guardian.student.domain;

/**
 * The outcome of processing an uploaded file (feature STU-002).
 *
 * <p>Deliberately coarse. It answers "was the file readable?", not "did every row import" — the
 * per-row outcome lives in {@link ImportRowError}. A file with four bad rows out of four hundred is
 * still {@link #COMPLETED}: the platform did what it could, which is the whole point of importing
 * the valid remainder rather than rejecting the file (PERSONAS.md, Fatima).
 */
public enum StudentImportStatus {

  /** The file was parsed and every data row was either enrolled or recorded as an error. */
  COMPLETED,

  /**
   * The file could not be processed at all — it was empty, unreadable, or its header carried a
   * column this version does not understand. Nothing was enrolled.
   */
  FAILED;

  public static StudentImportStatus fromStored(String stored) {
    return valueOf(stored);
  }
}
