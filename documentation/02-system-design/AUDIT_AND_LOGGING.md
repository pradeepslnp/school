# AUDIT AND LOGGING

**Document tier:** 2 — System Design
**Status:** Active
**Enforces:** BR-AUD-*, BR-IAM-012, BR-RPT-002

Audit and logging are different things with different purposes, retention, and guarantees. Conflating them is the usual mistake.

| | Audit | Logging |
|---|---|---|
| **Purpose** | Evidence of what was done and by whom | Diagnosing system behaviour |
| **Consumer** | Investigators, auditors, school management | Engineers |
| **Store** | PostgreSQL, append-only | Log aggregation |
| **Retention** | Per legal obligation (BR-AUD-007) | Weeks |
| **Guarantee** | Transactional; loss is unacceptable | Best-effort |
| **Contains PII** | Yes, minimally and deliberately | **Never** |

---

## Audit

### The transactional guarantee

**The audit write participates in the same transaction as the change it records** (BR-AUD-002). If the audit write fails, the change rolls back.

This is a deliberate trade: the platform will refuse an operation rather than perform it unrecorded. In a system whose records may be examined after a child is harmed, an unrecorded action is worse than a failed one.

It is also why the platform is a modular monolith with a shared database ([`ARCHITECTURE_OVERVIEW.md`](ARCHITECTURE_OVERVIEW.md)) — across service boundaries this guarantee would require a distributed transaction or be quietly abandoned.

### Record shape

| Field | Notes |
|---|---|
| `id`, `tenant_id`, `occurred_at` | |
| `actor_id`, `actor_type`, `actor_role` | Role **as held at the time** — roles change |
| `action` | Canonical verb, e.g. `HANDOVER_OVERRIDE` |
| `subject_type`, `subject_id` | What was acted upon |
| `reason` | **Required** for overrides (BR-AUD-004) |
| `source` | API, device, job, platform operation |
| `correlation_id` | Links to logs and to other records in the same operation |
| `before`, `after` | Changed fields only, sensitive values redacted |

### What is audited

**Always:**
- Every safety event: boarding, alighting, handover, reconciliation outcome
- **Every override, with its reason** — an override without a reason is rejected (BR-AUD-004)
- Trip lifecycle transitions
- Guardian relationship and pickup-person changes (BR-GRD-006)
- Custody restriction changes
- Role, permission, and session changes
- Configuration changes, with old and new values (BR-CFG-004)
- Every cross-tenant platform operation (BR-TEN-004, AUD-004)
- Every export of child data, with record count (BR-RPT-002)
- Every read of child personal data by a non-guardian (BR-IAM-012)

**Not audited:** ordinary reads by a guardian of their own child; system-generated position ingestion (volume without evidentiary value).

### Append-only

No update or delete path exists within the retention period (BR-AUD-001). Enforced by database grants — the application role holds `INSERT` and `SELECT` on audit tables and nothing else. This is stronger than an application-level convention, and it is the point.

Corrections are new records referencing the original, exactly as with boarding events (BR-BOARD-001).

### Data-access audit

Child-data reads are high-volume, so they are recorded in a separate table from action audit — same guarantees, different retention and indexing. This is the control that makes insider misuse *detectable*: a staff member browsing children outside their operational need produces a visible pattern.

---

## Logging

### Format

Structured JSON. Every entry carries: timestamp, level, correlation ID, tenant ID, actor ID, module, message.

Correlation ID enters at the edge, propagates through events and jobs, and appears in audit records — so a support question can be traced from a parent's report to the exact request and its audit trail.

### Levels

| Level | Use |
|---|---|
| `ERROR` | Operation failed, intervention likely needed |
| `WARN` | Degraded or unexpected but handled — provider retry, template gap |
| `INFO` | Significant lifecycle events — trip started, batch completed |
| `DEBUG` | Development only; not enabled in production by default |

### Never logged

Passwords, tokens, OTPs, provider credentials, encryption keys, full child records, guardian contact details, position coordinates tied to a named child.

**Students appear as IDs, never names.** A test scans log output for known-sensitive field names and fails the build on a hit — because this rule is otherwise violated by accident, repeatedly, in every system that merely writes it down.

### Metrics and traces

Metrics on every safety-critical path: boarding events recorded, reconciliation outcomes, notification dispatch and failure rates, alert volumes by type, ingestion throughput and rejection rate.

Traces span ingestion → processing → notification, so end-to-end latency against the charter's 10-second notification budget is measurable rather than assumed.

Detail in [`OBSERVABILITY.md`](../08-deployment/OBSERVABILITY.md).

---

## Retention

| Data | Retention |
|---|---|
| Action audit | Per region profile legal obligation; platform floor applies (BR-AUD-007) |
| Data-access audit | Shorter than action audit, long enough for investigation |
| Safety events | Full retention; never early-deleted |
| Position history | Tenant configuration, bounded by an investigation-sufficient floor (BR-TRACK-007) |
| Application logs | Weeks |

Retention is enforced automatically, not manually.

---

## Verification

1. A failing audit write rolls back the business change (BR-AUD-002).
2. The application role has no `UPDATE` or `DELETE` grant on audit tables.
3. An override submitted without a reason is rejected (BR-AUD-004).
4. Every cross-tenant platform operation writes an audit record before the first read.
5. Every child-data read by a non-guardian writes a data-access record.
6. Every export writes an audit record including record count.
7. Log output contains no field from the sensitive-field denylist.
8. Correlation ID propagates from request through event handling to audit record.
