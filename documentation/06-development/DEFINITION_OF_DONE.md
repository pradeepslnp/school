# DEFINITION OF DONE

**Document tier:** 6 — Development
**Status:** Active
**Implements:** [`INSTRUCTIONS.md`](../INSTRUCTIONS.md) STEP 6

A change is done when **every** item applies or is explicitly marked not applicable with a reason. Partial completion is not done — it is a change that has not landed.

---

## 1. Business Rules

- [ ] Every rule implemented cites its ID in code (`/** BR-SAFE-001: … */`)
- [ ] No rule invented — if it was not written down, it was added to [`BUSINESS_RULES.md`](../01-product-discovery/BUSINESS_RULES.md) first
- [ ] Rule conflicts resolved by document hierarchy, not by preference
- [ ] 🔴 changes carry an ADR and a stated preserved safety property

## 2. Validation

- [ ] Input validated at the boundary; client-supplied identifiers never trusted
- [ ] All field errors returned together, not one per submission
- [ ] Domain invariants enforced in the domain, **and** in the schema where SQL can express them
- [ ] Documented deviations where SQL cannot (cross-row rules) have a covering test

## 3. Authorization

- [ ] Endpoint declares a permission from [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md)
- [ ] **Object-level scope checked**, not just endpoint permission
- [ ] Cross-scope returns `403`; cross-tenant returns `404`
- [ ] Guardian access limited to own children (BR-IAM-005)
- [ ] Deny-by-default holds — no new path bypasses the check

## 4. Tenant Isolation 🔴

- [ ] New tables carry `tenant_id` and **forced** RLS in the same migration
- [ ] Policy declares both `USING` and `WITH CHECK`
- [ ] Indexes lead with `tenant_id`
- [ ] Tenant context set with `SET LOCAL`, never `SET`
- [ ] Cross-tenant isolation test present for new repositories

## 5. Error Handling

- [ ] Typed domain exceptions carrying error codes — no strings, no booleans
- [ ] Every code exists in [`ERROR_CATALOG.md`](../04-api/ERROR_CATALOG.md) with a localisation key
- [ ] No internal detail leaked to clients
- [ ] Nothing swallowed; nothing logged-and-rethrown at multiple layers

## 6. Logging

- [ ] Structured, with correlation ID and tenant ID
- [ ] **No child names, credentials, tokens, or contact details** — students appear as IDs
- [ ] Logged at the decision boundary, not every layer

## 7. Audit Trail 🔴

- [ ] Safety-relevant changes write an audit record
- [ ] **Audit write shares the transaction** (BR-AUD-002)
- [ ] Overrides carry a required, non-empty reason (BR-AUD-004)
- [ ] Child-data reads by non-guardians produce data-access records (BR-IAM-012)
- [ ] Exports record actor, scope, and record count (BR-RPT-002)

## 8. Performance

- [ ] Every query bounded — time range, limit, or both
- [ ] Supporting index exists; plan verified for hot paths
- [ ] No N+1 queries
- [ ] **No outbound call inside a transaction**
- [ ] Position-history queries prune by partition
- [ ] Budgets in [`REALTIME_TRACKING_DESIGN.md`](../02-system-design/REALTIME_TRACKING_DESIGN.md) hold for affected paths

## 9. Security

- [ ] No secrets in source; configuration from environment
- [ ] Parameterised queries only
- [ ] Uploads type- and size-checked; served through authorising endpoints
- [ ] Rate limits considered for new public endpoints
- [ ] Dependency scan clean above threshold
- [ ] `/security-review` run for changes touching auth, tenancy, or child data

## 10. Scalability

- [ ] Behaviour understood at reference scale ([`SCALABILITY.md`](../02-system-design/SCALABILITY.md))
- [ ] No per-tenant work that grows unbounded with tenant count
- [ ] Batch and scheduled work is chunked, idempotent, and safe to run concurrently
- [ ] One tenant cannot degrade another

## 11. Testing

- [ ] Unit tests for domain rules, no Spring context
- [ ] Integration tests for repositories, via Testcontainers
- [ ] **Every business rule ID has ≥1 test referencing it** (`@BusinessRule`)
- [ ] Error and edge cases covered, not only the happy path
- [ ] Architecture tests pass
- [ ] ~~Flutter: unit, widget, and golden tests; empty/loading/error states tested~~ — **paused — see [INSTRUCTIONS.md](../INSTRUCTIONS.md#current-exception--flutter-tests)**. Existing Flutter tests must still pass and `flutter analyze` must be clean; `guardian_core` remains tested.
- [ ] Offline path tested for driver-app changes (ADR-0008) — *still required once the driver app consumes real endpoints; the pause does not cover safety-critical screens*
- [ ] Critical journeys in [`SAFETY_CRITICAL_TEST_MATRIX.md`](../07-testing/SAFETY_CRITICAL_TEST_MATRIX.md) still pass

## 12. Accessibility (UI changes)

- [ ] Contrast, target size, and text scaling meet [`ACCESSIBILITY.md`](../05-ui/ACCESSIBILITY.md)
- [ ] Semantics on custom components
- [ ] Keyboard operable (admin web)
- [ ] Works at 200% text scale and in RTL
- [ ] Colour is never the only signal

## 13. Localisation

- [ ] **No user-facing string literal anywhere** (BR-CFG-005)
- [ ] Keys added for every supported locale
- [ ] Layout tolerates ±40% string length
- [ ] Times render in the school's timezone (BR-CFG-006)
- [ ] Region-specific behaviour is configuration, not a code branch (ADR-0007)

## 14. Documentation

- [ ] Updated **in the same PR**
- [ ] Feature ID in [`FEATURE_INVENTORY.md`](../01-product-discovery/FEATURE_INVENTORY.md)
- [ ] API document updated; new errors catalogued
- [ ] Table specifications updated for schema changes
- [ ] Screen inventory updated for UI changes
- [ ] ADR written for architectural decisions
- [ ] No documentation link points at a missing path

## 15. Code Quality

- [ ] Spotless and static analysis clean
- [ ] No commented-out code
- [ ] No `TODO` without a linked issue
- [ ] **No placeholder or pseudo-production code** ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §15)
- [ ] Comments explain *why*
- [ ] Constructor injection; no field injection; no static mutable state

---

## Safety-Critical Changes 🔴

Additionally required for anything touching a 🔴 rule:

- [ ] **Two approvals**, one from someone who did not pair on the change
- [ ] Explicit statement of the safety property preserved
- [ ] Tests referencing every affected rule ID
- [ ] ADR if the control itself changes
- [ ] Safety-critical test matrix re-run in full
- [ ] Failure behaviour considered: what happens offline, on provider failure, on database loss

---

## Not Done

State it plainly rather than merging something incomplete:

> "Handover override notification is implemented; the SMS fallback path is not — tracked as #412. The override itself is blocked from completing if no channel succeeds, so no child is released without a notification attempt."

**Documented incompleteness is acceptable. Silent incompleteness is not.** In a safety system, the gap someone knows about is manageable; the gap nobody knows about is how incidents happen.
