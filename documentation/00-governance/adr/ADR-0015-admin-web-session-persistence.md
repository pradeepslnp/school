# ADR-0015: Persisted admin-web sessions in browser local storage

**Status:** Accepted
**Date:** 2026-09-13
**Affects:** `admin` client (`core/session`), [`CODING_STANDARDS_FLUTTER.md`](../../06-development/CODING_STANDARDS_FLUTTER.md) §Security, [`SECURITY_ARCHITECTURE.md`](../../02-system-design/SECURITY_ARCHITECTURE.md), ADR-0006

## Context

The administration console held its session in memory only (`InMemorySessionStore`), so **every page reload signed the operator out**. [`ADMIN_WEB.md`](../../05-ui/ADMIN_WEB.md) §Design Brief describes a desk tool used with several tabs open across a working day; re-entering a password on every reload is a daily friction cost on the console's primary persona.

The obstacle is where a browser can keep a refresh token. `CODING_STANDARDS_FLUTTER.md` §Security states plainly: *"Tokens in platform secure storage, never in shared preferences."* On Flutter Web `SharedPreferences` **is** `localStorage`, readable by any script on the origin, and `flutter_secure_storage` does not help — its web backend encrypts into `localStorage` with a key stored in `localStorage`. An `ADMIN_WEB` refresh token is valid for 14 days (`ClientType.ADMIN_WEB`) on an account that `SECURITY_ARCHITECTURE.md` classifies as the platform's *higher privilege* client: it can read every child record in its tenant scope.

So the decision is not "persist or not". It is **which of two real costs to accept**: a daily sign-in on every reload, or a refresh token that becomes readable if the console ever has an XSS.

## Decision

The console persists its session in `SharedPreferences` (`SharedPreferencesSessionStore`), and **re-validates it against the server before trusting it**.

On startup, `SessionManager.restore()` does not adopt a stored session directly. It rotates the stored refresh token through `POST /auth/refresh`, which looks the token up against its server-side `Session` row. A session revoked while the tab was closed — staff deactivated (BR-IAM-007), signed out elsewhere, or a token family burned for reuse (BR-IAM-009) — is rejected there and cannot be resurrected from local storage. The console stays in `AuthUnknown` until the server answers.

**A durable store also makes refresh a cross-tab problem, and that had to be solved for this decision to be safe.** A refresh token is single-use; presenting a consumed one is read as theft and revokes the whole family (BR-IAM-009). With an in-memory store each tab held its own session, so this could not arise. Sharing one token across tabs means two tabs restoring at once would both rotate it, the slower would be correctly read as a replay, and **the operator would be signed out of every tab** — in a console `ADMIN_WEB.md` explicitly expects to be used with several tabs open. `SessionManager`'s existing single-flight guard does not help: it de-duplicates within one tab.

So exactly one tab may rotate the stored token (`ConcurrentSessionStore.tryClaimRefresh`, a TTL'd claim in the same storage); the others wait for it to publish the rotated session and adopt that. The claim expires on its own, so a tab closed mid-restore cannot lock anyone out.

This is an explicit, scoped exception to `CODING_STANDARDS_FLUTTER.md` §Security. **It applies to the `admin` client only.** The parent and driver apps run on platforms where secure storage is genuinely available, the standard applies to them unchanged, and `InMemorySessionStore` remains the default for any client that has not accepted this trade.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| `HttpOnly; Secure; SameSite=Strict` refresh cookie | **The correct answer, and the recorded exit — deferred, not rejected on merit.** JavaScript cannot read the token, so XSS cannot steal a durable session. It requires the API to set the cookie at sign-in, changing a contract that currently returns the refresh token in the response body (`AUTHENTICATION_API.md`), plus CORS credential handling. Backend work that was not in scope when the console needed persistence. |
| Keep `InMemorySessionStore` | Does not solve the stated problem: the operator is still signed out on every reload. |
| `flutter_secure_storage` | No improvement on web — encrypts into `localStorage` with a key kept in `localStorage`. Would obscure the risk rather than reduce it, which is worse than naming it. |
| Persist non-sensitive details only (email, display name) | Safe, and genuinely useful for prefilling sign-in, but does not keep anyone signed in. Available as a later addition; it does not conflict with this decision. |
| Shorten the `ADMIN_WEB` refresh lifetime | Narrows the stolen-token window without closing it, and costs every operator more sign-ins. Worth revisiting *alongside* the cookie work, not instead of it. |

## Consequences

**Positive**

- A reload, a crash, or a reopened tab no longer costs a sign-in.
- Revocation still takes effect: the startup validation makes local storage a cache of the server's answer, never the authority.
- `SessionStore` stays a port. Replacing this implementation with the cookie-backed one touches one class.

**Negative / accepted cost**

- **An XSS anywhere in the console — including in a dependency — yields a refresh token, and with it a 14-day session over every child record in the signed-in operator's scope.** This is the accepted risk, and it is the reason this ADR exists rather than a code comment.
- The console contradicts a platform coding standard. Anyone reading `CODING_STANDARDS_FLUTTER.md` §Security must be sent here, or the exception silently becomes precedent.
- Startup now makes a network call before the first screen. On a slow link the splash is held; on an unreachable API the stored session is used unvalidated until the first request re-checks it.
- The cross-tab claim is a lease in `localStorage`, not a real mutex — the browser offers none. Two tabs writing within the same microtask can both proceed; the waiting path is written to be correct when that happens, but the residual race is real and is the reason the claim is read back after writing.

**Neutral**

- Storage is versioned (`guardian.admin.session.v1`); an unparseable value is erased rather than partially trusted.

## Reversal Cost

**Low, and deliberately so.** `SessionStore` is a port with two implementations; reversal is one line in `dependencies.dart`. Moving to the cookie design additionally requires the `AuthController` change and CORS work described above, and does **not** require touching `SessionManager` — the startup validation this ADR introduces is exactly what the cookie design needs anyway.

**Triggers for reconsideration:**

- Any XSS finding in the console or its dependency tree — this ADR is then re-opened immediately, not scheduled.
- The `HttpOnly` cookie work becoming available on the API.
- Any move to widen `ADMIN_WEB`'s refresh lifetime beyond 14 days.
- A security review of the console, which should treat this as a named finding with an accepted-risk owner rather than discovering it.

## Verification

- `SharedPreferencesSessionStore` carries the risk and this ADR's number in its class documentation; `dependencies.dart` names it at the wiring point.
- `CODING_STANDARDS_FLUTTER.md` §Security links here, so the standard and its exception are never read apart.
- The behaviour that makes this defensible is `SessionManager.restore()` awaiting `/auth/refresh` before emitting `AuthSignedIn`. **A test asserting that a revoked stored session results in `AuthSignedOut` is the gate on this decision** — it is not yet written (see the repository's standing position on tests), and until it is, this verification is by review only.
