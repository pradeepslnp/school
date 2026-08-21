package com.guardian.staff.interfaces.rest.dto;

import com.guardian.staff.domain.StaffCredential;
import java.time.LocalDate;
import java.util.UUID;

public record StaffCredentialResponse(
    UUID id,
    UUID staffId,
    String credentialType,
    String credentialNumber,
    String credentialClass,
    LocalDate issuedOn,
    LocalDate expiresOn,
    boolean isMandatory,
    String fileRef) {

  public static StaffCredentialResponse from(StaffCredential credential) {
    return new StaffCredentialResponse(
        credential.id().value(),
        credential.staffId().value(),
        credential.credentialType(),
        credential.credentialNumber().orElse(null),
        credential.credentialClass().orElse(null),
        credential.issuedOn().orElse(null),
        credential.expiresOn(),
        credential.mandatory(),
        credential.fileRef().orElse(null));
  }
}
