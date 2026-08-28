package com.guardian.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for accepting an invitation (ADR-0012, feature IAM-009): the token from the emailed
 * link plus the password the invitee chooses.
 *
 * <p>{@code @NotBlank} catches an empty submission at the boundary; the token's validity and the
 * password's strength are decided server-side ({@code AcceptInvitationUseCase}, {@code
 * PasswordPolicy}), never trusted from here.
 */
public record AcceptInvitationRequest(
    @NotBlank String token, @NotBlank @Size(max = 128) String password) {}
