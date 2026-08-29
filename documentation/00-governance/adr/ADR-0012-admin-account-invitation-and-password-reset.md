# ADR-0012: Administrative account invitations and self-service password reset

**Status:** Accepted
**Date:** 2026-08-28
**Affects:** identity module, admin console, [`ADR-0006`](ADR-0006-authentication-model.md), [`SECURITY_ARCHITECTURE.md`](../../02-system-design/SECURITY_ARCHITECTURE.md), [`IDENTITY_ACCESS_API.md`](../../04-api/IDENTITY_ACCESS_API.md), [`ERROR_CATALOG.md`](../../04-api/ERROR_CATALOG.md)

## Context

Administrative users (`ORG_ADMIN`, `SCHOOL_ADMIN`, `PRINCIPAL`, `TRANSPORT_MANAGER`, and `SUPER_ADMIN`) sign in to the admin console with **email + password** (ADR-0006). Today the only way to give one of these people a working sign-in is `CreateAdministrativeUserUseCase`, which requires the operator to type an `initialPassword` and then hand it over out of band — `CreateUserRequest` itself documents that "no self-service or emailed invite flow exists yet."

Two gaps follow from that:

- **No way for a new admin to set their own password.** The operator picks the password, sees it in plaintext, and must transmit it. There is no verification that the account's email address is real or controlled by the intended person.
- **No way to recover a forgotten password.** A `SCHOOL_ADMIN` who forgets their password has no path back in; only a manual password re-set by another operator (which is also not built as a screen).

The platform is phone-first for **parents** (OTP), but admins are a different population: fewer, higher-privilege (a `SCHOOL_ADMIN` can read every child's PII in their school), and working on a **desktop web console**. For high-privilege accounts, "possession of a phone number" as the *sole* factor is weak — SMS OTP is vulnerable to SIM-swap, and numbers are reassigned on staff turnover. Email is a durable identity and gives an out-of-band channel for invitation, recovery, and security notices. (Phone OTP remains the right *second factor* for the most powerful roles later — a separate decision.)

The forces:

- Credential delivery must not depend on an operator copying a plaintext password.
- The account's email must be proven to belong to the person before the account is usable.
- Recovery must be self-service, with an operator-initiated fallback for the case where the email was entered wrong.
- We already have a proven "issue a hashed, expiring, single-use credential; deliver it via a provider port that is dev-logged until a real adapter ships" pattern — the OTP flow (`RequestOtpUseCase` → `OtpSender`/`LoggingOtpSender` → `VerifyOtpUseCase`). Re-inventing it would violate DRY and KISS.

## Decision

**Administrative accounts are activated and recovered by single-use, time-limited link tokens delivered by email, following the existing OTP credential pattern.**

1. **Invitation is the default when creating an admin; a manual password stays available.** `CreateAdministrativeUserUseCase` gains a delivery mode:
   - `INVITE` (default): the user row is created in a new **`PENDING`** status with **no** password credential, an `INVITE` token is issued, and an invitation email is sent after commit. The account cannot authenticate until the invite is accepted.
   - `PASSWORD` (fallback): the existing behaviour — operator sets a password, account is `ACTIVE` immediately. Kept for onboarding where the operator is sitting with the person or the email is not reliable.

2. **Accepting an invitation sets the password and activates the account.** A public endpoint takes the token + a new password, validates the password policy, writes the `PASSWORD` credential, consumes the token, and transitions the user `PENDING → ACTIVE`. Clicking the emailed link (which carries the token) *is* the email-verification step — no separate verify.

3. **Self-service password reset by emailed one-time code, plus an operator-initiated path.** Reset does **not** use a link — it uses a 6-digit code the person types back. This works across devices and email clients (no clicking a link on the same device the console is open on) and fits an OTP-familiar market. It reuses the sign-in OTP machinery (`OtpCredential`: single use, 5-attempt lock, BR-IAM-011), stored under its own `credential_type` so a sign-in code and a reset code can never be swapped.
   - Public "forgot password": takes an email, and **always returns the same generic response** whether or not an account exists (no account enumeration — OWASP). If the account exists and is active, a reset code is issued and emailed.
   - Public "reset password": takes the email + code + new password, verifies the code (advancing the attempt counter on a wrong guess), validates the policy, replaces the `PASSWORD` credential, consumes the code, and **revokes all of the user's sessions**.
   - Operator-initiated (authenticated, `PERM-USER-EDIT`): "resend invitation" for a `PENDING` user and "send reset code" for an `ACTIVE` user, from the Users screen — the fallback when a person's email was mistyped and only an operator can act; the admin still receives and enters the code.

4. **Two credential shapes, both hashed at rest, single-use, in `user_credentials`.**
   - **Invitation** uses a cryptographically-random URL-safe **link token** (≥ 256 bits), stored as a **deterministic SHA-256 hash** (`TokenHasher`) so it can be looked up by hash from a public endpoint that holds only the token. Type `INVITE`.
   - **Password reset** uses a **6-digit OTP** stored as a salted **Argon2** hash (`SecretHasher`) with an attempt counter and lock — because 6 digits is low-entropy and must not be brute-forceable. It is *not* looked up by hash; the account is resolved by **email** and the code checked against that account's latest reset credential, exactly as phone sign-in checks a code against a resolved phone. Type `RESET`.
   - **Expiry:** invite = 72 hours (resendable); reset code = **10 minutes** (single-use, 5-attempt lock). Re-issuing supersedes: the latest unconsumed credential wins.

5. **Invitation-token lookup crosses tenants through a `SECURITY DEFINER` function**, exactly as login does. The accept-invitation endpoint has no tenant context, so `auth_resolve_account_token(hash, type)` (owned by `guardian_preauth`, `BYPASSRLS`, mirroring `auth_resolve_email`) returns `(credential_id, user_id, tenant_id)`; the use case then does all mutation inside `tenantScoped.execute(tenantId, …)` under RLS. **Password reset needs no such function** — it is given the email, so it reuses the existing `auth_resolve_email` resolver.

6. **Email delivery is a port, dev-logged until a real adapter ships.** A new `AccountEmailSender` port carries invitation / reset / password-changed messages. `LoggingAccountEmailSender` (`@Profile("!prod & !production")`) writes the link to the log — identical containment to `LoggingOtpSender`, so a production deployment with no real adapter **fails to start** rather than silently not sending. The concrete provider (SES / SendGrid / Postmark / SMTP) is per-tenant configuration under ADR-0005's `EmailChannel`, chosen at go-live, not here.

7. **Password policy is length-first (NIST 800-63B).** Minimum length 12; rejected against a bundled list of the most common passwords; **no** forced composition rules and **no** forced rotation. Screening against a breach corpus (HaveIBeenPwned k-anonymity) is a future enhancement behind the same validator — flagged, not built now.

8. **Security defaults applied without further decision:** tokens never logged in production and never stored in plaintext; single-use and invalidated when the password changes; all sessions revoked on reset; a password-changed email sent on every password change; requests rate-limited; generic non-enumerating responses on the public email/token endpoints; audit records written in-transaction for create/invite/accept/reset/resend (BR-AUD-002).

9. **Administrators may also sign in with an emailed one-time code, as an alternative to a password — never as a replacement.** The console offers both: email + password (`POST /auth/login`), or email + a 6-digit code (`POST /auth/email-otp/request` → `/auth/email-otp/verify`). Both issue the same session, so an organisation that prefers passwords keeps them and one that would rather not manage passwords never sets one. The code reuses the same `OtpCredential` machinery as the reset code (6 digits, 10 minutes, single use, 5-attempt lock) under its own `credential_type` `LOGIN_OTP` — a third narrow type, so a phone sign-in code, a reset code and a console sign-in code can never be exchanged for one another.

   **The development magic code is opt-in by address, never blanket.** `guardian.auth.magic-otp` fixes the code so an account with no readable mailbox can still sign in (the mechanism the phone flow already had), but on the email path it applies *only* to addresses listed in `guardian.auth.magic-otp-emails`. An empty list disables the shortcut entirely rather than extending it to everyone — the opposite of the phone flow, and deliberately so: a blanket rule would mean a profile that sets a code for the parent app silently hands every administrator a guessable one, and the console is the higher-privilege surface. The list is empty even on the `demo` profile, because the seeded console accounts use real mailboxes and receive genuine generated codes; production configures no code at all.

   This does not change decision 1's framing: a password is still what an invitation sets up, and the reset flow still exists for it. Email-code sign-in is an additional door, and adding it retires nothing.

10. **Real email delivery is a second adapter behind the same port, switched by one flag.** `SmtpAccountEmailSender` (`guardian.mail.enabled=true`) sends over SMTP; `LoggingAccountEmailSender` (the default) writes to the log. Exactly one bean is registered, so nothing branches at call time, and the logging sender remains profile-gated out of production — a production deployment that forgets the flag fails to start rather than silently not sending. Delivery failure is logged rather than thrown: every caller sends *after* its transaction commits, so throwing would report a provider hiccup as a failure of work that actually succeeded, and would make the request-a-code endpoints answer differently for addresses that exist.

**Lockout guard (operational, not code):** self-service reset makes email a single point of failure for a role. The platform must retain **at least two `SUPER_ADMIN` accounts** (or a documented break-glass) so email loss for one cannot lock out platform administration.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Phone + OTP for admins (reuse parent flow) | Lightest to build, but SMS-as-sole-factor is weak for high-privilege accounts (SIM-swap, number reassignment), and admins work on desktop where email+password+manager is smoother. OTP is retained as a *future second factor*, not the primary. |
| Invite-only, remove the manual-password path | Cleaner, but brittle in the field: onboarding a principal in person, or one whose email is unreliable, needs a manual fallback. Kept both. |
| New dedicated `account_tokens` table | `user_credentials` already has the exact shape (hashed secret, expiry, consumed_at, tenant-scoped RLS). A second table would duplicate the pattern for no gain (KISS). |
| Salted Argon2 for link tokens (as passwords) | Argon2 is salted/non-deterministic, so it cannot be looked up by hash — and the public endpoints have only the token, not the user. High-entropy tokens are correctly stored as a single SHA-256 (OWASP), which is lookup-able. |
| Link (not OTP) for password reset | The first draft used an emailed reset link like the invitation. Changed to a 6-digit code: it works when the email is opened on a different device than the console, matches the OTP habit of the target market, and reuses the sign-in OTP machinery wholesale. Invitations stay links — activation is a one-time set-up, not a recurring action, and a longer-lived clickable link fits it. |
| Reuse the sign-in `OTP` credential type for reset | One type for both would let a sign-in code be replayed as a reset (or vice versa). Kept a separate `RESET` type so the two can never be confused. |
| Wire a real email provider now | Provider is per-tenant config (ADR-0005) and unknown until go-live; dev-log now matches the OTP precedent and blocks nothing. |
| Classic complexity + 90-day rotation policy | Contradicts current NIST guidance; pushes users to weaker, predictable passwords. Available only if a specific compliance regime demands it. |

## Consequences

**Positive**
- New admins set their own password; the operator never handles a plaintext credential, and the email is proven before the account works.
- Forgotten-password recovery is self-service, with an operator fallback for mistyped emails.
- Reuses the OTP credential/sender pattern end to end — one way to do "issue → deliver → consume a hashed, expiring, single-use secret."
- No new table, no new RLS surface; the public lookup reuses the established pre-auth `SECURITY DEFINER` mechanism.

**Negative / accepted cost**
- A new `PENDING` user status and two new `credential_type` values widen two CHECK constraints (migration).
- A `PENDING` account is a real state the UI and any user-listing must represent (a pending badge, a resend action).
- Email deliverability becomes an onboarding dependency once a real adapter ships; until then invitations are dev-logged only.
- Self-service reset makes email a potential lockout vector for a role — mitigated operationally (≥ 2 `SUPER_ADMIN`s / break-glass), not in code.

**Neutral**
- Phone-OTP second-factor for privileged roles is enabled by, but out of scope of, this ADR.
- The real email provider is deferred to per-tenant configuration under ADR-0005.

## Reversal Cost

**Low–moderate.** The invite/reset flow is additive: the manual-password path is unchanged and remains usable, so the feature can be disabled by defaulting the delivery mode back to `PASSWORD` and hiding the public pages. The `PENDING` status and new credential types would remain in the schema (harmless if unused). Trigger to reconsider: adopting an external IdP (ADR-0006 already anticipates this) would move invitation and recovery to that provider and supersede this ADR.

## Verification

1. A test asserts a `PENDING` user cannot authenticate (`UserStatus.canAuthenticate()` is false for `PENDING`).
2. A test asserts accepting an invitation with a valid token sets a password and moves the user to `ACTIVE`, and that the token cannot be used twice.
3. A test asserts an expired or already-consumed token is refused with the documented error code.
4. A test asserts "forgot password" returns an identical response for a known and an unknown email (no enumeration).
5. A test asserts completing a reset revokes all of the user's existing sessions.
6. A test asserts a password below the policy minimum, or on the common-password list, is refused with `VALIDATION_WEAK_PASSWORD`.
7. An architecture test asserts the three public endpoints carry `@PublicEndpoint` and the two operator endpoints carry `@RequiresPermission`.
8. A test asserts the token lookup is tenant-crossing only through the `SECURITY DEFINER` function and that all subsequent mutation runs under tenant scope.
