package com.guardian.student.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for {@code student_import_row_errors}. Package-private.
 *
 * <p>No {@code tenant_id} filter: row-level security applies it (ADR-0001).
 */
interface StudentImportRowErrorJpaRepository
    extends JpaRepository<StudentImportRowErrorEntity, UUID> {

  List<StudentImportRowErrorEntity> findByJobIdOrderByRowNumberAsc(UUID jobId);
}
