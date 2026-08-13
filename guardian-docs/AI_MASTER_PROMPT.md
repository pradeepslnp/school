# AI MASTER PROMPT

**Document tier:** 0 — Governance
**Priority:** 3
**Audience:** AI contributors (and the humans reviewing their output)

---

## Operating Contract

You are contributing to a long-term, multi-tenant, safety-critical enterprise platform. Optimise for the engineer who reads this code in three years, not for the speed of this response.

### Before you answer

1. Read [`INSTRUCTIONS.md`](INSTRUCTIONS.md). It outranks this document.
2. Locate the relevant documents for the module in question. Do not answer from memory of a previous conversation.
3. If a required document does not exist, say so and recommend creating it. Do not fill the gap with an invention.

### Non-negotiable rules

| Rule | Detail |
|---|---|
| Never invent requirements | If a business rule is not written down, ask. A plausible guess in a safety system is a defect. |
| Never contradict a higher-tier document | Escalate the conflict instead; propose an amendment. |
| Never place business logic in UI | See [`ENGINEERING_PRINCIPLES.md`](ENGINEERING_PRINCIPLES.md) §8. |
| Never bypass tenant scope | Any query crossing tenants requires an explicit, permission-gated, audited path. |
| Never produce placeholder code | No stubs, no `throw new UnsupportedOperationException()` left behind, no fake data paths. |
| Never silently redesign | Extending an existing module is the default; redesign requires an ADR. |

### Required output structure

`INSTRUCTIONS.md` STEP 0 sizes every request into Trivial / Standard / Architectural before anything else happens. The structure below is the default for **Standard and Architectural** tier only.

For a Standard or Architectural development request:

1. **Requirement Summary** — restate what is being asked, including what you inferred
2. **Documents Referenced** — actual paths you read
3. **Business Rules Applied** — by ID (`BR-BOARD-004`)
4. **Proposed Solution** — approach and rationale
5. **Impact Analysis** — business · database · API · UI · security · testing
6. **Implementation** — complete, production-quality code
7. **Test Cases** — mapped to business rule IDs
8. **Future Considerations** — what this defers, and documents needing update

Omit sections only when the user explicitly asks for code alone.

For a **Trivial** request (typo, one-file bug fix, config/copy change — see `INSTRUCTIONS.md` STEP 0): skip this structure. Make the fix, and give a one- or two-line explanation of what changed and why. Do not manufacture Impact Analysis or Future Considerations sections for a one-line change — that ceremony is the over-engineering failure mode STEP 0 exists to prevent.

### Traceability

Feature IDs (`TRK-003`) and business rule IDs (`BR-TRIP-011`) are the connective tissue of this repository. When you add a feature, add its ID to [`FEATURE_INVENTORY.md`](01-product-discovery/FEATURE_INVENTORY.md) and reference that ID in the API document, the database document, the UI document, and the tests. A feature that appears in code but not in the inventory is untracked work.

### When you are uncertain

State the uncertainty explicitly, proceed with everything that does not depend on it, and ask a specific question about the part that does. Do not block an entire deliverable on one open question, and do not resolve a safety-relevant ambiguity by guessing.

### Documentation obligation

Every change that introduces a business rule, feature, module, or architectural decision must name:

- the document to update,
- any new document required,
- other documents affected.

Documentation is the source of truth. Code that disagrees with documentation is a bug in one of the two — say which.
