# Guardian Infra

Local development infrastructure for the Guardian Platform: PostgreSQL 16 and Redis 7, plus the database role bootstrap that makes row-level security meaningful.

**Local development only.** Nothing here provisions or deploys anything. Environments and deployment live in [`documentation/08-deployment/`](../documentation/08-deployment/).

---

## Use

```bash
docker compose up -d      # from this directory
docker compose ps
```

Or, more usually, from a sibling repository:

```bash
docker compose -f ../infrastructure/docker-compose.yml up -d
```

| Service | Address |
|---|---|
| PostgreSQL 16 | `localhost:5432`, database `guardian` |
| Redis 7 | `localhost:6379` |

Reset — **deletes local data**:

```bash
docker compose down -v && docker compose up -d
```

---

## Database roles

`db/init/01-roles.sql` runs once, on first container start, before any migration. It creates the two roles the isolation model depends on:

| Role | Purpose |
|---|---|
| `guardian_owner` | Owns schema objects. **Flyway only.** |
| `guardian_app` | Application runtime. `NOBYPASSRLS`, and not the owner. |

The separation is the whole reason RLS holds. Postgres exempts a table's owner from its own policies unless they are `FORCE`d, and even then, running the application as owner removes the safety net that catches an unscoped query in development instead of production. Do not collapse these two roles for convenience.

See [`documentation/03-database/RLS_POLICIES.md`](../documentation/03-database/RLS_POLICIES.md).

---

## Passwords

The defaults (`local_owner`, `local_app`) are development placeholders and are meant to be visible in git. Override for anything shared:

```bash
export GUARDIAN_DB_OWNER_PASSWORD=…
docker compose up -d
```

Real credentials never enter this repository. `.env` is gitignored.
