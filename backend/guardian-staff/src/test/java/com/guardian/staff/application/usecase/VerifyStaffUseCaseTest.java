package com.guardian.staff.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.staff.application.command.VerifyStaffCommand;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.StaffType;
import com.guardian.staff.domain.TransportStaff;
import com.guardian.staff.domain.VerificationStatus;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Unit tests for the use case. Ports are mocked; no Spring context, no database. */
@ExtendWith(MockitoExtension.class)
class VerifyStaffUseCaseTest {

  private static final TenantId TENANT = TenantId.of(UUID.randomUUID());
  private static final SchoolId SCHOOL = SchoolId.of(UUID.randomUUID());
  private static final UUID ACTOR = UUID.randomUUID();

  @Mock private TransportStaffRepository staffRepository;
  @Mock private AuditPort auditPort;

  private VerifyStaffUseCase useCase;
  private StaffId staffId;

  @BeforeEach
  void setUp() {
    useCase = new VerifyStaffUseCase(staffRepository, auditPort);
    staffId = StaffId.generate();
    TenantContext.set(TENANT);
  }

  @AfterEach
  void tearDown() {
    TenantContext.clear();
  }

  private TransportStaff pendingStaff() {
    return TransportStaff.create(
        TENANT, SCHOOL, StaffType.DRIVER, "EMP-001", "Ravi", "Kumar", "9876500001", null);
  }

  private VerifyStaffCommand aCommand() {
    return new VerifyStaffCommand(
        staffId, "POLICE_BACKGROUND_CHECK", LocalDate.of(2027, 8, 3), "REF-1", ACTOR, "OPS_ADMIN");
  }

  @Test
  @BusinessRule("BR-STAFF-002")
  @DisplayName("verifying sets status to VERIFIED with the given verifiedUntil")
  void verifiesStaff() {
    when(staffRepository.findById(staffId)).thenReturn(Optional.of(pendingStaff()));
    when(staffRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    TransportStaff verified = useCase.execute(aCommand());

    assertThat(verified.verificationStatus()).isEqualTo(VerificationStatus.VERIFIED);
    assertThat(verified.verifiedUntil()).contains(LocalDate.of(2027, 8, 3));
  }

  @Test
  @DisplayName("a missing staff member is reported as not found")
  void throwsWhenStaffNotFound() {
    when(staffRepository.findById(staffId)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(aCommand()))
        .isInstanceOf(ResourceNotFoundException.class);
  }

  @Test
  @com.guardian.common.BusinessRule("BR-AUD-002")
  @DisplayName("records an audit entry carrying the verification evidence, not just the outcome")
  void writesAuditRecord() {
    when(staffRepository.findById(staffId)).thenReturn(Optional.of(pendingStaff()));
    when(staffRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    useCase.execute(aCommand());

    ArgumentCaptor<AuditRecord> captor = ArgumentCaptor.forClass(AuditRecord.class);
    verify(auditPort).record(captor.capture());

    AuditRecord record = captor.getValue();
    assertThat(record.action()).isEqualTo("TRANSPORT_STAFF_VERIFIED");
    assertThat(record.actorId()).isEqualTo(ACTOR);
    assertThat(record.actorRole()).isEqualTo("OPS_ADMIN");
    assertThat(record.tenantId()).isEqualTo(TENANT);
    assertThat(record.afterValues()).containsEntry("verificationType", "POLICE_BACKGROUND_CHECK");
    assertThat(record.afterValues()).containsEntry("verifiedUntil", "2027-08-03");
  }
}
