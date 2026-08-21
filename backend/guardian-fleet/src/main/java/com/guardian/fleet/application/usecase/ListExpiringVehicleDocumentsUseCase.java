package com.guardian.fleet.application.usecase;

import com.guardian.fleet.application.port.VehicleDocumentRepository;
import com.guardian.fleet.domain.VehicleDocument;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lists mandatory documents expiring soon (feature FLT-003).
 *
 * <p>Serves the manual "what's expiring" view a fleet manager checks ahead of the daily warning
 * job. This is not a citation of BR-FLEET-003: that rule is the <em>escalating, scheduled</em>
 * notification, which depends on MOD-12's dispatch job calling into this module — wiring that does
 * not exist yet. BR-FLEET-003 stays in the traceability baseline until it does.
 */
@Service
public class ListExpiringVehicleDocumentsUseCase {

  private static final int DEFAULT_WINDOW_DAYS = 30;
  private static final int MAX_RESULTS = 200;

  private final VehicleDocumentRepository documentRepository;
  private final Clock clock;

  public ListExpiringVehicleDocumentsUseCase(
      VehicleDocumentRepository documentRepository, Clock clock) {
    this.documentRepository = documentRepository;
    this.clock = clock;
  }

  @Transactional(readOnly = true)
  public List<VehicleDocument> withinDays(int days) {
    int window = days > 0 ? days : DEFAULT_WINDOW_DAYS;
    return documentRepository.findMandatoryExpiringWithin(
        LocalDate.now(clock), window, MAX_RESULTS);
  }
}
