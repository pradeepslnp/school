# ADR-0019: Discarding mistaken entries and correcting sign-in phone numbers

**Status:** Accepted
**Date:** 2026-09-16
**Affects:** [`BUSINESS_RULES.md`](../../01-product-discovery/BUSINESS_RULES.md) BR-STU-005, BR-STU-007, BR-STAFF-007, BR-IAM-014; [`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md) `PERM-STUDENT-DELETE`, `PERM-STAFF-VIEW`, `PERM-STAFF-DELETE`; [`API_STANDARDS.md`](../../04-api/API_STANDARDS.md) §Methods; [`STUDENTS_GUARDIANS_API.md`](../../04-api/STUDENTS_GUARDIANS_API.md); [`FLEET_STAFF_ROUTES_API.md`](../../04-api/FLEET_STAFF_ROUTES_API.md); [`CONVENTIONS.md`](../../03-database/CONVENTIONS.md) §Soft delete; `V20__discard_and_staff_view.sql`; `com.guardian.student`, `com.guardian.staff`, `com.guardian.guardian`, `com.guardian.identity`

## Context

School offices make data-entry mistakes, and the platform has no way to undo two kinds of them.

1. **A record that should never have existed.** A duplicate student, or one entered with the wrong admission number (which cannot be edited, because safety records cite it), or a driver entered by mistake. Today such a record can only be withdrawn (BR-STU-005) or deactivated (BR-IAM-008). Either way it stays in the register permanently. For a child who was never enrolled, that keeps personal data the platform has no reason to hold ([`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §7).
2. **A wrong phone number.** Guardians, drivers and attendants sign in by phone OTP against `users.phone`. The phone on a `transport_staff` or `guardians` record is a separate copy, and nothing keeps the two in step.
   - Correcting a driver's phone on the Drivers screen changes only the roster copy, so the OTP still goes to the wrong number.
   - A guardian's phone cannot be corrected at all.
   - Sign-in accounts are matched by number (BR-IAM-010). A wrong number that belongs to someone else attaches the role to *their* account, so a stranger's phone can hold a driver's or a parent's access to a child.

The constraints:

- **Safety history must never be erased.** Boarding, handover, absence, notification, custody and trip records are the evidence of what happened to a child (BR-AUD-001, BR-BOARD-001, [`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §4).
- **`API_STANDARDS.md` says `DELETE` never hard-deletes.** The console's `RestClient` retries `DELETE`, and a retried destructive request must not repeat.
- **Module dependencies.** The student module sits below the guardian and routes modules that hold a student's setup rows (MODULE_MAP rule 3).

## Decision

**1. Two operations, not one "delete".** A wrong phone number is *corrected*: the record stays. A record that should not exist is *discarded*: it is permanently removed. Discarding is never offered as a way to fix a detail that an edit can fix.

**2. Discard is a named action, not a `DELETE`.**
- The endpoints are `POST /students/{id}/discard` and `POST /transport-staff/{id}/discard`. Each needs a `reason` (1–500 characters).
- `DELETE` keeps its platform-wide meaning (soft). `POST` is not retried by clients without an idempotency key, so a discard is sent once.
- The console labels the action "Delete entry".

**3. "Safety history" is whatever the database still references.**
- Every table that references a student or a staff member declares `ON DELETE RESTRICT` ([`CONVENTIONS.md`](../../03-database/CONVENTIONS.md)).
- A discard first removes, in the same transaction, only the record's own setup rows:
  - for a student: guardian links, route assignments and boarding credentials
  - for a staff member: credential documents and duty assignments
- It then deletes the record. If any other row still references it, the database refuses the delete. The refusal becomes `422 STUDENT_HAS_SAFETY_RECORDS` or `422 STAFF_HAS_SAFETY_RECORDS`, and the whole transaction rolls back.
  - For a student, those rows are a boarding event, manifest, absence, notification, handover code, custody restriction or pickup nomination.
  - For a staff member, those rows are trip staffing, once built.
- A table added later is covered by its own foreign key, with no list in code to keep current.
- `audit_records` and `data_access_records` deliberately have no foreign keys to their subjects. They survive the discard and keep pointing at the removed id.
- A staff member has one further condition. **If their sign-in account has ever signed in, they are not discarded.** A driver who has used the app may have recorded events under that account.

**4. Who may discard.** Discarding is granted to `PRINCIPAL` and `SUPER_ADMIN` only:
- `PERM-STUDENT-DELETE` and `PERM-STAFF-DELETE` are new.
- `PERM-STAFF-VIEW` is also new, so that a Principal can open the Drivers screen without holding `PERM-STAFF-MANAGE`.

This is a deliberate two-person control: the school office (School Admin, Transport Manager) enters records, and the Principal removes mistakes. ORG_ADMIN and SCHOOL_ADMIN do not receive the delete permissions, unlike every other write in the matrix. A school-scoped caller may only discard a record in a school they are scoped to; anything else answers `404`.

**5. Correcting a phone moves the sign-in; it never edits the old account.** When the phone on a staff or guardian record changes:
1. The new number is provisioned exactly as a new record's would be: the existing account for that number is reused (BR-IAM-010), or a new one is created. The role is granted to it.
2. The record is relinked to that account.
3. The old account is released.

Rewriting `users.phone` in place was rejected (see below): anything the wrong-number holder did under that account would become attributed to the real person.

**6. Sign-in accounts are released, never deleted.**
- Releasing an account removes the one role, revokes every session the account holds immediately, and marks the account `INACTIVE` if no role remains.
- The account row stays, so nothing it recorded or received (notifications cascade from `users`) is lost.
- If the same number is later given a role again, an account that is `INACTIVE` and holds no role is reactivated and renamed rather than refused. Possession of the number is what OTP sign-in proves, so the number's holder is the right owner.
- A discarded staff member's account is released the same way.

**7. Cross-module work goes through ports**, following `StaffSessionRevocationPort`:
- The student module declares a port for releasing its setup rows. `guardian-api` implements it with the guardian and routes modules' own repositories.
- Staff and guardian reach identity downward through ports for provisioning, activity and release.
- No module reads another module's tables.

**8. Guardian records are not deleted with a student.** They may belong to a sibling, and they are reused if the child is entered again correctly.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Keep soft delete only (withdraw / deactivate) | Leaves duplicates and mistaken children in the register permanently, with no path to correct an admission number. Holds personal data with no purpose. |
| Hard delete with `DELETE /students/{id}` | Changes what `DELETE` means across the API, and the console retries `DELETE`. A named action keeps both invariants. |
| Enumerate "safety tables" in code and check each before deleting | Needs the student module to read tables owned by modules above it. The list silently goes stale when a new safety table is added. The foreign keys already are the authoritative list. |
| Edit `users.phone` in place | Misattributes anything the wrong-number holder did. Collides with `uq_users_tenant_phone` when the corrected number already has an account. |
| Delete the sign-in account when no role remains | `notifications.user_id` cascades, which would erase the record of what a phone was told about a child. It would also need `DELETE` on `users`. |
| Give delete to ORG_ADMIN and SCHOOL_ADMIN as well | Chosen against by the product owner. The person who made the mistake should not be the one who erases it. |

## Consequences

**Positive**
- A mistaken record can be removed, but a record with any safety history cannot. The database enforces that, not application code alone.
- Correcting a wrong number immediately cuts off the phone that should never have had access: role removed, sessions revoked.
- Every discard and release is audited with its reason. The deletion record keeps identifiers (admission number, employee code, school), never names or phone numbers (BR-AUD-006).

**Negative / accepted cost**
- **Recovery is harder.** A discarded record can be recovered only from a point-in-time restore ([`BACKUP_AND_DR.md`](../../08-deployment/BACKUP_AND_DR.md)).
- **Wider grants.** `guardian_app` now holds `DELETE` on `students`, `student_credentials`, `guardian_student_links` and `route_student_assignments`. The `RESTRICT` foreign keys on every safety table are what keep that safe.
- **Old accounts keep data.** A released account keeps the mistaken name and number in `users`, inactive and without a role.
- **Orphaned guardians.** A guardian left with no child after a discard keeps their account. Their app shows no children.
- **Principal's role changes.** It is no longer purely "read and reporting".

**Neutral**
- `PERM-STAFF-VIEW` separates reading the staff register from managing it; `PERM-STAFF-MANAGE` holders also hold it.

## Reversal Cost

**Low.** Removing the two endpoints and three permissions restores the previous behaviour. The grants can be revoked in a migration. Records already discarded stay discarded.

**Reconsider if:**
- a regulator requires an erasure path for records that *do* have history, which is a different decision with retention obligations (BR-AUD-007)
- tenants report that the Principal-only control does not fit how schools staff their offices

## Verification

- `SystemRolePermissionsDocConsistencyTest` and `EndpointPermissionTest` hold the three permissions to this matrix.
- `BusinessRuleTraceabilityTest` requires BR-STU-007, BR-STAFF-007 and BR-IAM-014 to be cited by `@BusinessRule`.
- Manual: discarding a student with boarding history returns `422` and changes no row.
- Manual: discarding a fresh mistaken student removes it, its links and its assignments, and writes `STUDENT_DISCARDED`.
- Manual: correcting a driver's phone leaves the old account `INACTIVE` with its sessions revoked.
