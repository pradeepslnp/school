package com.guardian.student.application.command;

import com.guardian.student.domain.SchoolId;
import java.util.Objects;
import java.util.UUID;

/**
 * Enrol every valid row of an uploaded spreadsheet into one school (feature STU-002).
 *
 * <p>{@code content} is the raw uploaded bytes — parsing and format validation happen inside the
 * use case, so nothing downstream receives a string it still has to trust. Every row lands in
 * {@code schoolId}: a student belongs to exactly one school (BR-STU-001), and a school is a
 * property of the upload, not a column that could vary line to line.
 */
public record ImportStudentsCommand(
    SchoolId schoolId, String fileName, byte[] content, UUID actorId, String actorRole) {

  public ImportStudentsCommand {
    Objects.requireNonNull(schoolId, "schoolId");
    Objects.requireNonNull(fileName, "fileName");
    Objects.requireNonNull(content, "content");
    Objects.requireNonNull(actorId, "actorId");
    Objects.requireNonNull(actorRole, "actorRole");
  }
}
