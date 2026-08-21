# ADR-0007: Region-specific behaviour as configuration

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** configuration module, fleet module, notification module, identity module

## Context

[`PRODUCT_PRINCIPLES.md`](../../PRODUCT_PRINCIPLES.md) §5 sets an explicit test: *if a new customer in a new country requires a code change to onboard, the design has failed.*

Things that genuinely vary by country and would otherwise leak into code:

| Concern | Variation |
|---|---|
| Phone number format | Length, country code, validation rules |
| SMS regulation | Sender ID registration, template pre-approval, opt-out handling |
| Vehicle documents | Which documents exist and are mandatory, and their renewal cadence |
| Driver credentials | Licence classes, background-check types, medical certification |
| Address format | Field order, postal code presence and shape |
| Date, time, number formats | Display and parsing |
| Time zone | Per school, not per platform |
| Language | Per user, with multiple languages inside one tenant |
| Emergency contacts | Which authority is called, and when |
| Data retention | Legally mandated minimum and maximum periods |

The temptation is a `if (country == "IN")` branch. That branch multiplies.

## Decision

**No country, currency, document type, or credential type is hardcoded. All are reference data or tenant configuration.**

Structure:

1. **Platform reference data** — countries, locales, time zones, phone rules. Seeded, versioned, extensible by migration without code change.
2. **Region profiles** — a named bundle of defaults (required vehicle document types, driver credential types, address format, retention defaults). Onboarding a country means adding a region profile row, not a branch.
3. **Tenant configuration** — a typed, validated, per-organization key/value store with defaults inherited from the region profile and overridable per school where meaningful. Includes alert thresholds, notification channels, handover verification methods, and quiet hours.
4. **Localisation** — all user-facing strings are resource keys. No string destined for a user is written inline in code. Templates carry locale variants.
5. **Time** — stored in UTC; displayed in the school's time zone. A school's time zone is data.

Configuration is **typed and schema-validated**, not free-form strings: each key declares a type, permitted range, default, and the scope level at which it may be set.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Hardcode the first market, generalise later | Fastest initial delivery, and the most common failure mode. Rejected: retrofitting configurability across fleet, identity, and notification modules after they are built costs far more than building it once. Directly violates §5. |
| Per-country code modules loaded by strategy | Genuinely appropriate for complex *behavioural* variation, but most of the list above is data, not behaviour. Reserve strategies for the rare true behaviour differences. |
| Untyped JSON configuration blob | Flexible and cheap. Rejected: no validation means misconfiguration surfaces at runtime in a safety system. Typed keys with declared ranges catch it at write time. |

## Consequences

**Positive**
- A new country is onboarded by adding a region profile and templates.
- Tenant-specific policy differences need no deployment.
- Configuration changes are auditable like any other data change.

**Negative / accepted cost**
- More upfront work than hardcoding; the configuration module is real scope with an admin surface.
- Defaults must be chosen carefully — a bad default silently becomes many tenants' behaviour.
- Every configurable value is a value that can be misconfigured. Mitigated by typing, ranges, and a review of safety-relevant configuration changes.

**Neutral**
- Safety-critical behaviour is deliberately **not** fully configurable. A tenant may configure *which* handover verification methods are acceptable, but may not configure handover verification away entirely — see `BR-HAND-001`. Child Safety First outranks Configuration over Hardcoding.

## Reversal Cost

**Not applicable in the reversing direction** — this decision only ever removes hardcoding. The risk is failing to apply it consistently.

## Verification

1. A test asserts no user-facing string literal is returned from a controller or domain class (resource keys only).
2. A test asserts every configuration key has a declared type, default, and scope level.
3. An onboarding test creates a tenant under a second, different region profile and asserts phone validation, required vehicle documents, and date formatting all follow that profile without a code path selecting on country.
4. A test asserts safety-critical minimums cannot be configured below their floor.
