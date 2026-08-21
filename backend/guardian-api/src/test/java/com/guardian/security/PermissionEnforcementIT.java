package com.guardian.security;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.guardian.AbstractIntegrationTest;
import com.guardian.common.BusinessRule;
import com.guardian.identity.application.port.AccessTokenIssuer;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

/**
 * {@code @RequiresPermission} refuses a caller who does not hold the permission (BR-IAM-002).
 *
 * <p>Integration-level because the guarantee is entirely plumbing: the annotation was already
 * declared on every endpoint and verified by an ArchUnit test, but nothing read it at request time.
 * Whether the interceptor sees a populated security context, and whether permission resolution can
 * read role assignments under row-level security, are not observable without the real filter chain
 * and a real database.
 *
 * <p>The two cases prove each other. If the security filter chain were skipped — the usual symptom
 * of a missing {@code spring-security-test} on the classpath — the principal would be absent and
 * <em>every</em> request would fail the interceptor's fail-closed branch with 403, including the
 * one expected to succeed. A passing deny case alone would therefore be no evidence at all.
 */
@AutoConfigureMockMvc
class PermissionEnforcementIT extends AbstractIntegrationTest {

  private static final UUID GUARDIAN_USER_ID = UUID.randomUUID();
  private static final UUID GUARDIAN_ROLE_ID = UUID.randomUUID();
  private static final UUID SCHOOL_ADMIN_USER_ID = UUID.randomUUID();
  private static final UUID SCHOOL_ADMIN_ROLE_ID = UUID.randomUUID();

  @Autowired private MockMvc mockMvc;
  @Autowired private AccessTokenIssuer accessTokenIssuer;

  @BeforeEach
  void seedUsersAndRoles() {
    // Seeded as owner, which is a superuser in the test container and so bypasses RLS. This is
    // the school provisioning staff accounts; no self-registration flow exists.
    JdbcTemplate owner = ownerJdbcTemplate();

    seedRole(owner, GUARDIAN_ROLE_ID, "GUARDIAN", "Guardian");
    seedRole(owner, SCHOOL_ADMIN_ROLE_ID, "SCHOOL_ADMIN", "School Administrator");

    seedUser(owner, GUARDIAN_USER_ID, "Asha", "Rao", GUARDIAN_ROLE_ID);
    seedUser(owner, SCHOOL_ADMIN_USER_ID, "Fatima", "Khan", SCHOOL_ADMIN_ROLE_ID);
  }

  @Test
  @BusinessRule("BR-IAM-002")
  @DisplayName("a guardian is refused an endpoint whose permission they do not hold")
  void guardianIsRefused() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/vehicles")
                .param("schoolId", UUID.randomUUID().toString())
                .header("Authorization", "Bearer " + tokenFor(GUARDIAN_USER_ID)))
        .andExpect(status().isForbidden())
        // The code matters more than the status: a 403 raised for the wrong reason would
        // otherwise look like a passing test.
        .andExpect(jsonPath("$.error.code").value("AUTH_PERMISSION_DENIED"))
        .andExpect(jsonPath("$.error.businessRule").value("BR-IAM-002"))
        .andExpect(jsonPath("$.error.details[0].issue").value("PERM-VEHICLE-VIEW"));
  }

  @Test
  @BusinessRule("BR-IAM-002")
  @DisplayName("a school administrator holding the permission is admitted")
  void schoolAdminIsAdmitted() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/vehicles")
                .param("schoolId", UUID.randomUUID().toString())
                .header("Authorization", "Bearer " + tokenFor(SCHOOL_ADMIN_USER_ID)))
        .andExpect(status().isOk());
  }

  @Test
  @BusinessRule("BR-IAM-002")
  @DisplayName("an unauthenticated request never reaches the permission check")
  void unauthenticatedIsRefusedEarlier() throws Exception {
    mockMvc
        .perform(get("/api/v1/vehicles").param("schoolId", UUID.randomUUID().toString()))
        .andExpect(status().isUnauthorized());
  }

  /**
   * Mints a token directly rather than signing in.
   *
   * <p>Verification is stateless — {@code NimbusAccessTokenVerifier} checks signature, issuer,
   * audience and expiry and never reads the {@code sessions} table — so a token minted here is
   * accepted exactly as one issued by a real sign-in, and the session id needs no row behind it.
   * Driving a real sign-in would test the sign-in flow, which has its own tests, rather than the
   * authorization this class exists to prove.
   */
  private String tokenFor(UUID userId) {
    return accessTokenIssuer
        .issue(
            new AccessTokenIssuer.Claims(
                UserId.of(userId), TENANT_A, SessionId.of(UUID.randomUUID()), ClientType.ADMIN_WEB))
        .value();
  }

  private void seedRole(JdbcTemplate owner, UUID roleId, String code, String name) {
    owner.update(
        """
        INSERT INTO roles (id, tenant_id, code, name, is_system_role)
        VALUES (?, ?, ?, ?, true)
        """,
        roleId,
        ORGANIZATION_A,
        code,
        name);
  }

  private void seedUser(
      JdbcTemplate owner, UUID userId, String firstName, String lastName, UUID roleId) {
    owner.update(
        """
        INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
        VALUES (?, ?, ?, ?, ?, 'en', 'ACTIVE')
        """,
        userId,
        ORGANIZATION_A,
        firstName.toLowerCase(java.util.Locale.ROOT) + "@greenwood.test",
        firstName,
        lastName);

    owner.update(
        "INSERT INTO user_roles (id, tenant_id, user_id, role_id) VALUES (?, ?, ?, ?)",
        UUID.randomUUID(),
        ORGANIZATION_A,
        userId,
        roleId);
  }
}
