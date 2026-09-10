package com.guardian.student.infrastructure.persistence;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Spring Data repository for {@code student_import_jobs}. Package-private — callers use {@link
 * com.guardian.student.application.port.StudentImportJobRepository}.
 *
 * <p>Nothing here filters on {@code tenant_id}: row-level security applies that predicate to every
 * statement (ADR-0001).
 */
interface StudentImportJobJpaRepository extends JpaRepository<StudentImportJobEntity, UUID> {}
