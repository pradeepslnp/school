package com.guardian.parent.application.port;

import com.guardian.parent.application.result.ChildDetailView;
import com.guardian.parent.application.result.DashboardView;
import com.guardian.parent.application.result.JourneyHistoryView;
import java.util.Optional;
import java.util.UUID;

/**
 * The parent app's composed reads.
 *
 * <p>One port, one adapter, one file of cross-module SQL (ADR-0010). Keeping the projection behind
 * this interface is what makes the accepted coupling reversible: when MOD-08 maintains a
 * denormalised {@code student_journey_states} table, a second adapter implements this and nothing
 * above it changes.
 *
 * <p><strong>Scope is the implementation's job, not the caller's.</strong> Every method takes the
 * calling guardian's user id and must join through {@code guardian_student_links} so a child the
 * caller holds no active link to cannot be returned at all (BR-IAM-005). A port that returned
 * everything and left filtering to a use case would put the safety decision one forgotten {@code
 * filter} away from a family seeing another family's child.
 *
 * <p>Read-only by construction: there is no write method here, and there must never be one.
 */
public interface ParentReadModel {

  /**
   * Every child the calling guardian may see, with each one's current journey state.
   *
   * <p>Returns an empty list — never an error — for a guardian with no linked children. "No
   * children linked yet" is an ordinary state the app renders as an explanation, not a failure.
   *
   * @param guardianUserId the authenticated user, resolved server-side from the session
   */
  DashboardView childrenOf(UUID guardianUserId);

  /**
   * One child in full, or empty when the caller holds no active link to them.
   *
   * <p>Empty covers both "no such student" and "not your child" deliberately. Distinguishing them
   * would confirm the existence of a specific child to someone not entitled to know it; the caller
   * turns both into the same {@code 403} (guardian-docs/04-api/API_STANDARDS.md § 403 vs 404).
   */
  Optional<ChildDetailView> childDetail(UUID guardianUserId, UUID studentId);

  /**
   * One child's past journeys, newest first (P-05).
   *
   * <p>Scoped identically: an empty list is returned for a student the caller is not linked to, so
   * a caller learns nothing from the difference between "no history" and "not your child".
   *
   * @param limit hard cap on rows returned. Bounded rather than open-ended because this is the one
   *     parent read whose size grows without limit over a school year, and an unbounded default is
   *     a slow query waiting for a long-enrolled child.
   */
  JourneyHistoryView journeyHistory(UUID guardianUserId, UUID studentId, int limit);
}
