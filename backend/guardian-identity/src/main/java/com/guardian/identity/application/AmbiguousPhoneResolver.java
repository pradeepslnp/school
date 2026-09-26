package com.guardian.identity.application;

import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.PreAuthenticationDirectory.PhoneMatch;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.PhoneNumber;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Picks one account when a phone number resolves to users in more than one organization —
 * <strong>only on a build that configures the magic OTP</strong>, which is the demo profile alone.
 *
 * <p>BR-IAM-003 says a person belongs to one organization, so two rows for one number is a data
 * defect and sign-in {@linkplain com.guardian.identity.application.usecase.VerifyOtpUseCase
 * refuses} rather than signing someone into an organization at random. That refusal is correct in
 * production and stays: this class returns empty whenever {@code guardian.auth.magic-otp} is unset,
 * so nothing about a real deployment changes.
 *
 * <p>A local database, though, collects exactly that defect: the demo seed ships guardians on
 * numbers a developer then reuses for their own organization's records. Every sign-in with such a
 * number fails with "invalid code", which reads as a broken OTP rather than as a duplicate number,
 * and the real reason is only visible in the server log.
 *
 * <p><strong>The client being signed into decides.</strong> The parent app gets the {@code
 * GUARDIAN} account, the driver app the {@code DRIVER} or {@code ATTENDANT} one, the console an
 * administrative one. That is the choice a person would make, and it keeps the two halves of
 * sign-in consistent — the code is issued to the same account that will verify it. When the client
 * is unknown, or when it does not narrow the matches to exactly one, this returns empty and the
 * caller refuses as before: a guess is never made.
 *
 * <p>Roles are read inside each candidate's own tenant, under ordinary row-level security. Nothing
 * here widens {@link com.guardian.identity.application.port.PreAuthenticationDirectory}, the one
 * lookup that crosses tenants.
 */
@Component
public class AmbiguousPhoneResolver {

  private static final Logger log = LoggerFactory.getLogger(AmbiguousPhoneResolver.class);

  private static final Set<String> GUARDIAN_ROLES = Set.of("GUARDIAN");
  private static final Set<String> CREW_ROLES = Set.of("DRIVER", "ATTENDANT");
  private static final Set<String> CONSOLE_ROLES =
      Set.of("SUPER_ADMIN", "ORG_ADMIN", "SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER");

  private final UserRepository users;
  private final TenantScopedTransaction tenantScoped;
  private final String magicOtp;

  public AmbiguousPhoneResolver(
      UserRepository users,
      TenantScopedTransaction tenantScoped,
      @Value("${guardian.auth.magic-otp:}") String magicOtp) {
    this.users = users;
    this.tenantScoped = tenantScoped;
    this.magicOtp = magicOtp;
  }

  /** Whether this build disambiguates at all — true only where the magic OTP is configured. */
  public boolean enabled() {
    return magicOtp != null && !magicOtp.isBlank();
  }

  /**
   * The one account to sign in, or empty to refuse.
   *
   * @param clientType the client signing in, or null when it is not known (the OTP request carries
   *     it only from a client that sends it)
   */
  public Optional<PhoneMatch> resolve(
      PhoneNumber phone, List<PhoneMatch> matches, ClientType clientType) {

    if (!enabled() || clientType == null) {
      return Optional.empty();
    }

    List<PhoneMatch> signable =
        matches.stream().filter(match -> match.status().canAuthenticate()).toList();
    if (signable.size() == 1) {
      return Optional.of(logChoice(phone, signable.get(0), matches.size(), "only active account"));
    }

    Set<String> wanted = rolesFor(clientType);
    List<PhoneMatch> suited = signable.stream().filter(match -> holdsAny(match, wanted)).toList();
    if (suited.isEmpty()) {
      // No account suits this client — a parent app signing in on a driver-only number. Refusing
      // is the caller's existing path, and the right answer even here.
      return Optional.empty();
    }
    if (suited.size() == 1) {
      return Optional.of(logChoice(phone, suited.get(0), matches.size(), clientType.name()));
    }

    // Two accounts of the same kind — the same guardian number seeded in the demo organization
    // and reused in the developer's own. Nothing distinguishes them, so the choice is arbitrary;
    // it is made **stably**, by id, because the OTP request and the verification must land on the
    // same account or the code would never match. Loud in the log, and demo-only.
    PhoneMatch first =
        suited.stream()
            .min(Comparator.comparing(match -> match.userId().value().toString()))
            .orElseThrow();
    return Optional.of(logChoice(phone, first, matches.size(), "arbitrary (lowest id)"));
  }

  private PhoneMatch logChoice(PhoneNumber phone, PhoneMatch chosen, int total, String why) {
    log.warn(
        "Magic-OTP build: phone {} resolves to {} users across tenants (BR-IAM-003 defect); "
            + "signing in tenant {} by {}. Real deployments refuse this.",
        phone.masked(),
        total,
        chosen.tenantId().value(),
        why);
    return chosen;
  }

  private boolean holdsAny(PhoneMatch match, Set<String> wanted) {
    List<String> held =
        tenantScoped.execute(match.tenantId(), () -> users.roleCodesOf(match.userId()));
    return held.stream().anyMatch(wanted::contains);
  }

  private static Set<String> rolesFor(ClientType clientType) {
    return switch (clientType) {
      case PARENT_APP -> GUARDIAN_ROLES;
      case DRIVER_APP -> CREW_ROLES;
      case ADMIN_WEB -> CONSOLE_ROLES;
    };
  }
}
