# ADR-0006: JWT access/refresh tokens with tenant-scoped RBAC

**Status:** Proposed
**Date:** 2026-08-03
**Affects:** identity module, all APIs, [`SECURITY_ARCHITECTURE.md`](../../02-system-design/SECURITY_ARCHITECTURE.md), [`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md)

## Context

Four client types authenticate: parent app, driver app, admin web, and GPS devices. Their needs differ:

- Parents: long-lived sessions on personal phones; losing a session mid-emergency is unacceptable.
- Drivers: shared or semi-shared devices; sessions must be revocable immediately when a driver leaves employment.
- Admin web: browser session, higher privilege, shorter tolerance for stale credentials.
- Devices: machine credentials, no human, rotated rarely.

Authorisation must resolve **within tenant scope** and at the correct level of [ADR-0002](ADR-0002-tenant-hierarchy.md)'s hierarchy. A guardian's rights are further narrowed to their own children.

The hard requirement: **revocation must be prompt.** A dismissed driver retaining access to student data until a token expires is a safety problem, and this is the standard weakness of stateless JWT.

## Decision

**Short-lived JWT access tokens plus opaque, server-stored refresh tokens.**

- **Access token:** JWT, 15-minute lifetime, signed asymmetrically (RS256). Carries `sub`, `tenant_id` (organization), `scope` level, and a `session_id`. It does **not** carry the full permission set — permissions are resolved server-side per request from the session, so a permission change takes effect on the next request rather than the next token.
- **Refresh token:** opaque, random, stored server-side, rotated on every use with reuse detection. Revoking a session deletes the stored refresh token.
- **Revocation:** immediate for refresh; bounded by 15 minutes for access. A `session_id` denylist, checked against a cache, closes even that window for high-severity revocation (dismissal, compromise).
- **Devices:** separate credential type, mutual-TLS or signed device tokens, never the human auth path.
- **Tenant binding:** `tenant_id` in the token seeds the RLS session variable ([ADR-0001](ADR-0001-multi-tenancy-strategy.md)). A token can only ever address its own tenant.
- **Guardian scope:** guardians are restricted to their own children by a scope predicate applied in the application layer above RLS.
- Deny by default — an endpoint without an explicit permission declaration fails closed.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Server-side sessions only | Simplest revocation story and genuinely a strong option. Rejected because mobile clients and horizontal scaling favour bearer tokens, and the hybrid above recovers most of the revocation benefit. |
| Long-lived JWT with permissions embedded | Fewer lookups per request. Rejected outright: permission and revocation changes would not take effect until expiry — unacceptable for a system holding child data. |
| Third-party IdP (Auth0/Cognito/Keycloak) | Real operational savings and worth revisiting. Rejected for now because per-tenant guardian identity (often phone-number based, high volume, low value per identity) fits awkwardly into per-MAU IdP pricing, and school SSO requirements are not yet known. |
| API keys for mobile clients | Not an authentication mechanism for humans; no session semantics, no revocation granularity. |

## Consequences

**Positive**
- Revocation is prompt: immediate for refresh, ≤15 minutes for access, immediate with denylist.
- Permission changes take effect on the next request.
- Tenant isolation is carried in the credential and cannot be overridden by a client.

**Negative / accepted cost**
- Per-request permission resolution costs a lookup. Mitigated by a short-TTL cache keyed on session, invalidated on role change.
- Refresh-token storage and rotation is state to operate.
- Key rotation for RS256 requires a JWKS endpoint and overlap handling.

**Neutral**
- School SSO (SAML/OIDC) for staff is not addressed here; it would be an additional authentication method producing the same session, and needs its own ADR when required.

## Reversal Cost

**Moderate.** Clients depend on the token exchange shape. Adopting an external IdP later is feasible because permission resolution is already server-side and not embedded in tokens.

## Verification

1. A test asserts a revoked session's access token is rejected within the denylist window.
2. A test asserts a permission removed from a role takes effect on the next request without re-issuing a token.
3. A test asserts refresh-token reuse triggers detection and invalidates the whole session family.
4. A test asserts a token bearing tenant A cannot read tenant B data even with a valid, correctly-signed token.
5. A test asserts a guardian cannot read a student they are not linked to, within their own tenant.
6. An architecture test asserts every endpoint declares a permission from [`PERMISSION_MATRIX.md`](../../01-product-discovery/PERMISSION_MATRIX.md).
