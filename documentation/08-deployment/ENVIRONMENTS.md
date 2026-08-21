# ENVIRONMENTS

**Document tier:** 8 — Deployment
**Status:** Active

---

## The Environments

| Environment | Purpose | Data | Access |
|---|---|---|---|
| **Local** | Development | Seeded synthetic | Developer machine |
| **CI** | Automated verification | Ephemeral per run | Pipeline only |
| **Staging** | Pre-production verification | **Synthetic, production-shaped** | Team |
| **Production** | Live | Real child data | Restricted, audited |

---

## Staging Data 🔴

**Staging never contains real child or guardian data.** Not anonymised production data — synthetic data generated to production *shape*.

Anonymisation is unreliable for this dataset: a route, a stop, a school, and a timestamp re-identify a child even without a name. Given [`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §7 (data minimisation) and the charter's duty of care, the risk is not worth the fidelity gain.

Generated staging data includes:
- Two organizations under **different region profiles** — so ADR-0007 is exercised continuously
- Realistic volumes: schools, students, guardians, vehicles, routes
- Documents and credentials at varying expiry, including expired
- Trips with exceptions: no-shows, overrides, an unaccounted child, a resolved SOS

That last item matters: staging must exercise the safety paths, not only the happy path.

---

## Configuration

| Kind | Source |
|---|---|
| Application settings | `application-<env>.yml`, committed |
| Secrets | Secret manager or environment — **never source control** |
| Tenant behaviour | Database configuration (ADR-0007) |
| Feature flags | Configuration registry, per tenant |

**No environment differs in behaviour by code branch.** A `if (env == "prod")` is a defect — environments differ in configuration and scale, not in logic. Otherwise staging stops predicting production, which is its only purpose.

### Secrets

Distinct per environment. Rotatable without redeployment. Never logged, never returned by any API — including per-tenant provider credentials, even to the tenant that set them.

Production secrets are accessible only to the deployment pipeline and to on-call engineers, and access is audited.

---

## Infrastructure

Per environment:

```
API (n instances)      ──┐
Ingestion (n)          ──┼──► PostgreSQL primary
Worker (n)             ──┘         │
                                   ├──► read replica (reporting)
                       ──────────► Redis
```

Three deployables from the same modules ([`ARCHITECTURE_OVERVIEW.md`](../02-system-design/ARCHITECTURE_OVERVIEW.md)) — separated because their load profiles differ, not because their code does.

| Environment | Scale |
|---|---|
| Staging | Single small instance of each; no replica |
| Production | Autoscaled; replica; multi-AZ |

**Staging runs the same topology at smaller scale.** A topology difference between staging and production is a class of bug staging cannot catch.

### Database roles

Identical in every environment ([`RLS_POLICIES.md`](../03-database/RLS_POLICIES.md)):

- `guardian_owner` — migrations only
- `guardian_app` — runtime, **`NOBYPASSRLS`**, not the owner
- `guardian_readonly` — replica reads

Running the application as owner in *any* environment defeats RLS and hides isolation bugs until production. Verified by a startup assertion, not by convention.

---

## Autoscaling

The load profile is **bimodal and predictable** — two sharp peaks per school day ([`SCALABILITY.md`](../02-system-design/SCALABILITY.md)).

Scaling is therefore **schedule-driven with reactive headroom**, not purely reactive. The peaks arrive in minutes; reactive scaling lags them. Scaling up before the morning run costs less than being short during it.

Off-peak the platform scales down to a floor sufficient for background jobs and any late trip.

---

## Timezones

Servers run UTC. All timestamps stored UTC (`TIMESTAMPTZ`). Display timezone comes from the **school** (BR-CFG-006).

Scheduled jobs that are per-school — trip generation, calendar rollover — iterate schools in their own timezones. A single "run at midnight" job would be wrong for every school outside the server's zone, and would produce or miss trips.

---

## Access Control

| Environment | Access |
|---|---|
| Staging | Team, with normal application authentication |
| Production application | Only through the application, with real permissions |
| Production database | On-call only, break-glass, audited |
| Production logs | Team; **contain no child PII** by construction |

**There is no direct-database support path.** Tenant support goes through `PERM-PLATFORM-TENANT-ACCESS`, which requires a justification and writes an audit record before the first read (BR-TEN-004 🔴). A database console bypasses that entirely, which is why it is break-glass rather than routine.

---

## Promotion

```
PR → CI (build, tests, architecture, security) → merge to main
      ▼
Staging (automatic)
      ▼
Verification: smoke, safety-critical matrix, migration timing
      ▼
Production (manual approval)
```

Every artefact is built once and promoted — the binary tested in staging is the binary that runs in production. Rebuilding per environment means testing something other than what ships.

Details in [`CI_CD.md`](CI_CD.md).

---

## Data Residency

Where a region requires data to remain in-country, the deployment is a **separate regional instance** — its own database, its own application, its own secrets.

This is deliberately not solved by tenant-level partitioning within one database. Residency is a legal boundary, and ADR-0001's shared-schema model does not provide one.

Region profiles (ADR-0007) handle *behavioural* regional variation. Residency is an infrastructure concern, and the two are not interchangeable.
