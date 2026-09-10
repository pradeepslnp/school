package com.guardian.identity.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.DataConflictException;
import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.identity.application.port.AccountEmailSender;
import com.guardian.identity.application.port.AccountTokenRepository;
import com.guardian.identity.application.port.TokenHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.AccountToken;
import com.guardian.identity.domain.LinkToken;
import com.guardian.identity.domain.TokenPurpose;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Re-sends an invitation to an administrator who has not yet activated (ADR-0012, feature IAM-009).
 *
 * <p>The operator fallback for the case self-service cannot cover: an invitee whose email was
 * mistyped, or whose link expired, cannot fix it themselves. Only a {@code PENDING} account can be
 * re-invited — an active one already has a password and would use the reset flow instead.
 *
 * <p>Runs within the target organization's tenant like {@link CreateAdministrativeUserUseCase}, and
 * carries the same caller-boundary guard: anyone but a {@code SUPER_ADMIN} may only act inside
 * their own tenant.
 */
@Service
@BusinessRule({"BR-IAM-002", "BR-IAM-004"})
public class ResendInvitationUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final AccountTokenRepository accountTokens;
  private final TokenHasher tokenHasher;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public ResendInvitationUseCase(
      UserRepository users,
      AccountTokenRepository accountTokens,
      TokenHasher tokenHasher,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.users = users;
    this.accountTokens = accountTokens;
    this.tokenHasher = tokenHasher;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public void execute(UUID organizationId, UUID userId, UUID actorId, String actorRole) {
    Instant now = Instant.now();

    if (!SUPER_ADMIN.equals(actorRole)) {
      TenantId callerTenant = TenantContext.require();
      if (!callerTenant.value().equals(organizationId)) {
        throw new ResourceNotFoundException(
            ErrorCode.AUTH_SCOPE_DENIED, "organization", organizationId);
      }
    }

    Issued issued =
        tenantScoped.execute(
            TenantId.of(organizationId), () -> resendWithin(userId, actorId, actorRole, now));

    emailSender.sendInvitation(
        issued.email(), issued.firstName(), issued.rawToken(), TokenPurpose.INVITE.lifetime());
  }

  private Issued resendWithin(UUID userId, UUID actorId, String actorRole, Instant now) {
    Optional<User> found = users.findById(UserId.of(userId));
    if (found.isEmpty()) {
      throw new ResourceNotFoundException(ErrorCode.USER_NOT_FOUND, "user", userId);
    }
    User user = found.get();
    if (user.status() != UserStatus.PENDING) {
      throw new DataConflictException(
          ErrorCode.USER_NOT_PENDING, Map.of("status", user.status().name()));
    }

    LinkToken raw = LinkToken.generate();
    accountTokens.save(
        AccountToken.issue(user.id(), TokenPurpose.INVITE, tokenHasher.hash(raw.value()), now));

    auditPort.record(
        AuditRecord.builder()
            // Inside tenantScoped.execute, the context is the target organization's tenant.
            .tenantId(TenantContext.require())
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("ADMINISTRATIVE_USER_INVITE_RESENT")
            .subject("User", user.id().value())
            .after(Map.<String, Object>of("initiatedBy", "OPERATOR"))
            .build());

    return new Issued(raw.value(), user.email(), user.firstName());
  }

  private record Issued(String rawToken, String email, String firstName) {}
}
