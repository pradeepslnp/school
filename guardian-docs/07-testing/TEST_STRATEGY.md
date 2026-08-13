# TEST STRATEGY

**Document tier:** 7 — Testing
**Status:** Active

---

## What Tests Are For Here

In most systems tests prevent regressions. In this one they additionally **prove that safety controls exist**.

[`DOCUMENT_HIERARCHY.md`](../00-governance/DOCUMENT_HIERARCHY.md) invariant 2: **every business rule ID has at least one test referencing it.** A rule with no test is a rule that is documented but not enforced — and in a safety system that is worse than an undocumented rule, because it creates false confidence.

---

## The Pyramid

```
        ╱ E2E ╲            critical journeys only — J1…J8
      ╱─────────╲
    ╱  Contract   ╲        API shape vs documented contract
  ╱─────────────────╲
 ╱   Integration     ╲     repositories + RLS, via Testcontainers
╱───────────────────────╲
      Unit               domain rules, no framework
```

| Level | Runs in | Scope |
|---|---|---|
| Unit | milliseconds | Domain entities, value objects, domain services. **No Spring context.** |
| Integration | seconds | Repositories against real PostgreSQL, including RLS |
| Contract | seconds | Request/response shape vs documented API |
| E2E | minutes | The eight user journeys, end to end |
| Architecture | seconds | Layering, boundaries, security invariants |

E2E is deliberately thin. Slow, brittle E2E suites get skipped, and a skipped safety test is no test.

---

## Business Rule Traceability

```java
@BusinessRule("BR-SAFE-001")
@Test
void trip_cannot_close_while_a_student_is_unaccounted() {
    var trip = tripWithBoardedStudentAndNoAlight();

    assertThatThrownBy(() -> closeTripUseCase.execute(trip.id()))
        .isInstanceOf(ReconciliationIncompleteException.class)
        .hasFieldOrPropertyWithValue("errorCode", ErrorCode.TRIP_RECONCILIATION_INCOMPLETE);
}
```

The `@BusinessRule` annotation makes references machine-readable. A CI check parses [`BUSINESS_RULES.md`](../01-product-discovery/BUSINESS_RULES.md), collects every annotation, and **fails the build on any rule with no test**.

🔴 rules require tests at **two levels** — unit for the decision, integration or E2E for the enforcement. A rule enforced only in a use case can be bypassed by a future code path; a rule enforced in the schema cannot.

---

## Unit Tests

Domain only. No Spring, no database, no mocks of things you own.

```java
@BusinessRule("BR-GRD-002")
@Test
void student_must_retain_at_least_one_handover_capable_guardian() { … }
```

Test **behaviour, not implementation**. A test asserting a method was called on a mock breaks on refactoring while proving nothing about correctness.

Mock only at ports — repositories, notification channels, clocks. Never mock a domain object.

**Time is injected**, never `Instant.now()` in domain code. Clock-dependent rules — credential expiry, quiet hours, pickup-person validity — are otherwise untestable at boundaries.

---

## Integration Tests

Testcontainers PostgreSQL, real schema, real migrations, real RLS.

**Never against a shared database.** These tests create and drop schemas.

### Every module has a tenant-isolation test 🔴

```java
@BusinessRule("BR-TEN-004")
@Test
void data_written_under_one_tenant_is_invisible_to_another() {
    withTenant(TENANT_A, () -> studentRepository.save(aStudent()));

    var found = withTenant(TENANT_B, () -> studentRepository.findAll());

    assertThat(found).isEmpty();   // zero rows — not an exception
}
```

Zero rows, not an error, is the correct outcome. It is what makes a forgotten `WHERE` clause safe ([`MULTI_TENANCY.md`](../02-system-design/MULTI_TENANCY.md)).

### Schema invariants, verified against the live database

- Every `tenant_id` table has RLS **enabled and forced**
- Every policy declares `USING` **and** `WITH CHECK`
- `guardian_app` lacks `BYPASSRLS` and owns no tables
- Append-only tables reject `UPDATE` and `DELETE`
- Constraints reject: override without reason, handover without receiver, resolution without actor
- Two sequential transactions on one pooled connection do not leak tenant context

That last one deserves its own test: it is the failure mode `SET` versus `SET LOCAL` produces, and it is silent.

---

## Contract Tests

Assert the API matches its documentation:

- Every endpoint declares a permission that exists in [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md)
- Every error code returned exists in [`ERROR_CATALOG.md`](../04-api/ERROR_CATALOG.md)
- Response envelopes conform to [`API_STANDARDS.md`](../04-api/API_STANDARDS.md)
- All timestamps are UTC with `Z`
- Generated OpenAPI matches the documented contract

Per-role authorisation tests assert every **denied** cell in the permission matrix actually returns `403` — the matrix is otherwise a description of intent rather than of behaviour.

---

## End-to-End Tests

The eight journeys in [`USER_JOURNEYS.md`](../01-product-discovery/USER_JOURNEYS.md), run against a full stack.

| Journey | Asserts |
|---|---|
| J1 Morning pickup | Manifest, boarding, notifications, reconciliation |
| J2 **Handover** 🔴 | Every branch: verified, pickup person, restriction, override, no receiver |
| J3 **Left-behind** 🔴 | Detection, critical alert, close blocked until resolved |
| J4 SOS escalation | Delivery bypassing preferences; escalation until acknowledged |
| J5 Absence | Manifest exclusion; late absence as amendment |
| J6 Route deviation | Sustained-condition detection; single alert |
| J7 Onboarding | Import with errors; guardian rights preconditions |
| J8 Compliance | Expiry blocks new trips; in-progress trip continues |

J2 and J3 are the reason the platform exists. Every branch of both is covered, including the refusal paths that create no record but must leave a trace.

---

## Offline Testing (ADR-0008)

The driver app's offline behaviour needs deliberate testing because its failures are invisible until they matter:

1. Full trip recorded with the network disabled
2. App killed mid-trip; queue survives restart
3. Reconnect — every event syncs **exactly once**
4. Replayed `clientEventId` creates no duplicate
5. Device clock skewed by hours — skew measured and stored, record still accepted
6. Client action contradicting server state is **flagged, not discarded** (BR-SAFE-005)
7. Logout wipes the encrypted local store

---

## Flutter Tests

| Level | Scope |
|---|---|
| Unit | Domain and state notifiers, no widgets |
| Widget | Screens including **empty, loading, and error** states |
| Golden | Key screens: light/dark, LTR/RTL, 100%/200% text |
| Integration | Critical journeys including the offline trip |

An untested error state becomes a blank screen in production.

---

## Test Data

- **Never real child or guardian data**, including in fixtures ([`GIT_WORKFLOW.md`](../06-development/GIT_WORKFLOW.md)).
- Builders with sensible defaults; tests override only what they assert on.
- **Two region profiles in every fixture set** — so region-specific behaviour leaking into code fails a test rather than a customer (ADR-0007).
- Each test creates its own tenant. Tests never share state and run in any order.

---

## Coverage

| Area | Expectation |
|---|---|
| Domain | High — this is where rules live |
| Application | High |
| Infrastructure adapters | Covered by integration tests |
| Controllers | Covered by contract tests |
| **Every 🔴 rule** | **100%, at two levels** |

A coverage percentage is a weak signal. **The traceability check is the real gate**: every business rule has a test, and every 🔴 rule has two.

---

## CI

| Stage | Runs on |
|---|---|
| Unit + architecture | Every push |
| Integration + contract | Every PR |
| E2E | Every PR to `main` |
| Safety-critical matrix | Every PR touching a 🔴 rule; nightly |
| Load | Nightly, and before release |
| Accessibility | Every PR touching UI |

**Flaky tests are fixed or deleted, never retried.** A retried test is a test whose result nobody believes — and in this suite, the ones that matter must be believed.
