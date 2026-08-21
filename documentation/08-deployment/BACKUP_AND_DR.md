# BACKUP AND DISASTER RECOVERY

**Document tier:** 8 — Deployment
**Status:** Active

---

## What Must Survive

Not all data is equally recoverable, and the priority order is not the usual one.

| Data | If lost | Priority |
|---|---|---|
| **Safety records** — boarding, handovers, reconciliations | **Unrecoverable and legally material.** Evidence of duty of care. | 1 |
| **Audit records** | Unrecoverable. Evidence of what was done and by whom. | 1 |
| Configuration — students, guardians, routes, staff | Recoverable by re-entry, at enormous cost | 2 |
| Operational — trips, manifests, alerts | Partially reconstructable | 3 |
| Position history | Lost telemetry; hurts investigations | 4 |
| Live position cache | Repopulates on the next report | 5 |

**Priority 1 is why the platform is a modular monolith with a shared database** ([`ARCHITECTURE_OVERVIEW.md`](../02-system-design/ARCHITECTURE_OVERVIEW.md)): the audit write shares the transaction with the change it records (BR-AUD-002 🔴), so a restore cannot produce a state where a boarding event exists without its audit trail, or vice versa.

---

## Objectives

| Metric | Target | Rationale |
|---|---|---|
| **RPO** (data loss) | **≤ 1 minute** | A lost boarding event is an unaccounted child |
| **RTO** (downtime) | ≤ 30 minutes during school hours | Two peaks per day; a peak missed is a day's records missed |
| RTO outside school hours | ≤ 4 hours | Low consequence |
| Backup retention | Per region profile legal obligation (BR-AUD-007) | |

RPO is driven by consequence, not convention. During a morning run, one minute of lost writes is dozens of boarding events — children whose journeys have no record.

**The driver app's offline queue is the real RPO backstop** (ADR-0008): events recorded on devices survive a database outage entirely and sync afterwards. The database RPO covers everything else.

---

## Backup Strategy

| Layer | Mechanism | Frequency |
|---|---|---|
| Continuous | WAL archiving, point-in-time recovery | Streaming |
| Full snapshot | Automated | Daily, off-peak |
| Cross-region copy | Replicated snapshot | Daily |
| Pre-migration | Verified snapshot | Every production migration |

All backups are **encrypted at rest** and use separate credentials from the application — a compromise of the application must not grant the ability to destroy backups.

Cross-region copies respect data residency ([`ENVIRONMENTS.md`](ENVIRONMENTS.md)): a region requiring in-country data has in-country backups, and its copies do not leave.

---

## Restore Testing 🔴

**An untested backup is not a backup.**

| Test | Frequency |
|---|---|
| Automated restore to a scratch environment | Weekly |
| Schema and row-count verification | Weekly, automated |
| **RLS verification post-restore** | Weekly, automated |
| Full DR drill with the team | Quarterly |
| Point-in-time recovery to an arbitrary timestamp | Quarterly |

### RLS verification after restore is mandatory

A restore that loses `FORCE ROW LEVEL SECURITY`, or restores tables owned by the wrong role, produces a running platform **with no tenant isolation** — and nothing else would fail. Every query would still work; every tenant would see every child.

The automated post-restore check asserts:
- Every `tenant_id` table has RLS enabled **and forced**
- Every policy declares `USING` and `WITH CHECK`
- `guardian_app` lacks `BYPASSRLS` and owns no tables
- A cross-tenant read returns zero rows

This is the single most important item in this document.

---

## Failure Scenarios

### Database primary loss

Failover to a standby in another availability zone. WAL streaming holds RPO within target.

During failover the platform is unavailable — **and the driver app keeps recording offline** (ADR-0008). Boarding and handover continue; they sync when the platform returns. This is the property that makes a database outage a service incident rather than a safety incident.

### Region loss

Restore from the cross-region snapshot into a standby region. RTO is hours, not minutes — accepted, because regional loss is rare and the offline path protects the safety-critical function meanwhile.

### Data corruption

Point-in-time recovery to just before the corrupting event. Correlation IDs and audit records identify the window ([`OBSERVABILITY.md`](OBSERVABILITY.md)).

Because safety and audit tables are **append-only** (BR-AUD-001, BR-BOARD-001 🔴), corruption there cannot be an accidental `UPDATE` — the grants and triggers prevent it. This narrows the corruption surface considerably.

### Accidental deletion

Soft delete on configuration data means most "deletions" are recoverable in-place. Safety and audit records have no delete path at all.

### Redis loss

No recovery needed. Live tracking degrades until the next position report; **no data is lost** (ADR-0004).

### Ransomware / malicious destruction

Backups use separate credentials and are immutable for their retention window. Restoration is from the last known-good snapshot, with point-in-time recovery to just before the event.

---

## Restore Procedure

1. **Declare** the incident; notify stakeholders per the region profile's obligations
2. **Stop writes** — take the application offline to prevent divergence
3. **Choose the recovery point** using audit and correlation data
4. **Restore** to a new instance, never over the live one
5. **Verify**: schema version · row counts · **RLS assertions** · sample tenant isolation check
6. **Reconcile**: identify trips and safety events in the lost window; the driver app's queue will resupply device-recorded events
7. **Resume** writes and monitor
8. **Communicate** what was lost, to whom, and what was recovered
9. **Post-incident review** with a documented preventive action

Step 6 matters and is easily forgotten: **after a restore, devices still hold unsynced safety events.** They will arrive, be deduplicated by `client_event_id` (BR-BOARD-009), and fill part of the gap. The reconciliation step must expect them rather than treat them as anomalies.

---

## Communication

A restore losing safety records is a **notifiable event to affected schools**, regardless of whether it meets a regulatory breach threshold. A school's duty of care depends on the platform's records; if a gap exists, they must know its exact extent.

The notification states: the affected time window, the trips and record types involved, what was recovered from device queues, and what could not be recovered.

---

## What Is Never Restored

- Real production data into staging or local ([`ENVIRONMENTS.md`](ENVIRONMENTS.md)) — staging is synthetic, and anonymisation is unreliable for this dataset
- Backups onto a live production database — always restore to a new instance, then cut over
