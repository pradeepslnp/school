# Architecture Decision Records

An ADR records a decision that is expensive to reverse: why it was made, what was rejected, and what it costs.

## Status values

| Status | Meaning |
|---|---|
| `Proposed` | Written, not yet ratified. **Treat as an assumption, not fact.** |
| `Accepted` | Ratified. Binding on all lower-tier documents. |
| `Superseded by ADR-nnnn` | Historical. |
| `Rejected` | Considered and declined; kept so it is not re-proposed. |

## Index

| ID | Title | Status |
|---|---|---|
| [ADR-0001](ADR-0001-multi-tenancy-strategy.md) | Multi-tenancy via shared schema with Row-Level Security | Proposed |
| [ADR-0002](ADR-0002-tenant-hierarchy.md) | Organization → School → Branch hierarchy | Proposed |
| [ADR-0003](ADR-0003-admin-web-client.md) | Flutter Web for the administration client | Proposed |
| [ADR-0004](ADR-0004-realtime-tracking-pipeline.md) | Real-time tracking pipeline | Proposed |
| [ADR-0005](ADR-0005-notification-provider-abstraction.md) | Provider-abstracted notification channels | Proposed |
| [ADR-0006](ADR-0006-authentication-model.md) | JWT access/refresh with tenant-scoped RBAC | Proposed |
| [ADR-0007](ADR-0007-regional-configuration.md) | Region-specific behaviour as configuration | Proposed |
| [ADR-0008](ADR-0008-offline-first-driver-app.md) | Offline-first driver application | Proposed |
| [ADR-0009](ADR-0009-flavor-configuration.md) | Flutter Flavor Configuration | Accepted |
| [ADR-0010](ADR-0010-parent-read-composition.md) | Parent-facing read composition | Accepted |
| [ADR-0011](ADR-0011-flutter-monorepo-consolidation.md) | Consolidate the Flutter/Dart clients into a single Melos-managed monorepo | Proposed |
| [ADR-0012](ADR-0012-admin-account-invitation-and-password-reset.md) | Administrative account invitations and self-service password reset | Accepted |
| [ADR-0013](ADR-0013-interim-client-bundled-flutter-localisation.md) | Interim client-bundled localisation for the Flutter apps (English/Kannada) | Accepted |

## Writing a new ADR

Copy [`TEMPLATE.md`](TEMPLATE.md), take the next number, and add a row above. Never edit an `Accepted` ADR to change its decision — supersede it.
