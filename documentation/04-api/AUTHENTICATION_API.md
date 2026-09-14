# AUTHENTICATION API

**Document tier:** 4 — API
**Implements:** ADR-0006 · **Features:** IAM-001 … IAM-004, IAM-009 · **Rules:** BR-IAM-*

Base path `/api/v1/auth`. These endpoints are **unauthenticated** except where noted, and are the most heavily rate-limited in the platform.

---

## `POST /auth/login` — Staff login

**Feature:** IAM-001 · **Permission:** none (public) · **Rules:** BR-IAM-001, BR-IAM-011

```json
{ "email": "anil@school.example", "password": "…", "clientType": "ADMIN_WEB" }
```

**`200`**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiIs…",
    "refreshToken": "opaque-random-string",
    "expiresIn": 900,
    "tokenType": "Bearer",
    "user": {
      "id": "…", "organizationId": "…", "firstName": "Anil", "lastName": "Kumar",
      "preferredLocale": "en-IN",
      "roles": ["TRANSPORT_MANAGER"],
      "scopes": [{ "level": "SCHOOL", "refId": "…" }]
    }
  }
}
```

`roles`, `scopes`, and `organizationId` are returned **for UI affordances only**. They are never trusted for authorisation — every request re-resolves permissions server-side (BR-IAM-001, BR-IAM-004).

`organizationId` is the organization the account belongs to, which is not the same as an `ORG` scope: a `SUPER_ADMIN` holds no organization scope but still belongs to the platform organization. The admin console uses it to withhold Suspend on the operator's own organization (BR-TEN-006).

**Errors:** `AUTH_CREDENTIALS_INVALID` (401) · `AUTH_ACCOUNT_LOCKED` (401) · `RATE_LIMIT_EXCEEDED` (429)

`AUTH_CREDENTIALS_INVALID` is returned for both an unknown email and a wrong password — distinguishing them would enumerate accounts.

---

## `POST /auth/otp/request` — Guardian OTP request

**Feature:** IAM-002 · **Rules:** BR-IAM-011

```json
{ "phone": "+919876543210" }
```

**`202`** — always. The response never reveals whether the number is registered:

```json
{ "data": { "message": "If this number is registered, a code has been sent.", "expiresIn": 300 } }
```

Phone format is validated against the region profile (ADR-0007), not a hardcoded pattern.

Rate limited per number **and** per source IP. An attacker who can enumerate registered parent phone numbers has a list of families at a specific school.

---

## `POST /auth/otp/verify` — Guardian login

**Feature:** IAM-002

```json
{ "phone": "+919876543210", "otp": "482913", "clientType": "PARENT_APP" }
```

Response mirrors `/auth/login`. Guardians receive a **longer refresh lifetime** than staff — losing a session mid-emergency is itself a safety problem ([`SECURITY_ARCHITECTURE.md`](../02-system-design/SECURITY_ARCHITECTURE.md)).

**Errors:** `AUTH_OTP_EXPIRED` · `AUTH_OTP_ALREADY_USED` · `AUTH_CREDENTIALS_INVALID` · `RATE_LIMIT_EXCEEDED`

OTPs are single-use and short-lived.

---

## `POST /auth/refresh` — Rotate tokens

**Feature:** IAM-003 · **Rules:** BR-IAM-007, BR-IAM-009

```json
{ "refreshToken": "opaque-random-string" }
```

**`200`** — returns a new access token **and a new refresh token**. The presented refresh token is consumed and can never be used again.

### Reuse detection

Presenting an already-consumed refresh token means it was captured. The response is `401 AUTH_REFRESH_REUSE_DETECTED`, and:

1. The **entire token family** is revoked — every descendant session (BR-IAM-009).
2. A security alert is raised (NTF-SEC-02).
3. The event is audited.

The legitimate user is logged out too. That is the correct trade: a stolen refresh token in a system holding children's locations is not something to resolve gently.

---

The three endpoints below act only on the caller's **own** sessions. They are authenticated but carry no permission from the matrix — ending your own session is identity, not authorisation, and the server answers `401` when no session is presented. In the code this is the `@SelfServiceEndpoint` marker, distinct from `@PublicEndpoint` (unauthenticated) and `@RequiresPermission`. Acting on **another** user's sessions is `DELETE /users/{id}/sessions` (`PERM-SESSION-REVOKE`), in the identity API.

## `POST /auth/logout`

**Self-service.** Revokes the session this request was made from, immediately. The driver app additionally **wipes its encrypted local store** (ADR-0008) — a shared device must not retain a previous shift's child data.

**`204`**

---

## `GET /auth/sessions` — List own sessions

**Feature:** IAM-004 · **Self-service**

```json
{
  "data": [
    { "id": "…", "clientType": "PARENT_APP", "deviceIdentifier": "Pixel 8",
      "issuedAt": "2026-08-01T06:12:00Z", "expiresAt": "2026-09-01T06:12:00Z",
      "status": "ACTIVE", "isCurrent": true }
  ]
}
```

`status` is `ACTIVE`, `REVOKED`, or `EXPIRED` — a rollup of the revoked flag and expiry, so a client does not re-derive lifecycle from timestamps. Revoked and expired rows are returned too: "this phone signed out yesterday" is what someone scanning for unfamiliar activity wants to see.

---

## `DELETE /auth/sessions/{sessionId}` — End one of your own

**Feature:** IAM-004 · **Self-service**

Signs a specific one of your own devices out from the list. A `sessionId` that is not yours returns `404 SESSION_NOT_FOUND` — the endpoint does not confirm another person's session id exists.

Revocation is immediate for refresh, and within the denylist window (≤15 min) for the access token (BR-IAM-007).

Deactivating an account (`PATCH /users/{id}/deactivate`), and staff deactivation (`POST /transport-staff/{staffId}/deactivate`), revoke **all** of that person's sessions (BR-IAM-008) — the control that matters when a driver leaves employment.

---

## `POST /auth/password/reset-request` / `POST /auth/password/reset`

**Feature:** IAM-009

Reset request always returns `202` regardless of whether the account exists. Reset tokens are single-use, short-lived, and **revoke all existing sessions on success**.

---

## `GET /.well-known/jwks.json`

Public. Signing keys for RS256 verification, with overlap during rotation so tokens signed by the previous key remain verifiable until they expire.

---

## Token Reference

| Property | Access token | Refresh token |
|---|---|---|
| Format | JWT, RS256 | Opaque random |
| Lifetime | 15 minutes | Long (client-dependent) |
| Storage | Client memory | Secure storage; **hashed** server-side |
| Reusable | n/a | **No — single use** |
| Revocable | Via denylist (≤15 min) | Immediately |

### Access token claims

```json
{
  "sub": "user-uuid",
  "tenantId": "organization-uuid",
  "sessionId": "session-uuid",
  "clientType": "PARENT_APP",
  "iat": 1754208000, "exp": 1754208900,
  "iss": "guardian-platform", "aud": "guardian-api"
}
```

**No permissions or roles in the token** (BR-IAM-004). They are resolved per request from a short-TTL cache invalidated on role change. A permission removed from a role takes effect on the **next request**, not the next token — which is the entire point ([`ADR-0006`](../00-governance/adr/ADR-0006-authentication-model.md)).

`tenantId` seeds the RLS session variable (ADR-0001). A token cannot address another tenant.

---

## Device Authentication

GPS devices use a **separate credential path** and never touch these endpoints (ADR-0006).

```
POST /api/v1/ingestion/positions
Authorization: Device <deviceId>:<signature>
```

Mutual TLS where the device supports it. Device credentials are long-lived, rotatable, and rate-limited per device. An unknown device is logged and ignored, **never auto-registered** (BR-FLEET-006).

---

## Verification

1. Refresh-token reuse revokes the family and raises an alert.
2. A revoked session's access token is rejected within the denylist window.
3. A role change takes effect on the next request without a new token.
4. A token bearing tenant A cannot read tenant B data.
5. OTP request returns `202` for both registered and unregistered numbers.
6. OTP is single-use and expires.
7. Logout wipes the driver app's local store.
8. Staff deactivation revokes every session for that user.
9. Rate limits apply per phone number and per source IP on OTP request.
