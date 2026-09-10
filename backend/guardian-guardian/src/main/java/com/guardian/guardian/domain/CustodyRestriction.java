package com.guardian.guardian.domain;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * A person barred from collecting — or from seeing — a child, whatever else the system says
 * (BR-GRD-008 🔴, BR-HAND-006 🔴).
 *
 * <p>Evaluated before every handover and before every visibility check: a restriction beats an
 * active guardian link that grants {@code can_authorise_handover}. It is the one record in the
 * platform that overrides an explicit right rather than being one.
 *
 * <p>The subject is <strong>exactly one of</strong> a guardian on file ({@link
 * #restrictedGuardianId}) or a named non-guardian ({@link #restrictedPersonName}) — {@code
 * ck_custody_subject} on the table enforces it, and this type refuses to be built any other way.
 *
 * <p>{@code reason} is required and never optional: a restriction without a recorded reason is not
 * evidence, and this is the kind of record read years later during a dispute.
 *
 * <p>Never exposed in any guardian-facing response — not to the restricted person, not to anyone.
 * Only holders of {@code PERM-CUSTODY-RESTRICTION-MANAGE} ever see one.
 */
public record CustodyRestriction(
    UUID id,
    UUID studentId,
    UUID restrictedGuardianId,
    String restrictedPersonName,
    Type type,
    String reason,
    Instant effectiveFrom,
    Instant effectiveUntil,
    boolean active) {

  /** Matches {@code ck_custody_type} on the table. */
  public enum Type {
    /** May not collect the child. Visibility is unaffected. */
    NO_HANDOVER,
    /** May not see the child's location or journey. Collection is handled elsewhere. */
    NO_VISIBILITY,
    /** Both. */
    FULL;

    public static Type fromStored(String stored) {
      return valueOf(stored);
    }
  }

  public CustodyRestriction {
    Objects.requireNonNull(studentId, "studentId");
    Objects.requireNonNull(type, "type");
    if (reason == null || reason.isBlank()) {
      throw new IllegalArgumentException("reason is required for a custody restriction");
    }
    reason = reason.trim();
    boolean hasGuardian = restrictedGuardianId != null;
    boolean hasName = restrictedPersonName != null && !restrictedPersonName.isBlank();
    if (hasGuardian == hasName) {
      throw new IllegalArgumentException(
          "a custody restriction names exactly one of a guardian or a person");
    }
    restrictedPersonName = hasName ? restrictedPersonName.trim() : null;
    Objects.requireNonNull(effectiveFrom, "effectiveFrom");
    if (effectiveUntil != null && !effectiveUntil.isAfter(effectiveFrom)) {
      throw new IllegalArgumentException("effectiveUntil must be after effectiveFrom");
    }
  }

  /**
   * Whether this restriction is in force at {@code at}. Lifting it is immediate (sets {@link
   * #active} false), so an inactive restriction never applies regardless of its window.
   */
  public boolean appliesAt(Instant at) {
    return active
        && !at.isBefore(effectiveFrom)
        && (effectiveUntil == null || at.isBefore(effectiveUntil));
  }
}
