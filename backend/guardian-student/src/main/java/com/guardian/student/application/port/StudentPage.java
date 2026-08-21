package com.guardian.student.application.port;

import com.guardian.student.domain.Student;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * One page of students, with the cursor that reaches the next.
 *
 * <p>{@code nextCursor} is empty when this is the last page. It is the admission number of the last
 * row rather than a row count, because the next query resumes from a value rather than a position —
 * see {@link StudentRepository#findBySchool}.
 */
public record StudentPage(List<Student> students, String nextCursor) {

  public StudentPage {
    students = List.copyOf(Objects.requireNonNull(students, "students"));
  }

  public static StudentPage lastPage(List<Student> students) {
    return new StudentPage(students, null);
  }

  public Optional<String> cursor() {
    return Optional.ofNullable(nextCursor);
  }

  public boolean hasMore() {
    return nextCursor != null;
  }
}
