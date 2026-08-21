package com.guardian.parent.application.usecase;

import com.guardian.parent.application.port.ParentReadModel;
import com.guardian.parent.application.result.JourneyHistoryView;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** One child's past journeys — feature BRD-003, screen P-05. */
@Service
public class GetJourneyHistoryUseCase {

  /**
   * Roughly a school term of legs (two per day). Enough that a parent scrolling back finds what
   * they are looking for, small enough that the query stays bounded for a child enrolled for years.
   * Paging arrives when a screen actually asks for it; a cap now beats an unbounded read later.
   */
  private static final int DEFAULT_LIMIT = 120;

  private final ParentReadModel readModel;

  public GetJourneyHistoryUseCase(ParentReadModel readModel) {
    this.readModel = readModel;
  }

  @Transactional(readOnly = true)
  public JourneyHistoryView execute(UUID guardianUserId, UUID studentId) {
    // An empty list rather than a refusal for a student the caller is not linked to: the port
    // scopes the query, so "not yours" and "nothing happened yet" are indistinguishable here by
    // design (BR-IAM-005).
    return readModel.journeyHistory(guardianUserId, studentId, DEFAULT_LIMIT);
  }
}
