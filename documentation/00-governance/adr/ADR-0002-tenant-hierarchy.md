# ADR-0002: Organization → School → Branch hierarchy

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** tenancy module, all scoped entities, [`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md)

## Context

Customers range from a single independent school to a group operating hundreds of campuses. The isolation boundary, the operational boundary, and the reporting boundary are not necessarily the same:

- Billing and data isolation belong at the group level.
- Timings, staff, routes, and students belong at the school level.
- Some schools run multiple campuses or shifts that share a name but not a bus fleet.

Getting this wrong is expensive: retrofitting a level into an established hierarchy touches every scoped table and every authorisation check.

## Decision

**A three-level hierarchy: `Organization → School → Branch`.**

- **Organization** is the tenant. `tenant_id` on every scoped table refers to the organization. It is the isolation and billing boundary.
- **School** owns the operational data: students, staff, vehicles, routes, trips.
- **Branch** is an **optional** subdivision of a school. It exists in the model from day one but a tenant may ignore it entirely.

A single independent school is modelled as an organization containing exactly one school. There is no special case in code.

Entities are scoped at the level they operate at — students and routes at school level, not branch level, unless the tenant activates branches.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Two levels (Organization → School) | Simpler, and sufficient for most customers. Rejected because campuses and shifts are common in the target market, and adding a level later requires migrating every scoped table plus every permission check — precisely the retrofit this decision is meant to avoid. |
| Arbitrary-depth tree (adjacency list / `ltree`) | Maximum flexibility. Rejected under KISS: unbounded depth complicates every authorisation query and reporting rollup, to serve a requirement nobody has stated. Three levels covers the known market. |
| School as the tenant | Would isolate schools within a group from each other, breaking group-level reporting and administration, which is a core value proposition for chains. |

## Consequences

**Positive**
- One code path serves both single schools and large chains.
- Group-level administration and reporting work without cross-tenant queries.
- Branch exists when needed, costs nothing when unused.

**Negative / accepted cost**
- An optional level invites inconsistent use. Mitigated by making `branch_id` nullable with a documented meaning: null means "school-wide".
- Authorisation must resolve scope at three levels, which is more complex than two.

**Neutral**
- Depth is fixed at three. A customer needing more must be handled by an ADR amendment, not by improvisation.

## Reversal Cost

**High** for adding or removing a level; **low** for leaving `branch` unused. This is precisely why the level is included now rather than later.

## Verification

1. Integration tests cover both shapes: single-school organization, and multi-school organization with branches active.
2. An authorisation test asserts that a school-scoped user cannot read another school's data within the same organization.
