package com.guardian.identity.application.port;

import com.guardian.common.tenant.TenantId;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.util.List;
import java.util.Optional;

/**
 * The only lookups in the platform that run without tenant context.
 *
 * <p>Authentication has a bootstrap problem: row-level security needs {@code app.tenant_id}, and at
 * {@code POST /auth/otp/request} or {@code POST /auth/login} the caller has supplied nothing but a
 * phone number or an email address. Something must cross tenants once to answer "whose identifier
 * is this?" before context can be established.
 *
 * <p>This port is that something, and it is deliberately the narrowest shape that works:
 *
 * <ul>
 *   <li>It returns <strong>identifiers and status only</strong>. No name, no locale, no credential
 *       material. A defect here therefore cannot become a data leak — the reads that follow run
 *       under ordinary RLS with the tenant this returned.
 *   <li>It is implemented by {@code SECURITY DEFINER} SQL functions granted narrowly to the
 *       application role (V3__identity.sql, V10__staff_login.sql), <strong>not</strong> by giving
 *       that role BYPASSRLS. Granting BYPASSRLS would have removed isolation from the entire
 *       application in order to solve one lookup.
 * </ul>
 *
 * <p>Two credential kinds, two methods — {@link #findByPhone} for guardians, {@link #findByEmail}
 * for staff — rather than one generic "resolve an identifier" method. Each is unambiguous about
 * which identifier it accepts, so a caller cannot pass a phone number where an email address is
 * expected and have it silently match nothing. A fourth method here is still a signal worth
 * stopping on: every addition widens the one path that is not tenant-isolated, and this pair covers
 * every credential kind the platform currently authenticates by.
 */
public interface PreAuthenticationDirectory {

  /**
   * Every user holding this number, across all tenants.
   *
   * <p>Returns a list rather than an {@code Optional} because {@code users.phone} is unique only
   * <em>within</em> a tenant, so the same number can legitimately exist in two organizations' rows.
   * BR-IAM-003 says a person belongs to one organization, so more than one match is a data defect —
   * and it is the caller's job to refuse rather than to guess. Guessing would sign someone into an
   * organization at random.
   *
   * <p>Does not filter by status. A caller that never sees locked or inactive users cannot answer
   * uniformly, and a response that varies by account state enumerates registered guardians.
   */
  List<PhoneMatch> findByPhone(PhoneNumber phone);

  /**
   * Every user holding this email address, across all tenants (IAM-001).
   *
   * <p>Staff sign in by email rather than phone; the shape of the problem and the reasons for this
   * shape are identical to {@link #findByPhone} — see that method's documentation. A list for the
   * same reason: {@code users.email} is unique only within a tenant (uq_users_tenant_email), so
   * BR-IAM-003 is the caller's rule to enforce, not this method's.
   */
  List<EmailMatch> findByEmail(String email);

  /** Locates the session holding this refresh token hash, so its tenant can be established. */
  Optional<SessionLocation> findSessionByRefreshTokenHash(String refreshTokenHash);

  /** A user found by phone, with just enough to establish context and decide whether to proceed. */
  record PhoneMatch(UserId userId, TenantId tenantId, UserStatus status) {}

  /** A user found by email. Same shape as {@link PhoneMatch}, for the same reason. */
  record EmailMatch(UserId userId, TenantId tenantId, UserStatus status) {}

  /** A session found by its refresh token hash. */
  record SessionLocation(SessionId sessionId, TenantId tenantId) {}
}
