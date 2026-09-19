package com.guardian.parent.interfaces.rest;

import com.guardian.common.security.CallerAccess;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.parent.application.usecase.GetStudentTransportUseCase;
import com.guardian.parent.interfaces.rest.dto.StudentTransportResource;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/**
 * The student record's transport panel for school staff — feature STU-009, screen A-11. See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md § Student transport and journey.
 *
 * <p>Served here rather than by MOD-03: it composes routes, fleet and staff, which sit above the
 * student module (ADR-0020, extending ADR-0010). {@code PERM-STUDENT-VIEW} is necessary, and the
 * caller's school scope decides the rest inside the query — a guardian or crew member, whose scope
 * reaches no school, is answered {@code 404}.
 */
@RestController
public class StudentTransportController {

  private final GetStudentTransportUseCase getStudentTransport;

  public StudentTransportController(GetStudentTransportUseCase getStudentTransport) {
    this.getStudentTransport = getStudentTransport;
  }

  @GetMapping("/api/v1/students/{studentId}/transport")
  @RequiresPermission("PERM-STUDENT-VIEW")
  public StudentTransportResource transport(
      @PathVariable UUID studentId, CurrentActor actor, CallerAccess access) {
    return StudentTransportResource.from(
        getStudentTransport.execute(studentId, access.scope(), actor));
  }
}
