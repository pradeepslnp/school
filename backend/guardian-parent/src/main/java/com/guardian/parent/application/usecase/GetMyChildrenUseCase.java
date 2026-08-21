package com.guardian.parent.application.usecase;

import com.guardian.parent.application.port.ParentReadModel;
import com.guardian.parent.application.result.DashboardView;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The parent dashboard read — feature GRD-007, screen P-02.
 *
 * <p>P-02 is the product: it answers "is my child fine?" with zero taps
 * (guardian-docs/05-ui/SCREEN_INVENTORY.md), which is why the whole dashboard is one call and one
 * query rather than a fan-out per child. On mobile data, at the moment the answer matters most, N+1
 * is not a performance note — it is the difference between an answer and a spinner.
 *
 * <p>This class is deliberately thin. There is no rule here to enforce: scope is enforced inside
 * the projection (BR-IAM-005), and the shaping is the controller's. A use case that only delegates
 * is still worth its file — it is the seam where auditing the read (BR-IAM-012) will attach when
 * data-access recording lands, and putting it in later without this class means editing a
 * controller.
 */
@Service
public class GetMyChildrenUseCase {

  private final ParentReadModel readModel;

  public GetMyChildrenUseCase(ParentReadModel readModel) {
    this.readModel = readModel;
  }

  /**
   * Reads in a transaction because tenant context is bound with {@code SET LOCAL} at transaction
   * start (ADR-0001). Outside one, {@code app.tenant_id} is unset and row-level security correctly
   * returns nothing at all.
   */
  @Transactional(readOnly = true)
  public DashboardView execute(UUID guardianUserId) {
    return readModel.childrenOf(guardianUserId);
  }
}
