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
import com.guardian.identity.application.port.ResetOtpCredentialRepository;
import com.guardian.identity.application.port.SecretHasher;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.OtpCode;
import com.guardian.identity.domain.OtpCredential;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Emails a password-reset code to an active administrator, initiated by an operator (ADR-0012,
 * feature IAM-010).
 *
 * <p>The operator fallback for a person who cannot start self-service reset — most often because
 * their email was entered wrong and only an operator can look at the record. The operator triggers
 * the email; the admin still receives and enters the code themselves, exactly as in the self-service
 * flow. Distinct from {@link RequestPasswordResetUseCase} because that one is public and
 * deliberately silent about whether an account exists; this one is authenticated, so it can report
 * plainly that a user is not resettable.
 *
 * <p>Same tenant handling and caller-boundary guard as {@link ResendInvitationUseCase}.
 */
@Service
@BusinessRule({"BR-IAM-002", "BR-IAM-004"})
public class SendPasswordResetCodeUseCase {

  private static final String SUPER_ADMIN = "SUPER_ADMIN";

  private final UserRepository users;
  private final ResetOtpCredentialRepository resetOtps;
  private final SecretHasher secretHasher;
  private final AccountEmailSender emailSender;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;
  private final String magicOtp;

  public SendPasswordResetCodeUseCase(
      UserRepository users,
      ResetOtpCredentialRepository resetOtps,
      SecretHasher secretHasher,
      AccountEmailSender emailSender,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped,
      @Value("${guardian.auth.magic-otp:}") String magicOtp) {
    this.users = users;
    this.resetOtps = resetOtps;
    this.secretHasher = secretHasher;
    this.emailSender = emailSender;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
    this.magicOtp = magicOtp;
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

    emailSender.sendPasswordResetCode(
        issued.email(), issued.firstName(), issued.code(), RequestPasswordResetUseCase.CODE_LIFETIME);
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

    OtpCode code = (magicOtp == null || magicOtp.isBlank()) ? OtpCode.generate() : OtpCode.of(magicOtp);
    resetOtps.save(
        OtpCredential.issue(
            user.id(), secretHasher.hash(code.value()), now, RequestPasswordResetUseCase.CODE_LIFETIME));

    auditPort.record(
        AuditRecord.builder()
            .tenantId(TenantContext.require())
            .actor(actorId, AuditRecord.ActorType.USER, actorRole)
            .action("AUTH_PASSWORD_RESET_REQUESTED")
            .subject("User", user.id().value())
            .after(Map.<String, Object>of("initiatedBy", "OPERATOR"))
            .build());

    return new Issued(code.value(), user.email(), user.firstName());
  }

  private record Issued(String code, String email, String firstName) {}
}
