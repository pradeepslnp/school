package com.guardian.student.infrastructure.persistence;

import com.guardian.student.application.port.StudentPage;
import com.guardian.student.application.port.StudentRepository;
import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Component;

/** Implements {@link StudentRepository} over JPA. */
@Component
class StudentRepositoryAdapter implements StudentRepository {

  private final StudentJpaRepository jpaRepository;
  private final StudentPersistenceMapper mapper;

  StudentRepositoryAdapter(StudentJpaRepository jpaRepository, StudentPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<Student> findById(StudentId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public StudentPage findBySchool(SchoolId schoolId, AdmissionNumber afterAdmissionNo, int limit) {

    // One more than asked for. Whether a further page exists is then a fact about what came back
    // rather than a second COUNT query over the same rows.
    Limit probe = Limit.of(limit + 1);

    List<StudentEntity> rows =
        afterAdmissionNo == null
            ? jpaRepository.findFirstPage(schoolId.value(), probe)
            : jpaRepository.findPageAfter(schoolId.value(), afterAdmissionNo.value(), probe);

    boolean hasMore = rows.size() > limit;
    List<StudentEntity> page = hasMore ? rows.subList(0, limit) : rows;

    List<Student> students = new ArrayList<>(page.size());
    page.forEach(entity -> students.add(mapper.toDomain(entity)));

    String nextCursor = hasMore ? students.get(students.size() - 1).admissionNo().value() : null;

    return new StudentPage(students, nextCursor);
  }

  @Override
  public boolean existsByAdmissionNo(SchoolId schoolId, AdmissionNumber admissionNo) {
    return jpaRepository.existsBySchoolIdAndAdmissionNo(schoolId.value(), admissionNo.value());
  }

  @Override
  public Student save(Student student) {
    // Loads the managed instance and mutates it rather than persisting a detached copy: only then
    // do Hibernate's dirty checking and @Version apply. A detached save would bypass optimistic
    // locking and let one administrator's edit silently overwrite another's.
    StudentEntity entity =
        jpaRepository
            .findById(student.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, student);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(student));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
