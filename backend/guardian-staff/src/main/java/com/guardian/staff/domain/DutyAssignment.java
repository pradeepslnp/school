package com.guardian.staff.domain;

import com.guardian.common.tenant.TenantId;
import java.time.LocalDate;
import java.util.Objects;
import java.util.Optional;

/**
 * The standing crew for a route (feature STF-004) — which driver or attendant normally runs it.
 *
 * <p>Immutable: state changes return new instances. Contains no framework annotations of any kind —
 * an architecture test fails the build if Spring, JPA, or Jackson types reach this package
 * (guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md).
 *
 * <p>This is the <em>default</em> crew, not who is actually on today's vehicle — that is {@code
 * trip_staff} (MOD-08, not yet built), kept separate so a one-off substitution (BR-STAFF-006) does
 * not rewrite the standing roster. Eligibility to actually start a trip (valid licence, current
 * verification — BR-STAFF-001/002) is checked at trip start, not here: an assignment records
 * intent, and intent can be recorded before every credential is in place.
 */
public final class DutyAssignment {

  private final DutyAssignmentId id;
  private final TenantId tenantId;
  private final StaffId staffId;
  private final RouteId routeId;
  private final StaffType role;
  private final Direction direction;
  private final LocalDate effectiveFrom;
  private final LocalDate effectiveUntil;
  private final boolean active;
  private final long version;

  public DutyAssignment(
      DutyAssignmentId id,
      TenantId tenantId,
      StaffId staffId,
      RouteId routeId,
      StaffType role,
      Direction direction,
      LocalDate effectiveFrom,
      LocalDate effectiveUntil,
      boolean active,
      long version) {
    this.id = Objects.requireNonNull(id, "id");
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
    this.staffId = Objects.requireNonNull(staffId, "staffId");
    this.routeId = Objects.requireNonNull(routeId, "routeId");
    this.role = Objects.requireNonNull(role, "role");
    this.direction = direction;
    this.effectiveFrom = Objects.requireNonNull(effectiveFrom, "effectiveFrom");
    this.effectiveUntil = effectiveUntil;
    this.active = active;
    this.version = version;
  }

  /** Creates a new, active assignment starting today (feature STF-004). */
  public static DutyAssignment create(
      TenantId tenantId, StaffId staffId, RouteId routeId, StaffType role, Direction direction) {
    return new DutyAssignment(
        DutyAssignmentId.generate(),
        tenantId,
        staffId,
        routeId,
        role,
        direction,
        LocalDate.now(),
        null,
        true,
        0L);
  }

  public DutyAssignment deactivate() {
    return new DutyAssignment(
        id,
        tenantId,
        staffId,
        routeId,
        role,
        direction,
        effectiveFrom,
        effectiveUntil,
        false,
        version);
  }

  public DutyAssignmentId id() {
    return id;
  }

  public TenantId tenantId() {
    return tenantId;
  }

  public StaffId staffId() {
    return staffId;
  }

  public RouteId routeId() {
    return routeId;
  }

  public StaffType role() {
    return role;
  }

  public Optional<Direction> direction() {
    return Optional.ofNullable(direction);
  }

  public LocalDate effectiveFrom() {
    return effectiveFrom;
  }

  public Optional<LocalDate> effectiveUntil() {
    return Optional.ofNullable(effectiveUntil);
  }

  public boolean active() {
    return active;
  }

  public long version() {
    return version;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) {
      return true;
    }
    return other instanceof DutyAssignment assignment && id.equals(assignment.id);
  }

  @Override
  public int hashCode() {
    return id.hashCode();
  }

  @Override
  public String toString() {
    return "DutyAssignment[" + id + ", " + role + " on " + routeId + "]";
  }
}
