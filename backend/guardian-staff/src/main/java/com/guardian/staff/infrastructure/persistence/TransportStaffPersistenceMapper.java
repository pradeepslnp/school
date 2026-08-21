package com.guardian.staff.infrastructure.persistence;

import com.guardian.common.tenant.TenantId;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.domain.UserId;
import com.guardian.staff.domain.VerificationStatus;
import org.springframework.stereotype.Component;

/** Translates between the domain model and its JPA mapping. */
@Component
class TransportStaffPersistenceMapper {

  TransportStaff toDomain(TransportStaffEntity entity) {
    return new TransportStaff(
        StaffId.of(entity.getId()),
        TenantId.of(entity.getTenantId()),
        SchoolId.of(entity.getSchoolId()),
        entity.getUserId() == null ? null : UserId.of(entity.getUserId()),
        StaffType.valueOf(entity.getStaffType()),
        entity.getEmployeeCode(),
        entity.getFirstName(),
        entity.getLastName(),
        entity.getPhone(),
        entity.getPhotoRef(),
        entity.getVendorName(),
        VerificationStatus.valueOf(entity.getVerificationStatus()),
        entity.getVerifiedUntil(),
        entity.isActive(),
        entity.getVersion());
  }

  TransportStaffEntity toEntity(TransportStaff staff) {
    return new TransportStaffEntity(
        staff.id().value(),
        staff.tenantId().value(),
        staff.schoolId().value(),
        staff.userId().map(UserId::value).orElse(null),
        staff.staffType().name(),
        staff.employeeCode().orElse(null),
        staff.firstName(),
        staff.lastName(),
        staff.phone(),
        staff.photoRef().orElse(null),
        staff.vendorName().orElse(null),
        staff.verificationStatus().name(),
        staff.verifiedUntil().orElse(null),
        staff.active(),
        staff.version());
  }

  /**
   * Copies mutable state onto a managed entity, so Hibernate's dirty checking and {@code @Version}
   * apply. Persisting a freshly built detached entity would bypass optimistic locking and let a
   * concurrent edit silently win.
   */
  void applyTo(TransportStaffEntity managed, TransportStaff staff) {
    managed.applyMutableState(
        staff.firstName(),
        staff.lastName(),
        staff.phone(),
        staff.verificationStatus().name(),
        staff.verifiedUntil().orElse(null),
        staff.active());
  }
}
