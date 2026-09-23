package com.guardian.common.error;

/**
 * Stable error identifiers returned to clients.
 *
 * <p>Every value here must appear in guardian-docs/04-api/ERROR_CATALOG.md with its HTTP status and
 * business rule — a CI check fails the build otherwise. Codes are never reused for a different
 * meaning.
 *
 * <p>Carries no user-facing text: {@link #messageKey()} names a localisation resource (BR-CFG-005).
 */
public enum ErrorCode {

  // --- Authentication & authorization -------------------------------------------------
  AUTH_CREDENTIALS_INVALID(401),
  AUTH_TOKEN_MISSING(401),
  AUTH_TOKEN_EXPIRED(401),
  AUTH_TOKEN_INVALID(401),
  AUTH_SESSION_REVOKED(401),
  AUTH_REFRESH_REUSE_DETECTED(401),
  AUTH_ACCOUNT_LOCKED(401),
  // Both mean the code can never succeed however it is retyped, which is why they are
  // distinct from AUTH_CREDENTIALS_INVALID: the client sends the guardian back for a fresh
  // code rather than letting them retype into a dead field.
  AUTH_OTP_EXPIRED(401),
  AUTH_OTP_ALREADY_USED(401),
  // Account-activation / password-reset link tokens (ADR-0012). Distinct from the OTP codes and
  // from each other so the accept/reset pages can tell a person to request a fresh link rather
  // than retype into a dead one. Holding the token is not a secret worth protecting by enumeration
  // — the person followed the link — so, unlike the OTP path, these report the specific condition.
  AUTH_LINK_INVALID(400),
  AUTH_LINK_EXPIRED(410),
  AUTH_LINK_ALREADY_USED(410),
  AUTH_PERMISSION_DENIED(403),
  AUTH_SCOPE_DENIED(403),
  AUTH_TENANT_MISMATCH(404),
  AUTH_JUSTIFICATION_REQUIRED(403),

  // --- Identity & Access (MOD-02) ------------------------------------------------------
  USER_EMAIL_EXISTS(409),
  USER_NOT_FOUND(404),
  // Operator-initiated invite/reset (ADR-0012): resending an invitation only makes sense for an
  // account still awaiting activation, and sending a reset link only for one that can sign in.
  USER_NOT_PENDING(409),
  USER_NOT_ACTIVE(409),
  // A well-formed password refused by policy (BR-IAM-013). 422, not 400: the request parsed fine,
  // the value is simply too weak — thrown as a BusinessRuleViolationException.
  PASSWORD_TOO_WEAK(422),
  // A session id in a path does not resolve for this caller: it is already gone, or — on the
  // self-service path — belongs to someone else. 404 rather than 403 so the endpoint cannot be
  // used to confirm another person's session id exists (IAM-004).
  SESSION_NOT_FOUND(404),
  // The account holds no role assignable through the console — a system role provisioned for a
  // driver/attendant, or a role code the matrix does not list. Blocks assigning or removing it
  // from the Users screen (BR-IAM-003, A-43).
  ROLE_NOT_ASSIGNABLE(422),
  // The scope in the request is not one this role may carry: a SCHOOL scope for an org-wide role,
  // or a ROUTE scope for a role that is not route-bound (BR-IAM-006).
  USER_SCOPE_NOT_PERMITTED_FOR_ROLE(422),

  // --- Validation ---------------------------------------------------------------------
  VALIDATION_FAILED(400),
  VALIDATION_REQUIRED_FIELD_MISSING(400),
  VALIDATION_INVALID_FORMAT(400),
  VALIDATION_VALUE_OUT_OF_RANGE(400),

  // --- Tenancy ------------------------------------------------------------------------
  ORG_CODE_ALREADY_EXISTS(409),
  ORG_SUSPENDED(403),
  ORG_LAST_SCHOOL_CANNOT_BE_REMOVED(422),
  ORG_CANNOT_SUSPEND_OWN_ORGANIZATION(422),
  SCHOOL_CODE_ALREADY_EXISTS(409),
  SCHOOL_CANNOT_CHANGE_ORGANIZATION(422),
  SCHOOL_NOT_FOUND(404),
  ORGANIZATION_NOT_FOUND(404),

  // --- Students & guardians -------------------------------------------------------------
  STUDENT_NOT_FOUND(404),
  // 409, not 422: the request is well-formed and the rule is satisfiable — the office needs to
  // pick a different number, not a different kind of request (BR-STU-003).
  STUDENT_ADMISSION_NO_EXISTS(409),
  STUDENT_NOT_ACTIVE(422),
  // BR-STU-002: a child must not be put on a bus with no guardian authorised to receive
  // them at the other end. Blocks route assignment until at least one exists.
  STUDENT_HAS_NO_ACTIVE_GUARDIAN(422),
  // BR-STU-007 / ADR-0019: a discard was refused because something other than the student's own
  // links, assignments, or credentials still references it. The student is withdrawn instead.
  STUDENT_HAS_SAFETY_RECORDS(422),
  GUARDIAN_NOT_FOUND(404),
  // BR-IAM-014: the corrected phone's sign-in account already belongs to a different guardian
  // record. Relinking would merge two people's access, so the office resolves which is right.
  GUARDIAN_PHONE_IN_USE(409),
  // 403, not 422: the caller lacks the handover right on the relationship, which is an
  // authorisation fact rather than a malformed nomination (BR-GRD-006).
  GUARDIAN_NOT_AUTHORISED_TO_NOMINATE(403),
  PICKUP_PERSON_OUTSIDE_VALIDITY(422),
  PICKUP_PERSON_REVOKED(422),
  // Same underlying right as GUARDIAN_NOT_AUTHORISED_TO_NOMINATE (can_authorise_handover,
  // BR-GRD-006) but a distinct code: this guards *requesting a release code*, not nominating
  // a pickup person, and a client should never have to infer which action a shared code means.
  GUARDIAN_NOT_AUTHORISED_FOR_HANDOVER(403),
  // A custody restriction id in a path does not resolve within the caller's tenant, or does not
  // belong to the student in the path (GRD-006 / A-14).
  CUSTODY_RESTRICTION_NOT_FOUND(404),
  // The request names neither a guardian nor a person — ck_custody_subject requires exactly one
  // (BR-GRD-008).
  CUSTODY_RESTRICTION_SUBJECT_REQUIRED(422),

  // --- Bulk student import (STU-002, screen A-12) ---------------------------------------
  STUDENT_IMPORT_NOT_FOUND(404),
  // The whole upload is rejected before any row is processed: nothing to enrol, or a byte
  // stream that is not the CSV it claimed to be. 400 — the request itself is malformed.
  STUDENT_IMPORT_FILE_EMPTY(400),
  STUDENT_IMPORT_FILE_UNREADABLE(400),
  // The header names a column this version does not process (e.g. a guardian or stop column).
  // Rejected wholesale rather than silently ignored — enrolling students while dropping data
  // the office believed it was providing is the more dangerous outcome.
  STUDENT_IMPORT_UNSUPPORTED_COLUMN(400),
  // 422: the file is well-formed but larger than one synchronous request should process. The
  // office splits it; a future asynchronous job lifts the limit (STUDENTS_GUARDIANS_API.md).
  STUDENT_IMPORT_TOO_MANY_ROWS(422),
  // A per-row code: the same admission number appears twice in the uploaded file. Neither row
  // is enrolled, because the platform cannot tell which one the office meant (BR-STU-003).
  STUDENT_IMPORT_DUPLICATE_ROW(422),

  // --- Fleet (MOD-05) -------------------------------------------------------------------
  VEHICLE_REGISTRATION_EXISTS(409),
  VEHICLE_NOT_ACTIVE(422),
  VEHICLE_NOT_FOUND(404),
  VEHICLE_DOCUMENT_NOT_FOUND(404),
  // BR-FLEET-002: a mandatory document (insurance, fitness, permit) has expired. Named
  // separately from VEHICLE_NOT_ACTIVE because the two send the driver to different people.
  VEHICLE_DOCUMENT_EXPIRED(422),
  VEHICLE_CAPACITY_EXCEEDED(422),
  // BR-FLEET-004: two devices reporting for one bus would produce contradictory positions.
  DEVICE_ALREADY_ASSIGNED(409),
  DEVICE_NOT_REGISTERED(404),

  // --- Transport Staff (MOD-06) -----------------------------------------------------------
  STAFF_NOT_FOUND(404),
  STAFF_EMPLOYEE_CODE_EXISTS(409),
  // BR-STAFF-007 / ADR-0019: a discard was refused because the staff member's account has signed
  // in, or something besides their own credentials and duties references the record. Deactivate.
  STAFF_HAS_SAFETY_RECORDS(422),
  // BR-STAFF-001/002 🔴 — the four ways a crew member can be unfit to run today. Four codes,
  // not one: a driver refused at 06:30 with a generic refusal cannot act, while one told their
  // licence expired can call the office and get a replacement (ERROR_CATALOG.md §Fleet & Staff).
  STAFF_LICENCE_EXPIRED(422),
  STAFF_LICENCE_CLASS_INVALID(422),
  STAFF_NOT_VERIFIED(422),
  STAFF_VERIFICATION_LAPSED(422),
  // BR-STAFF-004: already crewed on a trip that is running right now.
  STAFF_ALREADY_ON_ACTIVE_TRIP(409),
  // BR-STAFF-005: tenant configuration requires an attendant on this run and none is assigned.
  ATTENDANT_REQUIRED(422),

  // --- Routes (MOD-07) ---------------------------------------------------------------------
  ROUTE_CODE_ALREADY_EXISTS(409),
  ROUTE_NOT_FOUND(404),
  ROUTE_MINIMUM_STOPS_REQUIRED(422),
  ROUTE_GEOFENCE_OUT_OF_BOUNDS(422),
  ROUTE_STOP_TIMES_NOT_INCREASING(422),
  // A stop id in a PUT /routes/{id}/stops list that is not one of that route's current stops —
  // a stale editor, or an id from another route.
  ROUTE_STOP_NOT_FOUND(404),
  // BR-ROUTE-009: a stop cannot be removed while students are assigned to it.
  ROUTE_STOP_HAS_ASSIGNED_STUDENTS(422),
  // BR-ROUTE-004: at most one active pickup and one active drop per student. The DB's
  // uq_rsa_student_direction is the guarantee; this names the conflict for the client.
  STUDENT_ALREADY_ASSIGNED_FOR_DIRECTION(409),

  // --- Trip execution (MOD-08) --------------------------------------------------------------
  //
  // Names and statuses follow ERROR_CATALOG.md §Trips exactly. An earlier pass of this module
  // invented its own (TRIP_INVALID_TRANSITION, TRIP_VEHICLE_NOT_ELIGIBLE, …), which the driver
  // app could not have recognised — its ErrorCode enum was already written to the catalogue.
  TRIP_NOT_FOUND(404),
  // BR-TRIP-002: the requested transition is not one this status allows — starting a trip that
  // is already running, closing one that never completed. 409, because the request is valid and
  // the resource's state is what refuses it. The detail names the current status and what it may
  // become, since "invalid transition" alone tells a crew nothing.
  TRIP_INVALID_STATUS_TRANSITION(409),
  // BR-TRIP-005: that bus is already out on another run.
  TRIP_VEHICLE_ON_ANOTHER_TRIP(409),
  // BR-TRIP-006: the caller is neither rostered crew for this route nor a transport manager.
  // Distinct from a permission denial: they hold PERM-TRIP-START, just not for this run.
  TRIP_NOT_AUTHORISED_ACTOR(403),
  // BR-TRIP-003: a trip whose route has no assigned students, or all of them absent, would
  // start with an empty manifest and record nothing. Not in the catalogue before MOD-08 — the
  // condition only became reachable once trips were generated ahead of their students.
  TRIP_MANIFEST_EMPTY(422),
  // BR-TRIP-007: cancelling requires a reason — an unexplained cancelled run is a safety gap
  // nobody can account for afterwards.
  TRIP_CANCELLATION_REASON_REQUIRED(422),

  // --- Absence ----------------------------------------------------------------------------
  // The manifest is already materialised and immutable; a change after this point is a
  // manifest amendment by staff, not a parent's declaration (BR-ABS-003).
  ABSENCE_TRIP_ALREADY_STARTED(422),

  // --- System -------------------------------------------------------------------------
  RATE_LIMIT_EXCEEDED(429),
  TENANT_CONTEXT_MISSING(500),
  INTERNAL_ERROR(500);

  private final int httpStatus;

  ErrorCode(int httpStatus) {
    this.httpStatus = httpStatus;
  }

  public int httpStatus() {
    return httpStatus;
  }

  /**
   * The localisation key for this code — {@code error.auth.credentials_invalid}.
   *
   * <p>Clients display from this, never from a server-supplied message (BR-CFG-005).
   */
  public String messageKey() {
    return "error." + name().toLowerCase(java.util.Locale.ROOT);
  }
}
