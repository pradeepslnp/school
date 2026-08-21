package com.guardian.parent.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.parent.application.port.ParentReadModel;
import com.guardian.parent.application.result.ChildDetailView;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * One child in full — screen P-03.
 *
 * <p>The only decision here is what an absent result means, and it is a security decision rather
 * than a lookup one: a student the caller holds no active link to and a student that does not exist
 * produce the same {@code AUTH_SCOPE_DENIED}. Answering {@code 404} for one and {@code 403} for the
 * other would confirm to a guessing caller that a particular child exists at this school, which is
 * exactly the fact BR-IAM-005 exists to withhold.
 */
@Service
public class GetChildDetailUseCase {

  private final ParentReadModel readModel;

  public GetChildDetailUseCase(ParentReadModel readModel) {
    this.readModel = readModel;
  }

  @Transactional(readOnly = true)
  public ChildDetailView execute(UUID guardianUserId, UUID studentId) {
    return readModel
        .childDetail(guardianUserId, studentId)
        // AUTH_SCOPE_DENIED, not a 404: within a tenant, "not yours" is the honest answer and
        // 404 would be a probing oracle (API_STANDARDS.md § 403 vs 404).
        .orElseThrow(
            () -> new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "student", studentId));
  }
}
