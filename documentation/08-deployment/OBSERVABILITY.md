# OBSERVABILITY

**Document tier:** 8 — Deployment
**Status:** Active
**Related:** [`AUDIT_AND_LOGGING.md`](../02-system-design/AUDIT_AND_LOGGING.md) — audit and logging are different things with different guarantees.

---

## What Must Be Observable

Ordinary SaaS observability watches availability and latency. Here the primary question is different:

> **Is every child accounted for, and did every safety notification reach a parent?**

Metrics below are ordered by that priority. Uptime matters, but a platform that is up and silently failing to deliver `CRITICAL` notifications is worse than one that is visibly down.

---

## Safety Metrics 🔴

| Metric | Alert when |
|---|---|
| Unaccounted children, open | **> 0 for longer than the detection window** — page immediately |
| Trips completed but not closed | Above threshold — reconciliations are not being resolved |
| Reconciliation exceptions per trip | Sustained rise — a process or device problem |
| Handover overrides per day | Sustained rise — verification may be failing in practice |
| `HANDOVER_REFUSED` / `NO_RECEIVER` incidents | Any occurrence — notify, do not merely record |
| Boarding events recorded electronically | **< 99%** of expected (charter measure) |
| SOS unacknowledged | Beyond escalation window — page |
| `CRITICAL` notification delivery failure | **Any** — page |

The first row is the platform's reason for existing. It pages a human, not a dashboard.

The handover-override metric is a **leading indicator**: a rising override rate usually means verification is too slow or the credential flow is broken, and staff are working around it. Left unwatched, the control decays into a formality.

---

## Delivery Metrics

| Metric | Alert when |
|---|---|
| Board/alight notification latency | p95 > 10 s (charter measure) |
| Notification dispatch failure rate, per channel | > threshold |
| Fallback-channel escalations | Rising — the primary channel is degrading |
| Notifications with no reachable channel | Any — a parent is unreachable |
| Template gaps logged | Any — a locale is unserved |

---

## Tracking Metrics

| Metric | Alert when |
|---|---|
| Ingestion acknowledgement | p95 > 100 ms |
| Live position freshness | p95 > 30 s (charter measure) |
| Position rejection rate | Rising — a device is malfunctioning or spoofing |
| Vehicles reporting vs vehicles on active trips | Gap — devices are offline |
| **Next partition exists** | **Missing — ingestion will break** |
| Geofence evaluation lag | p95 > 3 s |

The partition check has days of margin by design. A missing partition means inserts have nowhere to go, and it is entirely preventable ([`INDEXING_AND_PARTITIONING.md`](../03-database/INDEXING_AND_PARTITIONING.md)).

---

## Security Metrics 🔴

| Metric | Alert when |
|---|---|
| Cross-tenant access attempts | **Any** — investigate immediately |
| Refresh-token reuse detections | Any — a token was captured |
| Failed authentications | Spike per identifier or source |
| Child-data reads per actor | Anomalous volume — possible insider misuse |
| Export volume and record counts | Anomalous — possible exfiltration |
| Platform tenant elevations | Every one, reviewed |
| Requests with unset tenant context | Any — a code path is missing context |

**Cross-tenant attempts alert at any volume.** RLS makes them return zero rows rather than data, so they are not incidents in themselves — but a single one means a code path exists that tried, and that path needs finding before it is reached with a bug that matters.

---

## System Metrics

Standard four golden signals per deployable, plus:

| Metric | Alert when |
|---|---|
| Database connection pool saturation | > 80% — the API's real bottleneck |
| Redis availability | Down — tracking degrades, boarding must not |
| Worker queue depth | Growing — notifications delaying |
| Per-tenant request share | One tenant dominating — fairness breach |
| Replica lag | Beyond threshold — reports going stale |

---

## Logging

Structured JSON with correlation ID and tenant ID on every entry ([`AUDIT_AND_LOGGING.md`](../02-system-design/AUDIT_AND_LOGGING.md)).

**Never logged:** passwords, tokens, OTPs, provider credentials, full child records, guardian contact details, coordinates tied to a named child. **Students appear as IDs, never names.**

A CI test scans log output against a sensitive-field denylist and fails the build on a hit — this rule is otherwise violated by accident, repeatedly, in every system that merely writes it down.

Retention: weeks. Logs are for diagnosis; **audit records are the evidence** and are retained per legal obligation.

---

## Tracing

Distributed traces span the paths where latency budgets exist:

```
device → ingestion → event processing → notification → provider
API request → use case → repository → audit write
```

Correlation IDs propagate through HTTP, domain events, and background jobs, and appear in audit records — so a parent's report can be traced from their message to the exact request and its audit trail.

---

## Dashboards

| Dashboard | Audience | Shows |
|---|---|---|
| **Safety** | On-call, platform ops | Unaccounted children, unresolved reconciliations, SOS, critical delivery failures |
| Delivery | Platform ops | Notification latency and failure by channel and tenant |
| Tracking | Platform ops | Ingestion rate, freshness, device coverage, partition health |
| Security | Security | Cross-tenant attempts, token reuse, access anomalies, elevations |
| System | Engineering | Golden signals, pools, queues, replica lag |
| Tenant | Support | Per-tenant activity and error rates |

The safety dashboard is the default view for on-call.

---

## Alert Discipline

The same rule the product applies to parents applies to engineers: **an alert stream that is noisy gets ignored, and then the real alert is invisible** ([`PERSONAS.md`](../01-product-discovery/PERSONAS.md), Anil).

| Severity | Response | Examples |
|---|---|---|
| **Page** | Immediate | Unaccounted child, `CRITICAL` delivery failure, cross-tenant attempt, platform down |
| **Ticket** | Next business day | Rising override rate, template gaps, replica lag |
| **Dashboard** | Reviewed periodically | Trends, capacity |

Every paging alert has a runbook and is actionable. **An alert with no action is deleted, not tuned** — a page nobody can act on trains people to ignore pages.

Alerts are deduplicated the same way product alerts are (BR-ALERT-005): a continuing condition is one alert, not a stream.

---

## Health Checks

| Endpoint | Purpose |
|---|---|
| `/health/liveness` | Process alive |
| `/health/readiness` | Dependencies reachable; safe to receive traffic |
| `/health/startup` | Migrations applied, schema version correct |

**Readiness includes an RLS assertion** — if tenant isolation cannot be verified against the live database, the instance does not serve traffic. That is the correct trade for the platform's primary security control.

---

## Incident Response

1. **Detect** — alert fires with a runbook link
2. **Assess** — is this a safety incident or a system incident?
3. **Contain** — a suspected compromise of guardian relationships or handover controls escalates on the **safety** path, not merely the technical one
4. **Investigate** — correlation IDs link logs, traces, and audit records
5. **Communicate** — affected tenants informed per the region profile's obligations
6. **Remediate** — fix, then add the regression test

**A data incident involving child location or guardian authorisation is treated as a child-safety incident.** It is not merely a privacy matter, and the escalation reflects that.
