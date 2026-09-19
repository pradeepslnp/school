# MOD-03 / MOD-04 — Students & Guardians Tables

**Owning modules:** `com.guardian.student`, `com.guardian.guardian` · **Rules:** BR-STU-*, BR-GRD-*

These tables answer the platform's most consequential question: **may this adult collect this child?**

---

## `students`

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools` |
| `branch_id` | `UUID` | → `branches`. Null = school-wide (BR-TEN-005) |
| `student_class_id` | `UUID` | → `student_classes` |
| `admission_no` | `VARCHAR(64)` | `NOT NULL`, unique within school |
| `first_name`, `last_name` | `VARCHAR(128)` | `NOT NULL` |
| `date_of_birth` | `DATE` | Drives self-release eligibility (BR-HAND-005) |
| `photo_ref` | `VARCHAR(255)` | Storage reference, not a URL — served through an authorising endpoint |
| `enrolment_status` | `VARCHAR(24)` | `NOT NULL`, `ACTIVE` / `INACTIVE` / `WITHDRAWN` / `TRANSFERRED` |
| `transport_eligible` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_students_admission UNIQUE (tenant_id, school_id, admission_no),
CONSTRAINT ck_students_enrolment CHECK (
    enrolment_status IN ('ACTIVE','INACTIVE','WITHDRAWN','TRANSFERRED'))
```

**`photo_ref` is a storage key, never a public URL.** A guessable photo URL for a child is a safety problem, so images are served through an endpoint that checks permission and scope ([`SECURITY_ARCHITECTURE.md`](../../02-system-design/SECURITY_ARCHITECTURE.md)).

Students are **never hard-deleted** while a safety record references them (BR-STU-005); withdrawal sets `enrolment_status` and removes future route assignments.

A student **entered by mistake** is discarded (BR-STU-007, ADR-0019): its `guardian_student_links`, `route_student_assignments`, and `student_credentials` are deleted, then the row itself, in one transaction. Every other table referencing `students` is `ON DELETE RESTRICT`, so any safety history makes the delete fail and the transaction roll back. `guardian_app` holds `DELETE` on exactly those four tables for this purpose (V20). `guardians` rows are kept.

**Indexes:** `idx_students_tenant_school (tenant_id, school_id) WHERE enrolment_status = 'ACTIVE'`, `uq_students_admission`

**Rules:** BR-STU-001, BR-STU-003, BR-STU-004, BR-STU-005

---

## `student_classes`

| Column | Type |
|---|---|
| `school_id` | `UUID NOT NULL` → `schools` |
| `grade`, `section` | `VARCHAR(32) NOT NULL` |
| `academic_year` | `VARCHAR(16) NOT NULL` |

Unique `(tenant_id, school_id, academic_year, grade, section)`.

---

## `student_credentials`

Boarding credential — QR or card (STU-007).

| Column | Type | Notes |
|---|---|---|
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `credential_type` | `VARCHAR(24)` | `NOT NULL`, `QR` / `NFC_CARD` / `BARCODE` |
| `credential_hash` | `VARCHAR(255)` | `NOT NULL` **UNIQUE** — hashed, never stored raw |
| `issued_at` | `TIMESTAMPTZ` | `NOT NULL` |
| `revoked_at` | `TIMESTAMPTZ` | |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

**Hashed, like a password.** A leaked credential table would let anyone forge a boarding scan. Lookup is by hash on scan.

**Indexes:** `uq_student_credentials_hash (credential_hash)`, `idx_student_credentials_student (tenant_id, student_id) WHERE is_active`

---

## `guardians`

| Column | Type | Notes |
|---|---|---|
| `user_id` | `UUID` | → `users`. Null until the guardian activates their account. |
| `first_name`, `last_name` | `VARCHAR(128)` | `NOT NULL` |
| `phone` | `VARCHAR(32)` | `NOT NULL` — the primary channel ([`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §6) |
| `email` | `VARCHAR(255)` | |
| `photo_ref` | `VARCHAR(255)` | For handover visual verification |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

`user_id` is nullable because a guardian exists as a *record* — receiving SMS and being authorised for handover — before ever installing the app. Requiring an account first would exclude exactly the parents the platform must reach.

---

## `guardian_student_links` 🔴

**The authorisation table for child collection.** Rights are explicit columns, never inferred (BR-GRD-001).

| Column | Type | Notes |
|---|---|---|
| `guardian_id` | `UUID` | `NOT NULL` → `guardians` |
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `relationship_type` | `VARCHAR(32)` | `NOT NULL` — **descriptive only** |
| `can_view` | `BOOLEAN` | `NOT NULL DEFAULT true` |
| `can_receive_notifications` | `BOOLEAN` | `NOT NULL DEFAULT true` |
| `can_authorise_handover` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `can_declare_absence` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `is_primary` | `BOOLEAN` | `NOT NULL DEFAULT false` |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT uq_guardian_student UNIQUE (tenant_id, guardian_id, student_id)
```

### Why rights are columns, not inferred from `relationship_type`

`relationship_type` records *"mother"*, *"father"*, *"uncle"*. It does **not** determine authority. Custody arrangements exist; a parent may be legally barred from collection (BR-GRD-008). Inferring "father ⇒ may collect" would encode an assumption that is wrong in exactly the cases where being wrong is most harmful.

**`can_authorise_handover` defaults to `false`.** Rights are granted deliberately, never by default. BR-GRD-002 requires at least one guardian per student to hold it — enforced by the application at link creation and route assignment, since PostgreSQL cannot express a cross-row minimum as a constraint. **This is a documented deviation from "enforce structurally"**, and is covered by a dedicated test.

**Indexes:** `idx_gsl_guardian (tenant_id, guardian_id) WHERE is_active`, `idx_gsl_student (tenant_id, student_id) WHERE is_active`, `idx_gsl_handover (tenant_id, student_id) WHERE is_active AND can_authorise_handover`

**Rules:** BR-GRD-001 🔴, BR-GRD-002 🔴, BR-GRD-003, BR-GRD-004, BR-IAM-005

---

## `authorised_pickup_persons`

An adult who may collect a child but is not a guardian (BR-GRD-005).

| Column | Type | Notes |
|---|---|---|
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `nominated_by_guardian_id` | `UUID` | `NOT NULL` → `guardians` |
| `full_name` | `VARCHAR(255)` | `NOT NULL` |
| `phone` | `VARCHAR(32)` | `NOT NULL` |
| `relationship_note` | `VARCHAR(255)` | |
| `photo_ref` | `VARCHAR(255)` | |
| `valid_from`, `valid_until` | `TIMESTAMPTZ` | `NOT NULL` — **always time-bounded** |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |
| `revoked_at`, `revoked_by` | | Immediate effect (BR-GRD-007) |

```sql
CONSTRAINT ck_app_validity CHECK (valid_until > valid_from)
```

**`valid_until` is `NOT NULL`** — nominations always expire. A permanent nomination made once and forgotten is a standing authorisation nobody reviews. Extending is an explicit act.

Nomination requires the nominating guardian to hold `can_authorise_handover` (BR-GRD-006) and is audited; all guardians with that right are notified (NTF-ADM-04).

**Indexes:** `idx_app_student_valid (tenant_id, student_id, valid_from, valid_until) WHERE is_active`

---

## `custody_restrictions` 🔴

Overrides everything above (BR-GRD-008, BR-HAND-006).

| Column | Type | Notes |
|---|---|---|
| `student_id` | `UUID` | `NOT NULL` → `students` |
| `restricted_guardian_id` | `UUID` | → `guardians` |
| `restricted_person_name` | `VARCHAR(255)` | For a non-guardian |
| `restriction_type` | `VARCHAR(32)` | `NOT NULL`, `NO_HANDOVER` / `NO_VISIBILITY` / `FULL` |
| `reason` | `TEXT` | `NOT NULL` |
| `effective_from`, `effective_until` | `TIMESTAMPTZ` | |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT true` |

```sql
CONSTRAINT ck_custody_subject CHECK (
    restricted_guardian_id IS NOT NULL OR restricted_person_name IS NOT NULL),
CONSTRAINT ck_custody_type CHECK (restriction_type IN ('NO_HANDOVER','NO_VISIBILITY','FULL'))
```

**Evaluated before any handover and before any visibility check** — a restriction beats an active guardian link with `can_authorise_handover = true`. An attempted collection by a restricted person is refused, recorded, and escalated (NTF-HAND-04). It creates no `handovers` row; the trace lives in `incidents` and `audit_records`.

Managed only by `PERM-CUSTODY-RESTRICTION-MANAGE`. Every change is audited.

**Indexes:** `idx_custody_student (tenant_id, student_id) WHERE is_active`

---

## `student_import_jobs` (V17)

One row per bulk upload (STU-002, screen A-12). Append-only — written once when the file has
finished processing, never updated.

| Column | Type | Notes |
|---|---|---|
| `school_id` | `UUID` | `NOT NULL` → `schools`. Every row of the file enrols here (BR-STU-001) |
| `uploaded_by` | `UUID` | `NOT NULL`, no FK — the operator, kept readable after deactivation |
| `uploaded_role` | `VARCHAR(64)` | `NOT NULL`, the role held at upload time |
| `file_name` | `VARCHAR(255)` | `NOT NULL`, a label shown back to the operator, never a path |
| `status` | `VARCHAR(24)` | `NOT NULL`, `COMPLETED` / `FAILED` — `FAILED` reserved for a future async pipeline |
| `total_rows`, `success_count`, `error_count` | `INTEGER` | `NOT NULL DEFAULT 0` |
| `created_at`, `completed_at` | `TIMESTAMPTZ` | |

```sql
CONSTRAINT ck_student_import_jobs_status CHECK (status IN ('COMPLETED','FAILED')),
CONSTRAINT ck_student_import_jobs_counts CHECK (
    total_rows >= 0 AND success_count >= 0 AND error_count >= 0
    AND success_count + error_count <= total_rows)
```

**Indexes:** `idx_student_import_jobs_school (tenant_id, school_id, created_at DESC)`

**Grants:** `SELECT, INSERT` only — no update, no delete.

---

## `student_import_row_errors` (V17)

One row per line of an upload that could not be enrolled. Append-only, written with its job.

| Column | Type | Notes |
|---|---|---|
| `job_id` | `UUID` | `NOT NULL` → `student_import_jobs` |
| `row_number` | `INTEGER` | `NOT NULL`, the spreadsheet line (header is 1, first student is 2) |
| `field` | `VARCHAR(64)` | The offending column, or null when the whole line is malformed |
| `error_code` | `VARCHAR(64)` | `NOT NULL`, a value from [`ERROR_CATALOG.md`](../../04-api/ERROR_CATALOG.md) |
| `message` | `VARCHAR(500)` | `NOT NULL`, fallback text in the tenant's default locale |
| `created_at` | `TIMESTAMPTZ` | |

**Indexes:** `idx_student_import_row_errors_job (tenant_id, job_id, row_number)`

**Grants:** `SELECT, INSERT` only.

The downloadable error report (`GET /students/import/{jobId}/errors.csv`) is built from these
rows and is audited as a child-data export (BR-RPT-002 🔴).

---

## Verification

1. A guardian link with no handover right anywhere for a student blocks route assignment (BR-GRD-002).
2. A guardian without `can_authorise_handover` cannot nominate a pickup person.
3. A pickup person outside their validity window is refused at handover.
4. Revoking a pickup person takes effect immediately.
5. A custody restriction blocks handover even where the guardian link grants it.
6. A restricted guardian cannot read the student's location.
7. Student photos are not retrievable without permission and scope.
8. Student credential lookup works by hash; raw credential values are absent from the database.
