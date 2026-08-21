package com.guardian.staff.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.port.StaffCredentialRepository;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.application.result.StaffEligibilityResult;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.domain.VerificationStatus;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/**
 * Unit tests for the staff half of trip-start eligibility
 * (guardian-docs/03-database/tables/MOD-05-06-fleet-staff.md, "Trip-Start Eligibility").
 */
@ExtendWith(MockitoExtension.class)
class GetStaffEligibilityUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());
  private static final Clock FIXED_CLOCK =
      Clock.fixed(Instant.parse("2026-08-03T00:00:00Z"), ZoneOffset.UTC);

  @Mock private TransportStaffRepository staffRepository;
  @Mock private StaffCredentialRepository credentialRepository;

  private GetStaffEligibilityUseCase useCase;
  private StaffId staffId;

  @BeforeEach
  void setUp() {
    useCase = new GetStaffEligibilityUseCase(staffRepository, credentialRepository, FIXED_CLOCK);
    staffId = StaffId.generate();
  }

  private TransportStaff verifiedStaff() {
    return new TransportStaff(
        staffId,
        TENANT,
        SCHOOL,
        null,
        StaffType.DRIVER,
        "EMP-001",
        "Ravi",
        "Kumar",
        "9876500001",
        null,
        null,
        VerificationStatus.VERIFIED,
        LocalDate.of(2027, 1, 1),
        true,
        0L);
  }

  @Test
  @DisplayName("a verified driver with no expired mandatory credential is eligible")
  void eligibleWhenVerifiedAndCompliant() {
    when(staffRepository.findById(staffId)).thenReturn(Optional.of(verifiedStaff()));
    when(credentialRepository.findMandatoryByStaff(staffId)).thenReturn(List.of());

    StaffEligibilityResult result = useCase.execute(staffId);

    assertThat(result.eligible()).isTrue();
    assertThat(result.checks()).allMatch(c -> c.passed());
  }

  @Test
  @BusinessRule("BR-STAFF-002")
  @DisplayName("a lapsed verification makes the staff member ineligible, naming the check")
  void ineligibleWhenVerificationHasLapsed() {
    TransportStaff lapsed =
        new TransportStaff(
            staffId,
            TENANT,
            SCHOOL,
            null,
            StaffType.DRIVER,
            "EMP-001",
            "Ravi",
            "Kumar",
            "9876500001",
            null,
            null,
            VerificationStatus.VERIFIED,
            LocalDate.of(2026, 1, 1),
            true,
            0L);

    when(staffRepository.findById(staffId)).thenReturn(Optional.of(lapsed));
    when(credentialRepository.findMandatoryByStaff(staffId)).thenReturn(List.of());

    StaffEligibilityResult result = useCase.execute(staffId);

    assertThat(result.eligible()).isFalse();
    assertThat(result.checks())
        .anySatisfy(
            check -> {
              assertThat(check.check()).isEqualTo("STAFF_VERIFIED");
              assertThat(check.passed()).isFalse();
              assertThat(check.businessRule()).isEqualTo("BR-STAFF-002");
            });
  }

  @Test
  @BusinessRule("BR-STAFF-001")
  @DisplayName(
      "an expired mandatory credential makes the staff member ineligible, naming the check")
  void ineligibleWhenAMandatoryCredentialHasExpired() {
    StaffCredential expired =
        StaffCredential.create(
            TENANT,
            staffId,
            "DRIVING_LICENCE",
            "DL-1",
            "LMV",
            null,
            LocalDate.of(2026, 7, 15),
            true,
            null);

    when(staffRepository.findById(staffId)).thenReturn(Optional.of(verifiedStaff()));
    when(credentialRepository.findMandatoryByStaff(staffId)).thenReturn(List.of(expired));

    StaffEligibilityResult result = useCase.execute(staffId);

    assertThat(result.eligible()).isFalse();
    assertThat(result.checks())
        .anySatisfy(
            check -> {
              assertThat(check.check()).isEqualTo("MANDATORY_CREDENTIALS_VALID");
              assertThat(check.passed()).isFalse();
              assertThat(check.businessRule()).isEqualTo("BR-STAFF-001");
            });
  }

  @Test
  @DisplayName("a credential expiring exactly today is not yet expired")
  void credentialExpiringTodayIsNotExpired() {
    StaffCredential expiresToday =
        StaffCredential.create(
            TENANT,
            staffId,
            "DRIVING_LICENCE",
            "DL-1",
            "LMV",
            null,
            LocalDate.of(2026, 8, 3),
            true,
            null);

    when(staffRepository.findById(staffId)).thenReturn(Optional.of(verifiedStaff()));
    when(credentialRepository.findMandatoryByStaff(staffId)).thenReturn(List.of(expiresToday));

    assertThat(useCase.execute(staffId).eligible()).isTrue();
  }
}
