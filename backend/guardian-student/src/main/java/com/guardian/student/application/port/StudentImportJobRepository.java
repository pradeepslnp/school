package com.guardian.student.application.port;

import com.guardian.student.domain.StudentImportJob;
import com.guardian.student.domain.StudentImportJobId;
import java.util.Optional;

/**
 * Persistence for {@link StudentImportJob} (feature STU-002).
 *
 * <p>Tenant-scoped implicitly, like every repository here: row-level security applies the {@code
 * tenant_id} predicate (ADR-0001).
 *
 * <p>Note what is absent — no update, and no delete. An import job records what a past upload did;
 * its row errors are facts about that run. Both are append-only in the schema (V17), so there is
 * nothing here that could change one after it is written.
 */
public interface StudentImportJobRepository {

  /**
   * Persists a finished job together with its row errors, in the caller's transaction.
   *
   * @return the job as stored
   */
  StudentImportJob save(StudentImportJob job);

  Optional<StudentImportJob> findById(StudentImportJobId id);
}
