# ERROR CATALOG

**Document tier:** 4 — API
**Status:** Active

Every error code the API returns. **A code not listed here cannot be returned** — verified in CI.

Envelope format: [`API_STANDARDS.md`](API_STANDARDS.md).

---

## Conventions

- `code` is `SCREAMING_SNAKE_CASE`, stable, and never reused for a different meaning.
- `messageKey` is the localisation key (BR-CFG-005). Clients display from this, never from `message`.
- `businessRule` is set whenever a business rule caused the refusal — always on `422`.
- Error messages never leak internal detail: no stack traces, no SQL, no internal identifiers.

---

## Authentication & Authorization

| Code | HTTP | Rule | Meaning |
|---|---|---|---|
| `AUTH_CREDENTIALS_INVALID` | 401 | BR-IAM-001 | Wrong identifier or secret. Deliberately does not distinguish which. |
| `AUTH_TOKEN_MISSING` | 401 | | No `Authorization` header |
| `AUTH_TOKEN_EXPIRED` | 401 | ADR-0006 | Access token expired — refresh |
| `AUTH_TOKEN_INVALID` | 401 | | Malformed or bad signature |
| `AUTH_SESSION_REVOKED` | 401 | BR-IAM-007 | Session revoked |
| `AUTH_REFRESH_REUSE_DETECTED` | 401 | BR-IAM-009 | **Token family revoked, security alert raised** |
| `AUTH_ACCOUNT_LOCKED` | 401 | BR-IAM-011 | Too many failed attempts |
| `AUTH_OTP_EXPIRED` | 401 | | OTP no longer valid |
| `AUTH_OTP_ALREADY_USED` | 401 | | OTP is single-use |
| `AUTH_PERMISSION_DENIED` | 403 | BR-IAM-002 | Permission not held |
| `AUTH_SCOPE_DENIED` | 403 | BR-IAM-005, BR-IAM-006 | Permission held, resource out of scope |
| `AUTH_TENANT_MISMATCH` | 404 | BR-TEN-004 | Cross-tenant — returns `404`, the resource is invisible |
| `AUTH_JUSTIFICATION_REQUIRED` | 403 | BR-TEN-004 | Platform elevation without justification |

`AUTH_CREDENTIALS_INVALID` covers both unknown identifier and wrong secret, deliberately — distinguishing them enumerates valid accounts.

---

## Validation

| Code | HTTP | Meaning |
|---|---|---|
| `VALIDATION_FAILED` | 400 | One or more fields invalid; see `details[]` |
| `VALIDATION_REQUIRED_FIELD_MISSING` | 400 | |
| `VALIDATION_INVALID_FORMAT` | 400 | Includes phone format per region profile (ADR-0007) |
| `VALIDATION_VALUE_OUT_OF_RANGE` | 400 | |
| `VALIDATION_INVALID_SORT_FIELD` | 400 | Undocumented sort field — never an unindexed scan |
| `VALIDATION_INVALID_CURSOR` | 400 | Malformed pagination cursor |
| `REQUEST_PAYLOAD_TOO_LARGE` | 400 | |

---

## Tenancy

| Code | HTTP | Rule |
|---|---|---|
| `ORG_CODE_ALREADY_EXISTS` | 409 | BR-TEN-007 |
| `ORG_SUSPENDED` | 403 | BR-TEN-006 |
| `ORG_LAST_SCHOOL_CANNOT_BE_REMOVED` | 422 | BR-TEN-002 |
| `SCHOOL_CODE_ALREADY_EXISTS` | 409 | BR-TEN-007 |
| `SCHOOL_CANNOT_CHANGE_ORGANIZATION` | 422 | BR-TEN-003 |

---

## Students & Guardians

| Code | HTTP | Rule | Meaning |
|---|---|---|---|
| `STUDENT_ADMISSION_NO_EXISTS` | 409 | BR-STU-003 | |
| `STUDENT_NOT_ACTIVE` | 422 | BR-STU-004 | Inactive students cannot be assigned or boarded |
| `STUDENT_HAS_NO_ACTIVE_GUARDIAN` | 422 | BR-STU-002 | Blocks route assignment |
| `STUDENT_HAS_SAFETY_RECORDS` | 422 | BR-STU-005 | Cannot hard-delete |
| `GUARDIAN_HANDOVER_RIGHT_REQUIRED` | 422 | BR-GRD-002 | **At least one guardian must hold it** |
| `GUARDIAN_LINK_ALREADY_EXISTS` | 409 | | |
| `GUARDIAN_NOT_AUTHORISED_TO_NOMINATE` | 403 | BR-GRD-006 | Lacks `can_authorise_handover` |
| `PICKUP_PERSON_OUTSIDE_VALIDITY` | 422 | BR-GRD-005 | Nomination expired or not yet valid |
| `PICKUP_PERSON_REVOKED` | 422 | BR-GRD-007 | |
| `CUSTODY_RESTRICTION_ACTIVE` | 403 | BR-GRD-008 🔴 | **Blocks handover and visibility** |
| `GUARDIAN_NOT_AUTHORISED_FOR_HANDOVER` | 403 | BR-GRD-006 | Lacks `can_authorise_handover`; cannot request a release code |

---

## Fleet & Staff

| Code | HTTP | Rule |
|---|---|---|
| `VEHICLE_REGISTRATION_EXISTS` | 409 | BR-FLEET-001 |
| `VEHICLE_NOT_FOUND` | 404 | | Not found, or not visible to the caller at all |
| `VEHICLE_DOCUMENT_NOT_FOUND` | 404 | | |
| `VEHICLE_DOCUMENT_EXPIRED` | 422 | BR-FLEET-002 🔴 |
| `VEHICLE_CAPACITY_EXCEEDED` | 422 | BR-FLEET-005 |
| `VEHICLE_NOT_ACTIVE` | 422 | BR-FLEET-001 |
| `DEVICE_ALREADY_ASSIGNED` | 409 | BR-FLEET-004 |
| `DEVICE_NOT_REGISTERED` | 404 | BR-FLEET-006 | Also returned when the referenced device ID does not exist |
| `STAFF_NOT_FOUND` | 404 | | Not found, or not visible to the caller at all |
| `STAFF_EMPLOYEE_CODE_EXISTS` | 409 | | Data-integrity constraint (`uq_staff_school_employee_code`), not a documented BR — same treatment as a vehicle's registration number |
| `STAFF_LICENCE_EXPIRED` | 422 | BR-STAFF-001 🔴 |
| `STAFF_LICENCE_CLASS_INVALID` | 422 | BR-STAFF-001 🔴 |
| `STAFF_NOT_VERIFIED` | 422 | BR-STAFF-002 🔴 |
| `STAFF_VERIFICATION_LAPSED` | 422 | BR-STAFF-002 🔴 |
| `STAFF_ALREADY_ON_ACTIVE_TRIP` | 409 | BR-STAFF-004 |
| `ROUTE_CODE_ALREADY_EXISTS` | 409 | BR-ROUTE-001 |
| `ROUTE_NOT_FOUND` | 404 | | Not found, or not visible to the caller at all |
| `ROUTE_MINIMUM_STOPS_REQUIRED` | 422 | BR-ROUTE-001 |
| `ROUTE_GEOFENCE_OUT_OF_BOUNDS` | 422 | BR-ROUTE-003 🔴 |
| `ROUTE_STOP_TIMES_NOT_INCREASING` | 422 | BR-ROUTE-008 |
| `ATTENDANT_REQUIRED` | 422 | BR-STAFF-005 |

Each of these names the exact failing check. A generic "cannot start trip" at 6:30 AM is not actionable ([`MOD-05-06-fleet-staff.md`](../03-database/tables/MOD-05-06-fleet-staff.md)).

---

## Routes

| Code | HTTP | Rule |
|---|---|---|
| `ROUTE_MINIMUM_STOPS_REQUIRED` | 422 | BR-ROUTE-001 |
| `ROUTE_STOP_TIMES_NOT_INCREASING` | 422 | BR-ROUTE-008 |
| `ROUTE_GEOFENCE_OUT_OF_BOUNDS` | 422 | BR-ROUTE-003, BR-CFG-003 🔴 |
| `ROUTE_HAS_ACTIVE_ASSIGNMENTS` | 422 | BR-ROUTE-007 |
| `STUDENT_ALREADY_ASSIGNED_FOR_DIRECTION` | 409 | BR-ROUTE-004 |

---

## Trips

| Code | HTTP | Rule | Meaning |
|---|---|---|---|
| `TRIP_ALREADY_EXISTS` | 409 | BR-TRIP-001 | Same route, date, direction |
| `TRIP_INVALID_STATUS_TRANSITION` | 409 | BR-TRIP-002 | |
| `TRIP_VEHICLE_ON_ANOTHER_TRIP` | 409 | BR-TRIP-005 | |
| `TRIP_NOT_STARTED` | 422 | BR-TRIP-002 | |
| `TRIP_ALREADY_COMPLETED` | 409 | BR-TRIP-002 | |
| `TRIP_CANCELLATION_REASON_REQUIRED` | 422 | BR-TRIP-007 | Quoted to guardians |
| `TRIP_MANIFEST_IMMUTABLE` | 422 | BR-TRIP-003 🔴 | Use an amendment instead |
| `TRIP_AMENDMENT_REASON_REQUIRED` | 422 | BR-AUD-004 | |
| `TRIP_RECONCILIATION_INCOMPLETE` | 422 | BR-TRIP-009, BR-SAFE-001 🔴 | **Cannot close with an unaccounted child** |
| `TRIP_NOT_AUTHORISED_ACTOR` | 403 | BR-TRIP-006 | |

---

## Boarding & Handover 🔴

| Code | HTTP | Rule | Meaning |
|---|---|---|---|
| `BOARDING_STUDENT_NOT_ON_MANIFEST` | 422 | BR-BOARD-003 | Override path available |
| `BOARDING_ALREADY_BOARDED` | 409 | BR-BOARD-005 | No intervening alight |
| `BOARDING_NOT_BOARDED` | 422 | BR-BOARD-006 | Cannot alight without boarding |
| `BOARDING_WRONG_STOP` | 422 | BR-BOARD-004 🔴 | Override notifies guardians |
| `BOARDING_WRONG_VEHICLE` | 422 | BR-SAFE-003 🔴 | **Student expected on another active trip** |
| `BOARDING_OVERRIDE_REASON_REQUIRED` | 422 | BR-AUD-004 | |
| `BOARDING_EVENT_IMMUTABLE` | 422 | BR-BOARD-001 🔴 | Corrections are new records |
| `BOARDING_CREDENTIAL_INVALID` | 422 | | Unknown or revoked credential |
| `HANDOVER_RECEIVER_NOT_AUTHORISED` | 403 | BR-HAND-001 🔴 | |
| `HANDOVER_VERIFICATION_FAILED` | 422 | BR-HAND-002 | |
| `HANDOVER_ALREADY_RECORDED` | 409 | BR-HAND-004 | |
| `HANDOVER_REQUIRES_ALIGHT_EVENT` | 422 | BR-HAND-004 | |
| `HANDOVER_OVERRIDE_REQUIRES_RECEIVER_IDENTITY` | 422 | BR-HAND-003 🔴 | **Must record who the child was given to** |
| `HANDOVER_REFUSED_CUSTODY_RESTRICTION` | 403 | BR-HAND-006 🔴 | Recorded and escalated |
| `RECONCILIATION_RESOLUTION_INCOMPLETE` | 422 | BR-SAFE-001 🔴 | Outcome, actor, and time all required |

`BOARDING_EVENT_IMMUTABLE` is returned on any attempt to update or delete a boarding record — the append-only guarantee surfaced to the client.

---

## Absence

| Code | HTTP | Rule |
|---|---|---|
| `ABSENCE_ALREADY_DECLARED` | 409 | BR-ABS-001 |
| `ABSENCE_TRIP_ALREADY_STARTED` | 422 | BR-ABS-003 |
| `ABSENCE_CANNOT_CANCEL_AFTER_START` | 422 | BR-ABS-004 |
| `ABSENCE_NOT_AUTHORISED` | 403 | BR-ABS-001 |

---

## Tracking, Alerts, Incidents

| Code | HTTP | Rule |
|---|---|---|
| `TRACKING_NOT_AVAILABLE_OUTSIDE_TRIP` | 422 | BR-TRACK-001 |
| `TRACKING_POSITION_IMPLAUSIBLE` | 400 | BR-TRACK-004 |
| `TRACKING_SUBSCRIPTION_DENIED` | 403 | BR-TRACK-002 |
| `ALERT_ALREADY_RESOLVED` | 409 | BR-ALERT-006 |
| `ALERT_RESOLUTION_OUTCOME_REQUIRED` | 422 | BR-ALERT-006 |
| `SOS_ALREADY_ACKNOWLEDGED` | 409 | BR-INC-001 |
| `SOS_CANNOT_BE_DELETED` | 422 | BR-INC-006 🔴 |
| `INCIDENT_RESOLUTION_REQUIRED` | 422 | BR-INC-005 |

---

## Notification & Configuration

| Code | HTTP | Rule |
|---|---|---|
| `NOTIFICATION_TEMPLATE_MISSING` | 422 | BR-NTF-002 |
| `NOTIFICATION_PREFERENCE_NOT_APPLICABLE` | 422 | BR-NTF-006 🔴 — safety-critical cannot be disabled |
| `CONFIG_VALUE_OUT_OF_BOUNDS` | 422 | BR-CFG-003 🔴 — platform floor or ceiling |
| `CONFIG_KEY_UNKNOWN` | 400 | BR-CFG-001 |
| `CONFIG_SCOPE_NOT_PERMITTED` | 422 | BR-CFG-001 |
| `CONFIG_SAFETY_CRITICAL_PERMISSION_REQUIRED` | 403 | BR-CFG-003 🔴 |

---

## System

| Code | HTTP | Meaning |
|---|---|---|
| `RATE_LIMIT_EXCEEDED` | 429 | `Retry-After` set |
| `IDEMPOTENCY_KEY_REUSED_WITH_DIFFERENT_PAYLOAD` | 409 | Same key, different body |
| `DEPENDENCY_UNAVAILABLE` | 503 | Named dependency down |
| `INTERNAL_ERROR` | 500 | Generic. `requestId` is the only detail returned. |

---

## Adding an Error

1. Add the code here with its HTTP status and business rule.
2. Add the `messageKey` to localisation resources for every supported locale (BR-CFG-005).
3. Reference it in the endpoint's API document.
4. Add a test asserting the code is returned in that condition.

A code returned by the application but absent here fails the CI check.
