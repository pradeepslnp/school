# MIGRATION STRATEGY

**Document tier:** 3 — Database
**Status:** Active

---

## Tool and Layout

Flyway, versioned, forward-only. Migrations live in `guardian-backend/guardian-api/src/main/resources/db/migration/`.

```
V1__baseline_tenancy.sql
V2__identity_and_access.sql
V3__students_and_guardians.sql
V4__fleet_and_staff.sql
V5__routes_and_stops.sql
V6__trips_and_manifests.sql
V7__boarding_and_handover.sql
V8__tracking_and_partitions.sql
V9__alerts_and_notifications.sql
V10__incidents.sql
V11__audit.sql
V12__configuration_and_reference.sql
R__seed_permissions.sql          -- repeatable
R__seed_region_profiles.sql      -- repeatable
```

Naming: `V<n>__<snake_case_description>.sql`. Repeatable migrations (`R__`) hold idempotent reference-data seeding and re-run whenever their checksum changes.

Migrations run at application startup in a single, ordered, locked sequence.

---

## Rules

1. **Never edit an applied migration.** Flyway checksums fail, and any environment that already ran it silently diverges. Fix forward with a new migration.
2. **Forward-only.** No `undo` scripts. Rollback is a new migration or a restore from backup — see below.
3. **Every migration is idempotent-safe to attempt**: `IF NOT EXISTS` where the construct supports it.
4. **Every new tenant-scoped table gets RLS in the same migration that creates it** ([`RLS_POLICIES.md`](RLS_POLICIES.md)). Not the next one.
5. **No data loss without an expand-contract sequence.**
6. **Tested against realistic data volumes** before production, not against an empty schema.

---

## Why Forward-Only

A rollback script is written when the change is fresh and is executed, if ever, during an incident — untested, under pressure, against data the original author never saw.

Forward-only means the recovery path is the same path used every day. Combined with expand-contract, it means a bad deploy is reverted by deploying the previous application version, with the schema still compatible.

---

## Expand-Contract

Any change that could break the running application is done in phases, each independently deployable. **The old and new application versions must both work against the intermediate schema** — that is the property that makes deploys reversible.

### Renaming a column

```
1  EXPAND   Add new column, nullable. Deploy.
2  BACKFILL Migrate data in batches. Deploy code writing BOTH columns.
3  SWITCH   Deploy code reading the new column.
4  CONTRACT Drop the old column — a later release, once rollback is no longer wanted.
```

### Adding a NOT NULL column

```
1  Add nullable, with a default for new rows.
2  Backfill existing rows in batches.
3  Add the NOT NULL constraint (validate separately to avoid a long lock).
```

### Dropping a table

Stop writing → stop reading → verify no access for a full retention cycle → drop. **Never in the same release as the code change.**

---

## Locking and Large Tables

At reference scale, some tables are large enough that a careless migration locks the platform during a school run.

| Operation | Safe approach |
|---|---|
| Add column | Nullable with no default is fast. A volatile default rewrites the table — avoid. |
| Add index | `CREATE INDEX CONCURRENTLY`, outside a transaction. |
| Add FK / check constraint | `NOT VALID` first, then `VALIDATE CONSTRAINT` separately — avoids a full-table lock. |
| Backfill | Batched with commits between; never one statement over millions of rows. |
| `position_history` | Never altered in place. Change applies to new partitions only. |

`lock_timeout` and `statement_timeout` are set for migration sessions so a migration fails fast rather than blocking the platform.

**Migrations run outside peak windows.** The load profile ([`SCALABILITY.md`](SCALABILITY.md)) makes the safe window obvious and generous.

---

## Partition Management

`position_history` partitions are created ahead of time by a scheduled job, not by migrations.

The job **must** apply RLS to each new partition ([`RLS_POLICIES.md`](RLS_POLICIES.md)). It also drops partitions past their retention (BR-TRACK-007).

A missing future partition breaks ingestion, so the job alerts if the next partition does not exist well before it is needed.

---

## Testing

| Test | Purpose |
|---|---|
| Clean-schema apply | All migrations run from empty against Testcontainers PostgreSQL. |
| Repeat apply | Running twice is a no-op. |
| RLS coverage | Every `tenant_id` table has a forced policy — **fails the build otherwise**. |
| Isolation | Cross-tenant reads return zero rows. |
| Realistic volume | Migrations applied to a seeded dataset; duration measured. |
| Backward compatibility | The previous application version starts against the new schema — proves the deploy is reversible. |

---

## Environments

```
Local → CI → Staging → Production
```

Staging runs against a sanitised production-shaped dataset. **Production migrations always run on a database with a verified recent backup** ([`BACKUP_AND_DR.md`](../08-deployment/BACKUP_AND_DR.md)).

---

## Failure Handling

Flyway holds a lock, so migrations never run concurrently across instances. On failure the application does not start — it does not serve traffic against a half-migrated schema.

Recovery: diagnose, write a corrective forward migration, redeploy. Restoring from backup is the last resort and is why the pre-migration backup is verified rather than assumed.

Because every migration is expand-contract, the previous application version can be redeployed against the new schema while the fix is prepared.
