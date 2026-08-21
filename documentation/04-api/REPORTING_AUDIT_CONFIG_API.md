# REPORTING, AUDIT & CONFIGURATION API

**Document tier:** 4 — API
**Modules:** MOD-15, MOD-16, MOD-17 · **Features:** RPT-001…007, AUD-001…005, CFG-001…007

---

# Reporting

All reports run against a **read replica** — reporting queries never block operational writes (BR-RPT-004).

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/reports/trip-operations` | RPT-001 | `PERM-REPORT-OPERATIONAL` | BR-RPT-001/003 |
| `GET` | `/reports/student-attendance` | RPT-002 | `PERM-REPORT-OPERATIONAL` | BR-RPT-001 |
| `GET` | `/reports/safety-exceptions` | RPT-003 | `PERM-REPORT-SAFETY` | BR-SAFE-001 |
| `GET` | `/reports/compliance` | RPT-004 | `PERM-REPORT-COMPLIANCE` | BR-FLEET-002, BR-STAFF-003 |
| `GET` | `/reports/incidents` | RPT-005 | `PERM-REPORT-SAFETY` | BR-INC-003 |
| `GET` | `/dashboards/management` | RPT-007 | `PERM-REPORT-OPERATIONAL` | BR-RPT-001 |
| `POST` | `/exports` | RPT-006 | `PERM-DATA-EXPORT` | BR-RPT-002 🔴 |
| `GET` | `/exports/{jobId}` | RPT-006 | `PERM-DATA-EXPORT` | |

### Scope containment

**A report never reveals data the requester could not read directly** (BR-RPT-001). Scope is applied inside the query, not filtered afterwards — post-filtering means the wrong data was already assembled, and an aggregate could still leak it.

### Every response states its time basis

```json
{
  "data": { },
  "meta": { "timezone": "Asia/Kolkata", "generatedAt": "2026-08-03T18:00:00Z",
            "dataAsOf": "2026-08-03T17:55:00Z" }
}
```

Required by BR-RPT-003. A report showing "07:42" without a timezone is ambiguous across a multi-region platform (BR-CFG-006).

### `GET /reports/safety-exceptions`

The report a principal reads. Left-behind events, no-shows, wrong-stop alights, handover overrides, refused handovers, and no-receiver exceptions — with actor, reason, and resolution for each.

Every row traces to a business rule ID, so "what happened and which control caught it" is answerable together.

### `POST /exports` 🔴

```json
{ "exportType": "STUDENT_TRANSPORT_REGISTER", "schoolId": "…", "format": "CSV" }
```

**`202`** with a job ID. Every export of child personal data is permission-gated and audited with actor, scope, and **record count** (BR-RPT-002 🔴).

The record count is the point: bulk exfiltration is invisible in an access log that records only "an export happened". A count makes an unusual export detectable.

Download links are short-lived, single-use, and authorisation-checked.

---

# Audit

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/audit-records` | AUD-002 | `PERM-AUDIT-VIEW` | BR-AUD-003 |
| `GET` | `/audit-records/overrides` | AUD-003 | `PERM-AUDIT-VIEW` | BR-AUD-004 |
| `GET` | `/students/{id}/access-log` | IAM-010 | `PERM-AUDIT-VIEW` | BR-IAM-012 🔴 |
| `GET` | `/audit-records/platform-access` | AUD-004 | `PERM-AUDIT-VIEW` | BR-TEN-004 🔴 |
| `POST` | `/audit-records/export` | AUD-002 | `PERM-AUDIT-EXPORT` | BR-AUD-007 |

**There is no `POST`, `PATCH`, or `DELETE` on audit records.** They are written only in-transaction by the modules that cause them (BR-AUD-002 🔴). No API path can create or alter one — the absence of these endpoints is itself the control ([`MOD-16-17-audit-config.md`](../03-database/tables/MOD-16-17-audit-config.md)).

### `GET /audit-records/overrides`

The override register (AUD-003). Every boarding override, wrong-stop alight, handover override, and manifest amendment — each with its **required** reason (BR-AUD-004).

This is the report a school reviews when a parent questions what happened. An override without a reason cannot exist, so every row here is answerable.

### `GET /students/{id}/access-log`

Who has read this child's data, when, and for what purpose (BR-IAM-012 🔴). Guardian reads of their own children are excluded — they are the expected case and would drown the signal.

This is what makes insider misuse **detectable** rather than merely prohibited.

### `GET /audit-records/platform-access`

Every cross-tenant platform operation, with the justification supplied at elevation (BR-TEN-004 🔴). The one deliberate hole in tenant isolation is also the most heavily instrumented path in the system.

---

# Configuration

| Method | Path | Feature | Permission | Rules |
|---|---|---|---|---|
| `GET` | `/configuration/definitions` | CFG-001 | `PERM-CONFIG-VIEW` | BR-CFG-001 |
| `GET` | `/configuration/values` | CFG-002 | `PERM-CONFIG-VIEW` | BR-CFG-002 |
| `PUT` | `/configuration/values` | CFG-002 | `PERM-CONFIG-EDIT` | BR-CFG-003/004 |
| `GET` | `/region-profiles` | CFG-003 | `PERM-CONFIG-VIEW` | ADR-0007 |
| `GET` | `/reference-data/{category}` | CFG-003 | authenticated | ADR-0007 |
| `GET` | `/localisation/{locale}` | CFG-006 | authenticated | BR-CFG-005 |

### `GET /configuration/definitions`

```json
{
  "data": [
    { "configKey": "alert.overspeed.threshold_mps", "valueType": "DECIMAL",
      "defaultValue": "16.7", "minValue": 5.0, "maxValue": 25.0,
      "scopeLevel": "SCHOOL", "isSafetyCritical": true },
    { "configKey": "handover.verification_methods", "valueType": "ENUM",
      "allowedValues": ["QR","OTP","PIN","VISUAL"], "scopeLevel": "ORG",
      "isSafetyCritical": true }
  ]
}
```

Every key declares a type, default, bounds, and the lowest scope at which it may be set (BR-CFG-001).

### `PUT /configuration/values` 🔴

```json
{ "scopeLevel": "SCHOOL", "scopeRefId": "…",
  "values": [ { "configKey": "alert.overspeed.threshold_mps", "value": "13.9" } ] }
```

**Validated on write, not on read.** Type, range, and scope are checked when the value is set — misconfiguration surfaces when it is made, not during a school run.

| Condition | Error | Rule |
|---|---|---|
| Outside platform floor/ceiling | `422 CONFIG_VALUE_OUT_OF_BOUNDS` | BR-CFG-003 🔴 |
| Unknown key | `400 CONFIG_KEY_UNKNOWN` | BR-CFG-001 |
| Set below permitted scope | `422 CONFIG_SCOPE_NOT_PERMITTED` | BR-CFG-001 |
| Safety-critical without permission | `403 CONFIG_SAFETY_CRITICAL_PERMISSION_REQUIRED` | BR-CFG-003 🔴 |

**A tenant may tighten a safety threshold; never loosen it past the floor** (BR-SAFE-007 🔴).

This is where Configuration over Hardcoding yields to Child Safety First ([`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) resolution order). A tenant configures *which* handover verification methods are acceptable — they cannot set the list to empty and configure verification away (BR-HAND-001 🔴).

Every change is audited with old and new values (BR-CFG-004).

### `GET /reference-data/{category}`

Categories: `vehicle_document_types` · `staff_credential_types` · `relationship_types` · `incident_types` · `verification_methods`

Values come from the region profile (ADR-0007). Clients render these rather than hardcoding lists — a client with a hardcoded document-type dropdown would break in a new market just as a hardcoded enum would.

### `GET /localisation/{locale}`

All user-facing strings as resource keys (BR-CFG-005). **No string destined for a user is written inline in code**, in the backend or in any client.

---

## Verification

1. A report never returns data outside the requester's scope.
2. Every report response includes `timezone` and `generatedAt`.
3. Every export writes an audit record including record count.
4. Export download links expire and are single-use.
5. No API path creates, updates, or deletes an audit record.
6. Every override in the register has a non-empty reason.
7. Child-data access log excludes guardian reads of their own children.
8. A configuration value outside its bounds is rejected on write.
9. A safety-critical change without `PERM-CONFIG-SAFETY-EDIT` is refused.
10. Setting handover verification methods to an empty list is rejected.
11. Reporting queries execute against the replica, not the primary.
