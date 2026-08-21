package com.guardian.common.audit;

import java.util.List;

/**
 * Records reads of child personal data (BR-IAM-012 🔴). Implemented in infrastructure; called from
 * use cases.
 *
 * <p>Like {@link AuditPort}, the implementation participates in the caller's transaction: a read
 * that could not be recorded is a read the platform declines to have performed. The asymmetry with
 * ordinary logging is deliberate — this table is evidence, and evidence that is best-effort is not
 * evidence.
 */
public interface DataAccessPort {

  void record(DataAccessRecord record);

  /**
   * Records a whole listing at once.
   *
   * <p>A listing produces one row per student (see {@link DataAccessRecord}), so a register page of
   * fifty is fifty rows. Batched rather than looped so that cost is one round trip, not fifty.
   */
  void recordAll(List<DataAccessRecord> records);
}
