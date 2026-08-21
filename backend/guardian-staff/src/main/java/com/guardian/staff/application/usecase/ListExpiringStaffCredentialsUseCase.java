package com.guardian.staff.application.usecase;

import com.guardian.staff.application.port.StaffCredentialRepository;
import com.guardian.staff.domain.StaffCredential;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lists mandatory credentials expiring soon (feature STF-003).
 *
 * <p>Serves the manual "who's expiring" view a transport manager checks ahead of the daily warning
 * job. This is not a citation of BR-STAFF-003: that rule is the <em>escalating, scheduled</em>
 * notification that also blocks future duty assignment on expiry, which depends on MOD-12's
 * dispatch job and MOD-07's {@code duty_assignments} table — neither exists yet. BR-STAFF-003 stays
 * in the traceability baseline until both do.
 */
@Service
public class ListExpiringStaffCredentialsUseCase {

  private static final int DEFAULT_WINDOW_DAYS = 30;
  private static final int MAX_RESULTS = 200;

  private final StaffCredentialRepository credentialRepository;
  private final Clock clock;

  public ListExpiringStaffCredentialsUseCase(
      StaffCredentialRepository credentialRepository, Clock clock) {
    this.credentialRepository = credentialRepository;
    this.clock = clock;
  }

  @Transactional(readOnly = true)
  public List<StaffCredential> withinDays(int days) {
    int window = days > 0 ? days : DEFAULT_WINDOW_DAYS;
    return credentialRepository.findMandatoryExpiringWithin(
        LocalDate.now(clock), window, MAX_RESULTS);
  }
}
