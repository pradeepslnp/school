# SECURITY ARCHITECTURE

**Document tier:** 2 — System Design
**Status:** Active
**Implements:** ADR-0001, ADR-0006 · **Enforces:** BR-IAM-*, BR-TEN-004, BR-AUD-*

The platform holds location and identity data for children. The threat that matters most is not financial fraud — it is **an adult obtaining a specific child's location or collecting a child they have no right to**.

---

## Threat Model

| Threat | Control |
|---|---|
| Cross-tenant data access | RLS at the database layer (ADR-0001, [`MULTI_TENANCY.md`](MULTI_TENANCY.md)) |
| Guardian accessing another family's child | Scope predicate `OWN_CHILDREN` + data-access audit (BR-IAM-005, BR-IAM-012) |
| Dismissed staff retaining access | Immediate session revocation + denylist (BR-IAM-008, ADR-0006) |
| Unauthorised adult collecting a child | Handover verification, never disableable (BR-HAND-001) 🔴 |
| Restricted guardian collecting a child | Custody restriction blocks and escalates (BR-GRD-008, BR-HAND-006) 🔴 |
| Stolen driver device | Encrypted local store, remote-revocable, wiped on logout (ADR-0008) |
| Position spoofing | Device credentials + plausibility validation (BR-TRACK-004, BR-FLEET-006) |
| Credential stuffing | Rate limiting, lockout, anomaly alerting (BR-IAM-011) |
| Token theft | 15-minute access tokens, rotating single-use refresh, reuse detection (BR-IAM-009) |
| Insider misuse by school staff | Scope limits + every child-data read audited (BR-IAM-012) |
| Insider misuse by platform operator | Justified, time-boxed, fully audited elevation (BR-TEN-004) |
| Bulk exfiltration via export | Permission-gated, audited with record counts (BR-RPT-002) |

---

## Authentication

Per ADR-0006.

| Client | Method | Session |
|---|---|---|
| Staff | Password + optional second factor | 15-min access, rotating refresh |
| Guardian | Phone + OTP | Longer refresh — losing a session mid-emergency is itself a safety problem |
| Admin web | Password + second factor | Shorter refresh, higher privilege |
| GPS device | Device credential, mutual TLS where supported | Long-lived, rotatable, never the human path |

**Password storage:** Argon2id. **Token signing:** RS256 with rotating keys published at a JWKS endpoint. **OTP:** short-lived, single-use, rate-limited per number and per source.

### Why permissions are not in the token

An embedded permission set is stale the moment a role changes. In a system where "revoke this person's access to children's data" must take effect now, that is unacceptable. Permissions are resolved per request from a short-TTL cache invalidated on role change (BR-IAM-004).

---

## Authorisation

Two independent checks, both required:

```
Permission   PERM-STUDENT-VIEW held?          → else 403
     ×
Scope        is THIS student within scope?    → else 403 (never 404-vs-403 leakage)
```

Deny by default (BR-IAM-002): an endpoint with no declared permission is unreachable, verified by an architecture test.

**Object-level checks are mandatory.** Holding `PERM-STUDENT-VIEW` never implies access to a specific student — the commonest real-world API vulnerability class, and the reason scope is checked per object rather than per endpoint.

---

## Child Data Protection

### Minimisation
Children are not individually tracked. Their location is inferred from the **vehicle's** position during a trip they boarded. There is no per-child GPS.

### Classification

| Class | Examples | Handling |
|---|---|---|
| **Sensitive child data** | Name, photo, stop, journey history | Encrypted at rest; access audited; strict scope |
| **Contact data** | Guardian phone, email | Encrypted at rest; visible only where operationally required |
| **Operational data** | Vehicle position, trip state | Standard protection |
| **Reference data** | Countries, document types | Public within the platform |

### Access logging
Every read of child personal data by a non-guardian is recorded (BR-IAM-012): actor, subject, time, purpose. This is what makes insider misuse detectable rather than merely prohibited.

### In transit and at rest
TLS 1.2+ everywhere, including device ingestion. Database encrypted at rest; sensitive columns additionally encrypted at the application layer. Backups encrypted. Device local stores encrypted (ADR-0008).

### Retention
Configured per tenant within the region profile's legal bounds (ADR-0007, BR-TRACK-007, BR-AUD-007). Position history is dropped by partition. Safety and audit records are retained for their full period and are never soft-deleted early (BR-AUD-001).

---

## Secrets

Sourced from the environment or a secret manager — **never from source control**. Per-tenant provider credentials (SMS, push) are encrypted at rest with a platform key and are never returned by any API, including to the tenant that set them. Rotation is supported without redeployment.

---

## Input Handling

Validate at the boundary; never trust a client-supplied identifier. All persistence through parameterised queries. Output encoding on every rendered surface. Notification content is template-rendered with escaping (BR-NTF-008). Uploads (student photos, documents) are type- and size-checked, stored outside the web root, and served through an authorising endpoint.

---

## API Protection

Rate limiting per user, per IP, and per tenant. Stricter limits on authentication and OTP endpoints. Ingestion limited per device — one device cannot flood the pipeline. Request size limits. CORS restricted to known client origins. Standard security headers.

---

## Logging Discipline

Logs carry correlation ID and tenant ID and are structured JSON.

**Never logged:** passwords, tokens, OTPs, provider credentials, full child records. Student identifiers appear as IDs, not names. Verified by a test that scans log output for known-sensitive field names.

---

## Mobile Client Security

| Concern | Control |
|---|---|
| Local safety data | Encrypted store, key in platform keystore (ADR-0008) |
| Session revocation | Remote revocation wipes local data on next contact |
| Logout | Local store cleared |
| Transport | Certificate pinning on both mobile apps |
| Shared driver devices | Short foreground session; explicit end-of-shift logout |
| Screenshots | Suppressed on screens showing child personal data |

---

## Incident Response

1. **Detect** — anomaly alerts on failed auth, unusual export volume, cross-tenant attempts, refresh-token reuse.
2. **Contain** — revoke sessions, suspend accounts, disable an integration.
3. **Investigate** — audit trail is append-only and complete (BR-AUD-001).
4. **Notify** — per the region profile's breach obligations.
5. **Remediate** — fix, then add the regression test.

A suspected compromise of a **guardian relationship or handover control** is treated as a child-safety incident, not merely a data incident, and escalates on the safety path.

---

## Verification

| # | Test |
|---|---|
| 1 | Every endpoint declares a permission from [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md). |
| 2 | Object-level scope enforced: a guardian requesting another family's student receives `403`. |
| 3 | Cross-tenant request with a valid token returns no data (see [`MULTI_TENANCY.md`](MULTI_TENANCY.md)). |
| 4 | Revoked session rejected within the denylist window. |
| 5 | Refresh-token reuse invalidates the session family and raises an alert. |
| 6 | Role change takes effect on the next request without re-issuing a token. |
| 7 | Log output contains no field from the sensitive-field denylist. |
| 8 | Every child-data read by a non-guardian produces an audit record. |
| 9 | Every export produces an audit record with actor, scope, and record count. |
| 10 | Dependency and container scanning in CI; findings above threshold fail the build. |

A security review runs against this document before each release — see [`/security-review`](../06-development/DEFINITION_OF_DONE.md).
