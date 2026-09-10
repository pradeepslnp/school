package com.guardian.student.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.student.application.port.StudentImportJobRepository;
import com.guardian.student.domain.ImportRowError;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.StudentImportJob;
import com.guardian.student.domain.StudentImportJobId;
import com.guardian.student.domain.StudentImportStatus;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Implements {@link StudentImportJobRepository} over JPA. */
@Component
class StudentImportJobRepositoryAdapter implements StudentImportJobRepository {

  private final StudentImportJobJpaRepository jobJpa;
  private final StudentImportRowErrorJpaRepository errorJpa;

  StudentImportJobRepositoryAdapter(
      StudentImportJobJpaRepository jobJpa, StudentImportRowErrorJpaRepository errorJpa) {
    this.jobJpa = jobJpa;
    this.errorJpa = errorJpa;
  }

  @Override
  public StudentImportJob save(StudentImportJob job) {
    // Flush the parent before the children: student_import_row_errors.job_id is a foreign key,
    // and Hibernate does not otherwise guarantee it orders inserts of different entity types.
    jobJpa.saveAndFlush(
        new StudentImportJobEntity(
            job.id().value(),
            job.tenantId().value(),
            job.schoolId().value(),
            job.uploadedBy(),
            job.uploadedRole(),
            job.fileName(),
            job.status().name(),
            job.totalRows(),
            job.successCount(),
            job.errorCount(),
            job.createdAt(),
            job.completedAt()));

    List<StudentImportRowErrorEntity> errorRows =
        job.rowErrors().stream()
            .map(
                error ->
                    new StudentImportRowErrorEntity(
                        UUID.randomUUID(),
                        job.tenantId().value(),
                        job.id().value(),
                        error.rowNumber(),
                        error.field(),
                        error.code(),
                        error.message(),
                        Instant.now()))
            .toList();
    errorJpa.saveAll(errorRows);

    return job;
  }

  @Override
  public Optional<StudentImportJob> findById(StudentImportJobId id) {
    return jobJpa.findById(id.value()).map(this::toDomain);
  }

  private StudentImportJob toDomain(StudentImportJobEntity entity) {
    List<ImportRowError> errors =
        errorJpa.findByJobIdOrderByRowNumberAsc(entity.getId()).stream()
            .map(
                row ->
                    ImportRowError.of(
                        row.getRowNumber(), row.getField(), row.getErrorCode(), row.getMessage()))
            .toList();

    return new StudentImportJob(
        StudentImportJobId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        SchoolId.of(entity.getSchoolId()),
        entity.getUploadedBy(),
        entity.getUploadedRole(),
        entity.getFileName(),
        StudentImportStatus.fromStored(entity.getStatus()),
        entity.getTotalRows(),
        entity.getSuccessCount(),
        entity.getErrorCount(),
        errors,
        entity.getCreatedAt(),
        entity.getCompletedAt());
  }
}
