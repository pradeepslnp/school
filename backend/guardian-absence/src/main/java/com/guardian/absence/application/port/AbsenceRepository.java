package com.guardian.absence.application.port;

import com.guardian.absence.domain.Absence;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Persistence for declared absences, in the domain's language rather than the ORM's.
 *
 * <p>Method names describe intent — {@code findActiveForStudent}, not {@code
 * findByStudentIdAndStatusEquals}.
 */
public interface AbsenceRepository {

  Absence save(Absence absence, UUID actorUserId);

  /** Active declarations for a student, soonest first. Cancelled ones are excluded. */
  List<Absence> findActiveForStudent(UUID studentId);

  Optional<Absence> findById(UUID absenceId);

  /** Marks an absence cancelled. Never deletes it — see {@link Absence.Status}. */
  void cancel(UUID absenceId, UUID actorUserId);

  /**
   * Whether a trip covering this student, date and run has already started.
   *
   * <p>The BR-ABS-003 check. Lives behind the port because the answer is in MOD-08's tables and
   * this module must not reach into them from a use case — the adapter is the one place that knows,
   * and it is a read of a single boolean rather than a dependency on the trip module.
   */
  boolean tripAlreadyStarted(UUID studentId, LocalDate date, Absence.Direction direction);

  /**
   * Whether the calling user is a guardian of this student holding {@code can_declare_absence}.
   *
   * <p>{@code PERM-ABSENCE-DECLARE} for a guardian additionally requires that right on the
   * relationship (BR-ABS-001, PERMISSION_MATRIX.md) — holding the permission is necessary and never
   * sufficient, and object-level scope is exactly what an endpoint permission cannot express.
   */
  Optional<UUID> declaringGuardianIdFor(UUID userId, UUID studentId);
}
