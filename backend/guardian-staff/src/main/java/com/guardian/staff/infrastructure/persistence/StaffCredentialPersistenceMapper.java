package com.guardian.staff.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.StaffCredentialId;
import com.guardian.staff.domain.StaffId;
import org.springframework.stereotype.Component;

@Component
class StaffCredentialPersistenceMapper {

  StaffCredential toDomain(StaffCredentialEntity entity) {
    return new StaffCredential(
        StaffCredentialId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        StaffId.of(entity.getStaffId()),
        entity.getCredentialType(),
        entity.getCredentialNumber(),
        entity.getCredentialClass(),
        entity.getIssuedOn(),
        entity.getExpiresOn(),
        entity.isMandatory(),
        entity.getFileRef(),
        entity.getVersion());
  }

  StaffCredentialEntity toEntity(StaffCredential credential) {
    return new StaffCredentialEntity(
        credential.id().value(),
        credential.tenantId().value(),
        credential.staffId().value(),
        credential.credentialType(),
        credential.credentialNumber().orElse(null),
        credential.credentialClass().orElse(null),
        credential.issuedOn().orElse(null),
        credential.expiresOn(),
        credential.mandatory(),
        credential.fileRef().orElse(null),
        credential.version());
  }

  void applyTo(StaffCredentialEntity managed, StaffCredential credential) {
    managed.applyMutableState(
        credential.credentialNumber().orElse(null),
        credential.credentialClass().orElse(null),
        credential.issuedOn().orElse(null),
        credential.expiresOn(),
        credential.mandatory(),
        credential.fileRef().orElse(null));
  }
}
