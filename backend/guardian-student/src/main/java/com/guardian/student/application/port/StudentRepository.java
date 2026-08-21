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
 * <p>Note what is absent: there is no {@code findAll} and no {@code delete}. Every read is bounded
 * (DEFINITION_OF_DONE.md §8) — a school has thousands of students and an unbounded register query
 * is the one that takes the console down. And BR-STU-005 permits no delete path at all.
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
}
