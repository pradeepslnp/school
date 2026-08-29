-- V17 — Email one-time-code sign-in for the admin console (IAM-001, ADR-0012)
--
-- Adds a third one-time-code credential kind: LOGIN_OTP, the code emailed to an administrator who
-- chooses "email me a code" instead of typing a password.
--
-- Why a distinct type rather than reusing 'OTP' or 'RESET':
--   * 'OTP'       is the guardian's phone sign-in code. Sharing the type would let a code sent by
--                 SMS to a parent's handset be replayed against the admin console, and vice versa.
--   * 'RESET'     is the emailed password-reset code. Sharing the type would let a reset code be
--                 exchanged directly for a session — turning "prove you can read this mailbox" into
--                 a sign-in that skips setting a password at all.
-- Three narrow types cost one CHECK constraint; one broad type costs a credential-confusion bug
-- that no test would obviously catch.
--
-- No new table: user_credentials already carries hashed secret, expiry, consumed_at, attempt count
-- and lock, under tenant-scoped RLS (V3). Same reasoning as V16.

ALTER TABLE user_credentials DROP CONSTRAINT ck_user_credentials_type;
ALTER TABLE user_credentials
    ADD CONSTRAINT ck_user_credentials_type
    CHECK (credential_type IN ('PASSWORD', 'OTP', 'INVITE', 'RESET', 'LOGIN_OTP'));

-- A one-time code without an expiry is a permanent credential. The guard V16 applied to the link
-- kinds is extended to the emailed sign-in code for the same reason.
ALTER TABLE user_credentials DROP CONSTRAINT ck_user_credentials_link_expires;
ALTER TABLE user_credentials
    ADD CONSTRAINT ck_user_credentials_link_expires
    CHECK (credential_type NOT IN ('INVITE', 'RESET', 'LOGIN_OTP') OR expires_at IS NOT NULL);
