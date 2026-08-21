package com.guardian.absence.application.usecase;

import com.guardian.absence.application.port.AbsenceRepository;
import com.guardian.absence.domain.Absence;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Active absences for one child (feature ABS-001).
 *
 * <p>Scoped the same way as declaring one: the caller must be a guardian of this child. A parent
 * who may not declare an absence may still hold {@code PERM-ABSENCE-VIEW}, so the check here is
 * link membership rather than the declare right.
 */
@Service
public class ListAbsencesUseCase {

  private final AbsenceRepository absences;

  public ListAbsencesUseCase(AbsenceRepository absences) {
    this.absences = absences;
  }

  @Transactional(readOnly = true)
  public List<Absence> execute(UUID actorUserId, UUID studentId) {
    if (absences.declaringGuardianIdFor(actorUserId, studentId).isEmpty()) {
      throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "student", studentId);
    }
    return absences.findActiveForStudent(studentId);
  }
}
