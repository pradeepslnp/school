package com.guardian.student.application.port;

import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentId;
import java.util.Optional;

/**
 * Persistence for {@link Student}.
 *
 * <p>Every method is implicitly tenant-scoped: row-level security applies the {@code tenant_id}
 * predicate to every statement (ADR-0001). Adding an application-level filter would imply isolation
 * depends on remembering it.
 *
 * <p>Note what is absent: there is no {@code findAll} and no general {@code delete}. Every read is
 * bounded (DEFINITION_OF_DONE.md §8) — a school has thousands of students and an unbounded register
 * query is the one that takes the console down. BR-STU-005 keeps every student with history; the
 * one removal, {@link #discard}, is for a record entered by mistake (BR-STU-007) and is refused by
 * the database whenever that history exists.
 */
public interface StudentRepository {

  Optional<Student> findById(StudentId id);

  /**
   * One page of a school's register, ordered by admission number.
   *
   * <p>Keyset pagination, not offset (API_STANDARDS.md). {@code afterAdmissionNo} is the last row
   * of the previous page; null starts at the beginning. Offset pagination would re-scan every
   * skipped row and, worse, silently drop or repeat a student when one is enrolled mid-paging —
   * which on a register is a child who does not appear on the screen someone is checking.
   *
   * @param limit maximum rows to return; the caller asks for one more than it needs to detect
   *     whether a further page exists
   */
  StudentPage findBySchool(SchoolId schoolId, AdmissionNumber afterAdmissionNo, int limit);

  boolean existsByAdmissionNo(SchoolId schoolId, AdmissionNumber admissionNo);

  Student save(Student student);

  /**
   * Deletes every boarding credential issued to a student being discarded (BR-STU-007). Never used
   * to retire a credential in service — that is a revocation.
   *
   * @return how many were removed
   */
  int deleteCredentials(StudentId id);

  /**
   * Permanently deletes a student entered by mistake (BR-STU-007, ADR-0019). Its credentials,
   * guardian links and route assignments must already have been removed in the same transaction.
   *
   * @return {@code false} if anything else still references the student — the database refused the
   *     delete, and the surrounding transaction can now only be rolled back
   */
  boolean discard(StudentId id);
}
