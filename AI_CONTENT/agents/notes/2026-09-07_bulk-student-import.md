# 2026-09-07 — Bulk student import (STU-002 / A-12)

## What this is about

Implementation of `POST /students/import`, `GET /students/import/{jobId}`,
`GET /students/import/{jobId}/errors.csv` (backend, `guardian-student`) and the A-12 upload
screen (admin console). Full-stack, delivered against the shapes already written in
`documentation/04-api/STUDENTS_GUARDIANS_API.md` and `documentation/05-ui/ADMIN_WEB.md`.

The feature itself is documented in the tiers (`STUDENTS_GUARDIANS_API.md`, `ERROR_CATALOG.md`,
`03-database/tables/MOD-03-04-students-guardians.md`, `MODULE_MAP.md`). This note only records
the decisions and risks that are *not* in those docs.

## Deferred, on purpose

- **Guardian links / route assignment in the same file.** The A-12 mock in `ADMIN_WEB.md`
  shows `guardian`, `phone`, and `stopId` row errors, implying the eventual importer accepts
  those columns. This version imports **student demographics only** and rejects the whole file
  (`STUDENT_IMPORT_UNSUPPORTED_COLUMN`) if it sees a column it does not understand — enrolling
  students while silently dropping a `guardian` column the office believed it was providing is
  the more dangerous outcome. Guardian/route columns are a follow-up; they need
  `guardian-guardian` changes and BR-GRD-002 handling.
- **Asynchronous processing.** Import is synchronous, one request, one transaction, capped at
  `ImportStudentsUseCase.MAX_ROWS` (5,000). The response already models a *job*
  (`jobId`/`status`) so a later background worker (a `PROCESSING` state, lifting the cap) is an
  additive change, not a contract break. `StudentImportStatus.FAILED` is reserved for that
  world and unused today — whole-file rejections are thrown as `StudentImportRejectedException`
  before any job row is written.
- **"Failed rows in the original format".** `ADMIN_WEB.md` describes the error download as the
  original failed rows, fixed and re-uploaded. What ships is a **diagnostic** report
  (`row,field,code,message`) — the office reads the line numbers against their own master
  spreadsheet. Storing the raw failed rows would mean child PII at rest in an error table
  (§7 minimisation); a line-number report is both safer and still actionable. The admin
  screen builds this file client-side from the import response (no extra round trip); the
  server `errors.csv` endpoint stays for support and reopening an old job, and is audited as
  a child-data export (BR-RPT-002).

## Risks / not yet mitigated

- **Late failure in pass 4 aborts the whole import.** Every candidate is pre-checked
  (`existsByAdmissionNo`, in-file duplicates) before any write, so a failure while enrolling is
  a genuine race with a concurrent enrolment. It rolls the transaction back — nothing partially
  committed — and surfaces as `409`. Acceptable and rare; "valid rows are still imported" holds
  for every case except this one.
- **`errorJpa.saveAll` is unbatched.** No `hibernate.jdbc.batch_size` is configured, so N row
  errors are N inserts in one transaction. Fine for a rare admin operation; revisit if import
  files routinely fail in the thousands.

## Not a decision to re-litigate

- New pub dependency in `admin`: **`web: ^1.1.0`** (was already transitive). It is the only way
  a Flutter Web build can open a file picker and hand back a file to save. Confined to
  `features/students/import/data_provider/student_import_file_gateway.dart` — the one file in
  the console that imports `package:web`.

## Cross-cutting issue found, NOT fixed here (out of scope)

`./gradlew build` **already fails on the `localisation` branch before this change** —
`guardian-common` and `guardian-api` have `spotlessCheck` violations in files untouched by this
work (`OrganizationSuspendedException.java`, `PermissionEnforcementInterceptor.java`,
`GuardianAccountProvisioningAdapter.java`, and others), left by commit `1f6a288` "Refactor code
structure for improved readability". CI (`ci.yml`, `./gradlew build -x test`) still runs the
`spotlessCheck` task, so the backend build is red independent of this feature. `guardian-student`
(this feature's module) is spotless-clean and compiles. Fix is a repo-wide `./gradlew
spotlessApply` as its own commit.

## Kannada

All 22 new strings are English placeholders in `app_kn.arb`, tracked in
`admin/lib/l10n/TRANSLATION_STATUS.md` per ADR-0013. None are safety-critical (import does not
touch handover authorisation, the audit register, or transport removal).
