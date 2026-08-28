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
 * Sends a password-reset link to an active administrator, initiated by an operator (ADR-0012,
 * feature IAM-010).
 *
 * <p>The counterpart to {@link ResendInvitationUseCase} for accounts past activation: the operator
 * fallback for someone who cannot use self-service reset — most often because their email was
 * entered wrong and only an operator can look at the record. Distinct from {@link
 * RequestPasswordResetUseCase} because that one is public and deliberately silent about whether an
 * account exists; this one is authenticated, so it can report plainly that a user is not resettable.
 *
 * <p>Same tenant handling and caller-boundary guard as {@link ResendInvitationUseCase}.
 */
@Service
@BusinessRule({"BR-IAM-002", "BR-IAM-004"})
public class SendPasswordResetLinkUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final AccountTokenRepository accountTokens;
  private final TokenHasher tokenHasher;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public SendPasswordResetLinkUseCase(
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
        throw new ResourceNotFoundException(ErrorCode.AUTH_SCOPE_DENIED, "organization", organizationId);
      }
    }

    Issued issued =
        tenantScoped.execute(
            TenantId.of(organizationId), () -> issueWithin(userId, actorId, actorRole, now));

    emailSender.sendPasswordReset(
        issued.email(), issued.firstName(), issued.rawToken(), TokenPurpose.RESET.lifetime());
  }

  private Issued issueWithin(UUID userId, UUID actorId, String actorRole, Instant now) {
    Optional<User> found = users.findById(UserId.of(userId));
    if (found.isEmpty()) {
      throw new ResourceNotFoundException(ErrorCode.USER_NOT_FOUND, "user", userId);
    }
    User user = found.get();
    if (user.status() != UserStatus.ACTIVE || user.email() == null) {
      throw new DataConflictException(
          ErrorCode.USER_NOT_ACTIVE, Map.of("status", user.status().name()));
    }

    LinkToken raw = LinkToken.generate();
    accountTokens.save(
        AccountToken.issue(user.id(), TokenPurpose.RESET, tokenHasher.hash(raw.value()), now));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("AUTH_PASSWORD_RESET_REQUESTED")
            .subject("User", user.id().value())
            .after(Map.<String, Object>of("initiatedBy", "OPERATOR"))
            .build());

    return new Issued(raw.value(), user.email(), user.firstName());
  }

  private record Issued(String rawToken, String email, String firstName) {}
}
