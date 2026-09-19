package com.guardian.parent.application.port;

import com.guardian.common.security.AccessScope;
import com.guardian.parent.application.result.StudentTransportView;
import java.util.Optional;
import java.util.UUID;

/**
 * The staff-facing read of a student's assigned transport (feature STU-009, ADR-0020).
 *
 * <p>Composed across MOD-07 (route assignment, route, stop), MOD-05 (the route's default bus) and
 * MOD-06 (today's duty crew) under the same bounded exception ADR-0010 accepts for the parent app:
 * read-only, one adapter file, row-level security still applying.
 *
 * <p><strong>Scope is the implementation's job.</strong> The student's school must lie within
 * {@code scope}, and that is decided in the query itself (BR-IAM-006). Out of scope and not found
 * are the same empty result, so a caller cannot probe for students in other schools.
 */
public interface StudentTransportReadModel {

  Optional<StudentTransportView> transportOf(UUID studentId, AccessScope scope);
}
