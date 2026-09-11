# ADR-0014: Platform email delivery over SMTP

**Status:** Accepted
**Date:** 2026-09-10
**Affects:** identity module (`guardian-identity` infrastructure), [`ADR-0012`](ADR-0012-admin-account-invitation-and-password-reset.md) §6, [`ADR-0005`](ADR-0005-notification-provider-abstraction.md) (`EmailChannel`), [`SECURITY_ARCHITECTURE.md`](../../02-system-design/SECURITY_ARCHITECTURE.md), [`LOCAL_SETUP.md`](../../06-development/LOCAL_SETUP.md), [`DEPLOYMENT.md`](../../08-deployment/DEPLOYMENT.md)

## Context

ADR-0012 built administrative account invitations and self-service password reset on the `AccountEmailSender` port, and deferred the concrete provider: "dev-logged until a real adapter ships … the concrete provider (SES / SendGrid / Postmark / SMTP) is per-tenant configuration under ADR-0005's `EmailChannel`, chosen at go-live, not here."

That deferral now blocks real use:

- The only `AccountEmailSender` implementation is `LoggingAccountEmailSender`, gated `@Profile("!prod & !production")`. A `prod` deployment has no email sender at all and the context fails to start — the intended fail-closed behaviour, but it means no customer can be onboarded.
- Even in development, exercising the invite and reset flows means reading a link or a code out of the application log. A developer cannot see what the recipient sees, and cannot test against a real inbox.

ADR-0005's `EmailChannel` — per-tenant provider, sender identity, credentials, and versioned templates — is the correct end state, but it is a module's worth of work (a tenant-configuration store, per-tenant secret storage, a template registry) and none of it is needed to get the first school live.

The forces:

- One school needs to receive real invitation and reset emails. That is the whole requirement right now.
- The same mechanism should work in development, pointed at a local catcher, so the flows are testable without log-scraping.
- Delivery must not become a way to break the flows it serves: the reset-request endpoint returns `202` whether or not the account exists (no enumeration — OWASP), and the invite/reset use cases have already committed the token or code before delivery is attempted. A send failure must not turn into a `500`.
- No provider SDK in the domain or leaking through infrastructure (ENGINEERING_PRINCIPLES.md; CLAUDE.md §11).
- The `@Profile`-gated fail-closed guarantee from ADR-0012 §6 must survive.

## Decision

**A single SMTP adapter, `SmtpAccountEmailSender`, implementing the existing `AccountEmailSender` port, selected by configuration, platform-wide for now.**

1. **SMTP via Spring's `JavaMailSender`.** `guardian-identity` gains `spring-boot-starter-mail`. `SmtpAccountEmailSender` lives beside `LoggingAccountEmailSender` in `infrastructure/email/` and the port is untouched. SMTP is the universal interface: the same adapter points at a local catcher (MailHog / Mailpit) in development and at a real relay in production. No vendor SDK enters the codebase.

2. **Registered by `@ConditionalOnProperty("spring.mail.host")` and marked `@Primary`.** That property is also exactly the condition under which Spring Boot creates the `JavaMailSender` the adapter needs.
   - **Development, no mail host:** only `LoggingAccountEmailSender` exists — unchanged behaviour, link and code in the log.
   - **Development, mail host set:** both beans exist; `@Primary` means the use cases inject the SMTP one and mail is really sent.
   - **`prod` / `production`:** `LoggingAccountEmailSender` is excluded by profile. An unset `spring.mail.host` leaves no `AccountEmailSender`, and the context fails to start — the ADR-0012 §6 guarantee, unchanged.

3. **The adapter never throws.** `mailSender.send(...)` is wrapped; a `MailException` is logged at `ERROR` with the recipient address masked, and swallowed. This matches the "no failure branch" design of the calling use cases — the token/code is already persisted, and the operator's recourse is "resend invitation" / "send reset code". `mail.smtp.*.timeout` is set to 5s so an unreachable host fails fast rather than holding a response thread (the send already runs after the request transaction has committed).

4. **Platform-wide sender, explicitly interim.** One `From` address (`guardian.email.from`) and one SMTP account for the whole platform. Per-tenant sender identity, provider, and templates remain ADR-0005's `EmailChannel`; when that lands, this adapter delegates to it instead of holding SMTP details. Messages are plain text, content mirroring what `LoggingAccountEmailSender` already logs, plus a subject line and the console URL (`guardian.admin.base-url`).

5. **Credentials come from the environment**, never source (`SECURITY_ARCHITECTURE.md`): `SPRING_MAIL_HOST`, `GUARDIAN_SMTP_USERNAME`, `GUARDIAN_SMTP_PASSWORD`, `GUARDIAN_EMAIL_FROM`. Authentication is not forced in config — JavaMail enables it when a username/password is supplied — so a credential-less local catcher works and a real relay on port 587 still authenticates and upgrades via STARTTLS.

6. **The initial production transport is a Google Workspace / Gmail account with an app password.** Low setup cost and adequate for one school's volume. It is transport configuration, not an architectural commitment — moving to SES or a dedicated provider is an environment change, no code.

7. **Scope is email only.** The guardian SMS one-time-code path (`OtpSender`) keeps its logging adapter; a real SMS provider is a separate decision.

## Alternatives Considered

| Alternative | Why rejected |
|---|---|
| Provider SDK now (AWS SES, SendGrid API) | Better delivery telemetry, but a separate adapter per vendor and the SDK sits in infrastructure. SMTP gets the needed outcome with one adapter and no new dependency beyond a Spring starter. |
| Full ADR-0005 `EmailChannel` (per-tenant) now | The correct end state, but weeks of work — tenant-config store, per-tenant secret storage, template registry — none of it required to send one school its invitation emails. This ADR is a deliberate step toward it, not a detour. |
| Keep development on the logging adapter | The request was specifically that a developer be able to test against a real inbox, not the log. |
| Force `mail.smtp.auth=true` in config | Breaks a credential-less local catcher. JavaMail turns auth on when credentials are present, so forcing it buys nothing. |
| Make the adapter propagate send failures | Would turn a reset request into a `500` and let it enumerate accounts, and would surface an invite-email hiccup as a failed user creation even though the account and token were written. |
| A new profile (`email`) rather than a property switch | A property that is also the trigger for Spring's own mail auto-configuration is one fact, not two that can disagree. |

## Consequences

**Positive**
- A school receives real invitation, reset-code, and password-changed emails.
- The same adapter runs in development against MailHog/Mailpit — the flows are testable end to end against an inbox.
- No new runtime dependency beyond a first-party Spring Boot starter; no provider SDK anywhere.
- ADR-0012 §6's fail-closed property is preserved exactly.

**Negative / accepted cost**
- Platform-wide sender identity: every tenant's mail comes `From` the same address until ADR-0005's `EmailChannel` is built. For a single early customer this is invisible; it must not ship to a multi-customer deployment unaddressed.
- A failed send is only an `ERROR` log line. Until there is delivery-attempt persistence (ADR-0005), operational visibility is "watch the logs" plus the manual resend actions.
- Gmail rewrites `From` to the authenticated mailbox unless the address is a verified alias — the configured `guardian.email.from` may not be what recipients see.
- SMTP send is synchronous (after commit). Bounded at 5s by timeouts; asynchronous/queued dispatch is ADR-0005's concern.

**Neutral**
- SMS OTP delivery is untouched and still logging-only.
- Choice of Gmail vs SES vs another relay is now an environment-variable decision.

## Reversal Cost

**Low.** The adapter is one class behind an existing port. Unsetting `spring.mail.host` in a non-prod environment reverts to logging with no code change. Replacing it — with a provider SDK adapter, or with ADR-0005's `EmailChannel` — is a new implementation of the same port; the use cases do not change. The trigger to reconsider is the second paying tenant (per-tenant sender identity becomes mandatory) or a deliverability problem with Gmail (move to SES).

## Verification

1. With `spring.mail.host` unset, `LoggingAccountEmailSender` is the injected `AccountEmailSender` and the invite/reset flows log as before.
2. With `spring.mail.host` set to a local catcher, requesting a password reset delivers a message to that catcher with the expected subject and body, and the reset-request endpoint still returns `202`.
3. With `spring.mail.host` set to an unreachable host, the reset-request endpoint still returns `202`, creating an invited user still returns `201`, and each failure is logged at `ERROR` with the recipient masked — no `500`, no stack trace to the client.
4. The `prod` profile with no `spring.mail.host` fails to start (no `AccountEmailSender` bean).
5. The ArchUnit layering suite (`no_provider_sdks_inside_the_domain`, `domain_is_free_of_frameworks`) still passes — the mail dependency is confined to `infrastructure`.
