# DOCUMENT HIERARCHY

**Document tier:** 0 — Governance
**Status:** Active

This document is the map of the repository's documentation and the authority for resolving conflicts between documents.

---

## Authority Order

When two documents disagree, the one higher in this list wins. Always.

```
 1  INSTRUCTIONS.md
 2  PROJECT_CHARTER.md
 3  PRODUCT_PRINCIPLES.md  /  ENGINEERING_PRINCIPLES.md
 4  Architecture Decision Records (accepted)
 5  BUSINESS_RULES.md
 6  FEATURE_INVENTORY.md
 7  System Design
 8  Database
 9  API
10  UI
11  Development
12  Testing
13  Deployment
```

**Why this order.** Rules of intent (charter, principles, business rules) constrain rules of construction (design, database, API). A convenient API shape never justifies weakening a business rule; a database limitation never justifies changing what the product promises without amending the tier that made the promise.

---

## Conflict Procedure

1. Identify both documents and their tiers.
2. The higher tier is correct **by definition**; the lower document is defective.
3. Fix the lower document, or — if the higher document is genuinely wrong — raise an ADR to amend it. Never resolve a conflict by editing the lower document to disagree quietly.
4. Record the resolution where the next reader will find it.

**Never invent a requirement to resolve a conflict.** If neither document answers the question, the answer does not exist yet — ask.

---

## The Tiers

### Tier 0 — Governance (repository root and `documentation/00-governance/`)

| Document | Purpose |
|---|---|
| [`INSTRUCTIONS.md`](../INSTRUCTIONS.md) | Contribution protocol |
| [`PROJECT_CHARTER.md`](../PROJECT_CHARTER.md) | Mission, scope, non-goals, commitments |
| [`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) | Product trade-off resolution |
| [`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) | Code structure and standards |
| [`AI_MASTER_PROMPT.md`](../AI_MASTER_PROMPT.md) | AI contributor contract |
| [`DOCUMENT_HIERARCHY.md`](DOCUMENT_HIERARCHY.md) | This document |
| [`GLOSSARY.md`](GLOSSARY.md) | Canonical vocabulary |
| [`adr/`](adr/) | Architecture decision records |

### Tier 1 — Product Discovery (`documentation/01-product-discovery/`)

The origin tier. Everything below is derived from it.

[`STAKEHOLDERS.md`](../01-product-discovery/STAKEHOLDERS.md) · [`PERSONAS.md`](../01-product-discovery/PERSONAS.md) · [`MODULE_MAP.md`](../01-product-discovery/MODULE_MAP.md) · [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md) · [`BUSINESS_RULES.md`](../01-product-discovery/BUSINESS_RULES.md) · [`USER_JOURNEYS.md`](../01-product-discovery/USER_JOURNEYS.md) · [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md) · [`NOTIFICATION_CATALOG.md`](../01-product-discovery/NOTIFICATION_CATALOG.md)

### Tier 2 — System Design (`documentation/02-system-design/`)

[`ARCHITECTURE_OVERVIEW.md`](../02-system-design/ARCHITECTURE_OVERVIEW.md) · [`MULTI_TENANCY.md`](../02-system-design/MULTI_TENANCY.md) · [`SECURITY_ARCHITECTURE.md`](../02-system-design/SECURITY_ARCHITECTURE.md) · [`REALTIME_TRACKING_DESIGN.md`](../02-system-design/REALTIME_TRACKING_DESIGN.md) · [`NOTIFICATION_ARCHITECTURE.md`](../02-system-design/NOTIFICATION_ARCHITECTURE.md) · [`AUDIT_AND_LOGGING.md`](../02-system-design/AUDIT_AND_LOGGING.md) · [`INTEGRATION_ARCHITECTURE.md`](../02-system-design/INTEGRATION_ARCHITECTURE.md) · [`SCALABILITY.md`](../02-system-design/SCALABILITY.md)

### Tier 3 — Database (`documentation/03-database/`)

[`DATA_MODEL_OVERVIEW.md`](../03-database/DATA_MODEL_OVERVIEW.md) · [`ERD.md`](../03-database/ERD.md) · [`CONVENTIONS.md`](../03-database/CONVENTIONS.md) · [`RLS_POLICIES.md`](../03-database/RLS_POLICIES.md) · [`MIGRATION_STRATEGY.md`](../03-database/MIGRATION_STRATEGY.md) · [`INDEXING_AND_PARTITIONING.md`](../03-database/INDEXING_AND_PARTITIONING.md) · [`tables/`](../03-database/tables/)

### Tier 4 — API (`documentation/04-api/`)

[`API_STANDARDS.md`](../04-api/API_STANDARDS.md) · [`ERROR_CATALOG.md`](../04-api/ERROR_CATALOG.md) · [`AUTHENTICATION_API.md`](../04-api/AUTHENTICATION_API.md) · plus one document per module.

### Tier 5 — UI (`documentation/05-ui/`)

[`DESIGN_SYSTEM.md`](../05-ui/DESIGN_SYSTEM.md) · [`SCREEN_INVENTORY.md`](../05-ui/SCREEN_INVENTORY.md) · [`PARENT_APP.md`](../05-ui/PARENT_APP.md) · [`DRIVER_ATTENDANT_APP.md`](../05-ui/DRIVER_ATTENDANT_APP.md) · [`ADMIN_WEB.md`](../05-ui/ADMIN_WEB.md) · [`ACCESSIBILITY.md`](../05-ui/ACCESSIBILITY.md)

### Tier 6 — Development (`documentation/06-development/`)

[`PROJECT_STRUCTURE.md`](../06-development/PROJECT_STRUCTURE.md) · [`CODING_STANDARDS_BACKEND.md`](../06-development/CODING_STANDARDS_BACKEND.md) · [`CODING_STANDARDS_FLUTTER.md`](../06-development/CODING_STANDARDS_FLUTTER.md) · [`ARCHITECTURE_ENFORCEMENT.md`](../06-development/ARCHITECTURE_ENFORCEMENT.md) · [`GIT_WORKFLOW.md`](../06-development/GIT_WORKFLOW.md) · [`LOCAL_SETUP.md`](../06-development/LOCAL_SETUP.md) · [`DEFINITION_OF_DONE.md`](../06-development/DEFINITION_OF_DONE.md)

### Tier 7 — Testing (`documentation/07-testing/`)

[`TEST_STRATEGY.md`](../07-testing/TEST_STRATEGY.md) · [`SAFETY_CRITICAL_TEST_MATRIX.md`](../07-testing/SAFETY_CRITICAL_TEST_MATRIX.md) · [`TEST_CASES.md`](../07-testing/TEST_CASES.md)

### Tier 8 — Deployment (`documentation/08-deployment/`)

[`ENVIRONMENTS.md`](../08-deployment/ENVIRONMENTS.md) · [`CI_CD.md`](../08-deployment/CI_CD.md) · [`OBSERVABILITY.md`](../08-deployment/OBSERVABILITY.md) · [`BACKUP_AND_DR.md`](../08-deployment/BACKUP_AND_DR.md)

---

## Traceability Model

Identifiers connect the tiers. This is what makes the hierarchy real rather than decorative.

| ID form | Defined in | Referenced by |
|---|---|---|
| `MOD-xx` | `MODULE_MAP.md` | Feature inventory, package names |
| `TRK-001` (feature) | `FEATURE_INVENTORY.md` | API docs, UI docs, test cases |
| `BR-BOARD-004` (business rule) | `BUSINESS_RULES.md` | Code comments, tests, API docs |
| `PERM-TRIP-VIEW` | `PERMISSION_MATRIX.md` | API docs, security config |
| `NTF-BOARD-01` | `NOTIFICATION_CATALOG.md` | Notification templates, API docs |
| `ADR-0001` | `adr/` | Any document affected by the decision |

**Invariants**, verified in CI:

1. Every feature ID appears in at least one API document and one test case.
2. Every business rule ID has at least one test referencing it.
3. Every endpoint declares a permission ID that exists in the permission matrix.
4. No document links to a path that does not exist.

---

## Adding a Document

1. Place it in the correct tier directory.
2. Add it to the tier listing above.
3. Add a header block: tier, status, and what it settles.
4. If it introduces an architectural decision, write an ADR instead of embedding the decision in prose.

## Document Status Values

| Status | Meaning |
|---|---|
| `Draft` | Being written; not authoritative |
| `Active` | Authoritative |
| `Superseded by X` | Historical; read X |
| `Deprecated` | No longer applies; retained for history |
