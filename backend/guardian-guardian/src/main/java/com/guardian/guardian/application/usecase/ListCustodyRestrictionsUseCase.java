package com.guardian.guardian.application.usecase;

import com.guardian.guardian.application.port.CustodyRestrictionRepository;
import com.guardian.guardian.domain.CustodyRestriction;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Every custody restriction on a student — active and lifted — for screen A-14 (feature GRD-006).
 *
 * <p>Read-only, tenant-scoped by row-level security. The controller's {@code
 * PERM-CUSTODY-RESTRICTION-MANAGE} is the gate; there is no guardian path to this data at all, by
 * design (BR-GRD-008 🔴).
 */
@Service
public class ListCustodyRestrictionsUseCase {

  private final CustodyRestrictionRepository restrictions;

  public ListCustodyRestrictionsUseCase(CustodyRestrictionRepository restrictions) {
    this.restrictions = restrictions;
  }

  @Transactional(readOnly = true)
  public List<CustodyRestriction> execute(UUID studentId) {
    return restrictions.findAllForStudent(studentId);
  }
}
