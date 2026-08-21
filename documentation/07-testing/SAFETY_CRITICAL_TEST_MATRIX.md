# SAFETY-CRITICAL TEST MATRIX 🔴

**Document tier:** 7 — Testing
**Status:** Active

Every 🔴 rule from [`BUSINESS_RULES.md`](../01-product-discovery/BUSINESS_RULES.md), with the tests that prove it holds.

**Each 🔴 rule is tested at two levels** — the decision (unit) and the enforcement (integration/E2E/schema). A rule enforced only in a use case can be bypassed by a future code path. A rule enforced in the schema cannot.

This matrix runs in full on every PR touching a 🔴 rule, and nightly.

---

## Tenant Isolation

| Rule | Level | Test |
|---|---|---|
| BR-TEN-004 | Integration | Data written under tenant A returns zero rows under tenant B — **every** tenant-scoped repository |
| BR-TEN-004 | Schema | Every `tenant_id` table has RLS enabled **and forced** |
| BR-TEN-004 | Schema | Every policy declares `USING` **and** `WITH CHECK` |
| BR-TEN-004 | Schema | `guardian_app` lacks `BYPASSRLS`; owns no tables |
| BR-TEN-004 | Integration | Two sequential transactions on one pooled connection do not leak context |
| BR-TEN-004 | Integration | Unset context ⇒ zero rows, not an error |
| BR-TEN-004 | Integration | Insert bearing a foreign `tenant_id` rejected by `WITH CHECK` |
| BR-TEN-004 | Integration | Platform elevation without justification refused; audit written **before** first read |

---

## Access Control

| Rule | Level | Test |
|---|---|---|
| BR-IAM-001 | Contract | Client-supplied role/scope claims ignored |
| BR-IAM-002 | Architecture | Every endpoint declares a permission — build fails otherwise |
| BR-IAM-002 | Contract | Every denied cell in the permission matrix returns `403` |
| BR-IAM-005 | Integration | Guardian requesting another family's student receives `403` |
| BR-IAM-012 | Integration | Every non-guardian child-data read writes a data-access record |

---

## Guardians & Handover

| Rule | Level | Test |
|---|---|---|
| BR-GRD-002 | Unit | Removing the last handover-capable guardian is refused |
| BR-GRD-002 | Integration | Route assignment refused when no guardian holds the right |
| BR-GRD-006 | Integration | Guardian without the right cannot nominate a pickup person |
| BR-GRD-008 | Unit | Custody restriction overrides an active guardian link |
| BR-GRD-008 | E2E | Restricted guardian cannot read the student's location |
| BR-HAND-001 | Unit | Release to an unauthorised adult refused |
| BR-HAND-001 | Schema | Handover with zero or two receiver paths rejected by constraint |
| BR-HAND-001 | Integration | Handover verification cannot be disabled by configuration |
| BR-HAND-003 | Schema | Override without reason or receiver identity rejected by constraint |
| BR-HAND-003 | E2E | Override notifies **all** guardians and the transport manager |
| BR-HAND-006 | E2E | Restricted collection refused, `HANDOVER_REFUSED` incident raised, escalated, **no handover row created** |
| BR-HAND-007 | E2E | No receiver ⇒ student stays on vehicle, incident raised, escalation starts |
| BR-HAND-007 | UI | The no-receiver screen offers no path that discharges the child |

`BR-HAND-007` is the rule most likely to be argued away for operational convenience. Both the API and the UI are tested for the absence of an escape hatch.

---

## Boarding

| Rule | Level | Test |
|---|---|---|
| BR-BOARD-001 | Schema | `UPDATE`/`DELETE` on `boarding_events` raises an exception |
| BR-BOARD-001 | Integration | Correction creates a new record; both remain readable |
| BR-BOARD-004 | E2E | Wrong-stop alight requires override and notifies guardians |
| BR-BOARD-009 | Schema | Duplicate `client_event_id` rejected |
| BR-BOARD-009 | Integration | Replayed submission returns the original record, not a duplicate |

---

## Safety Controls

| Rule | Level | Test |
|---|---|---|
| **BR-SAFE-001** | Unit | Boarded with no alight ⇒ `UNACCOUNTED` |
| **BR-SAFE-001** | Integration | Trip cannot reach `CLOSED` with an unresolved item |
| **BR-SAFE-001** | Schema | Resolution without outcome, actor, **and** time rejected |
| **BR-SAFE-001** | E2E | Critical alert reaches driver, attendant, manager, guardians within the detection window |
| **BR-SAFE-001** | E2E | Alert bypasses preferences and quiet hours |
| BR-SAFE-002 | E2E | Departure with un-boarded student ⇒ no-show recorded, guardians notified |
| BR-SAFE-003 | E2E | Student scanned onto the wrong trip ⇒ both crews and guardians alerted |
| BR-SAFE-004 | Integration | SOS delivered with every preference disabled and quiet hours active |
| BR-SAFE-005 | Integration | Offline event conflicting with server state is **flagged, not discarded** |
| BR-SAFE-006 | Integration | Unacknowledged alert escalates a level, repeatedly, until acknowledged |
| BR-SAFE-007 | Integration | Configuration below the platform floor rejected |

**BR-SAFE-001 carries five tests.** It is the control the platform exists for — a child asleep on a parked vehicle.

---

## Trips & Manifest

| Rule | Level | Test |
|---|---|---|
| BR-TRIP-003 | Integration | Route edits after start do not change the materialised manifest |
| BR-TRIP-003 | Integration | Direct manifest edit refused; amendment required |
| BR-TRIP-003 | Schema | Amendment without reason rejected |
| BR-FLEET-002 | Integration | Expired mandatory document blocks trip start |
| BR-FLEET-002 | E2E | Expiry mid-trip does **not** interrupt the in-progress trip |
| BR-STAFF-001 | Integration | Expired or wrong-class licence blocks assignment |
| BR-STAFF-002 | Integration | Lapsed verification blocks assignment |

---

## Notification

| Rule | Level | Test |
|---|---|---|
| BR-NTF-006 | Integration | `CRITICAL` dispatches with preferences off and quiet hours active |
| BR-NTF-006 | Integration | Primary-channel failure escalates to fallback; both attempts recorded |
| BR-NTF-007 | Unit | Multi-recipient templates cannot interpolate a student name |
| BR-NTF-007 | E2E | Trip-wide incident notification names no child |

---

## Audit

| Rule | Level | Test |
|---|---|---|
| BR-AUD-001 | Schema | `UPDATE`/`DELETE` on `audit_records` raises an exception |
| BR-AUD-001 | Schema | `guardian_app` holds no `UPDATE`/`DELETE` grant on audit tables |
| BR-AUD-002 | Integration | **Failing audit write rolls back the business change** |
| BR-AUD-004 | Schema | Override without a reason rejected by constraint |
| BR-RPT-002 | Integration | Every export writes an audit record including record count |

`BR-AUD-002` is tested by deliberately failing the audit write and asserting the boarding event does not exist afterwards. The platform refuses an operation rather than performing it unrecorded.

---

## Configuration Floors

| Rule | Level | Test |
|---|---|---|
| BR-CFG-003 | Integration | Value outside min/max rejected on write |
| BR-CFG-003 | Integration | Safety-critical change without `PERM-CONFIG-SAFETY-EDIT` refused |
| BR-CFG-003 | Integration | Handover verification methods cannot be set to empty |
| BR-ROUTE-003 | Schema | Geofence radius outside 20–500 m rejected |

The empty-verification-methods test is the concrete expression of *Child Safety First outranks Configuration over Hardcoding* ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md)).

---

## Failure-Mode Tests

Safety controls must survive the failures that make them most necessary.

| Failure | Expected |
|---|---|
| Redis down | Live tracking degrades; **boarding and handover unaffected**; no data lost |
| Notification provider down | Retry, then fallback for `CRITICAL`; failures recorded and visible |
| All providers down | `CRITICAL` escalates to a human at the school; never silently dropped |
| Network lost on vehicle | Full trip recorded locally; syncs exactly once on reconnect |
| App killed mid-trip | Queue survives restart; no events lost |
| Database unavailable | Platform unavailable; **driver app continues recording offline** |
| Device clock wrong by hours | Skew measured and stored; record accepted and flagged |
| Position ingestion down | Positions lost for the outage; **boarding unaffected** |

The consistent property: **the failure that takes down everything else still does not stop a child's boarding from being recorded.**

---

## Execution

| When | Scope |
|---|---|
| PR touching a 🔴 rule | Full matrix |
| Nightly | Full matrix |
| Before release | Full matrix + load + accessibility |

**A failure here blocks release.** No exceptions, no waivers, no "fix forward" — these tests exist because their failure modes harm children.

Adding a 🔴 rule requires adding rows here in the same PR. The traceability check fails otherwise.
