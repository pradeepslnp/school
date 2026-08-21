package com.guardian.student.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.BranchId;
import com.guardian.student.domain.EnrolmentStatus;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentClassId;
import com.guardian.student.domain.StudentId;
import org.springframework.stereotype.Component;

/** Translates between {@link Student} and its JPA mapping. */
@Component
class StudentPersistenceMapper {

  Student toDomain(StudentEntity entity) {
    return new Student(
        StudentId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        SchoolId.of(entity.getSchoolId()),
        entity.getBranchId() == null ? null : BranchId.of(entity.getBranchId()),
        entity.getStudentClassId() == null ? null : StudentClassId.of(entity.getStudentClassId()),
        AdmissionNumber.of(entity.getAdmissionNo()),
        entity.getFirstName(),
        entity.getLastName(),
        entity.getDateOfBirth(),
        entity.getPhotoRef(),
        EnrolmentStatus.fromStored(entity.getEnrolmentStatus()),
        entity.isTransportEligible(),
        entity.getVersion());
  }

  StudentEntity toEntity(Student student) {
    return new StudentEntity(
        student.id().value(),
        student.tenantId().value(),
        student.schoolId().value(),
        student.branchId().map(BranchId::value).orElse(null),
        student.studentClassId().map(StudentClassId::value).orElse(null),
        student.admissionNo().value(),
        student.firstName(),
        student.lastName(),
        student.dateOfBirth().orElse(null),
        student.photoRef().orElse(null),
        student.enrolmentStatus().name(),
        student.transportEligible());
  }

  void applyTo(StudentEntity managed, Student student) {
    managed.applyMutableState(
        student.branchId().map(BranchId::value).orElse(null),
        student.studentClassId().map(StudentClassId::value).orElse(null),
        student.firstName(),
        student.lastName(),
        student.dateOfBirth().orElse(null),
        student.photoRef().orElse(null),
        student.enrolmentStatus().name(),
        student.transportEligible());
  }
}
