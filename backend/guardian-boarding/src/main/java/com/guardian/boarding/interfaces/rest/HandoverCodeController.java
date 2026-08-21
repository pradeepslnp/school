package com.guardian.boarding.interfaces.rest;

import com.guardian.boarding.application.usecase.RequestHandoverCodeUseCase;
import com.guardian.boarding.domain.HandoverCode;
import com.guardian.boarding.interfaces.rest.dto.HandoverCodeResponse;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Handover verification code issuance — feature P-12. See guardian-docs/05-ui/PARENT_APP.md § P-12
 * — Handover Verification.
 *
 * <p>Nested under the student, same reasoning as {@code PickupPersonController}: a code has no
 * meaning apart from the child it concerns.
 *
 * <p>This layer only translates. The right check (BR-GRD-006) and code generation live in {@link
 * RequestHandoverCodeUseCase}.
 */
@RestController
@RequestMapping("/api/v1/students/{studentId}")
public class HandoverCodeController {

  private final RequestHandoverCodeUseCase requestHandoverCode;

  public HandoverCodeController(RequestHandoverCodeUseCase requestHandoverCode) {
    this.requestHandoverCode = requestHandoverCode;
  }

  /**
   * Issues a fresh code, superseding any code already live for this student.
   *
   * <p>Not idempotent, and deliberately so: opening P-12 a second time before the first code
   * expired should hand the parent a code that still has its full ten minutes, not the remainder of
   * one they may have already shown someone.
   */
  @PostMapping("/handover-code")
  @RequiresPermission("PERM-HANDOVER-CODE-REQUEST")
  public ResponseEntity<HandoverCodeResponse> requestCode(
      @PathVariable UUID studentId, CurrentActor actor) {

    HandoverCode issued = requestHandoverCode.execute(studentId, actor.userId(), actor.role());
    return ResponseEntity.ok(HandoverCodeResponse.from(issued));
  }
}
