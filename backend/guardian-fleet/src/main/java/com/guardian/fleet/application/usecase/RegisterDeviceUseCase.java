package com.guardian.fleet.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.fleet.application.command.RegisterDeviceCommand;
import com.guardian.fleet.application.port.DeviceCredentialHasher;
import com.guardian.fleet.application.port.DeviceRepository;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceIdentifier;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Explicitly registers a GPS device (feature FLT-004).
 *
 * <p>Registration is always operator-initiated. There is no code path here that creates a {@link
 * Device} from an ingested position report — {@code guardian-tracking} (MOD-10, not yet built) will
 * call {@link DeviceRepository#findByIdentifierGlobally} to look a device up and never to create
 * one.
 *
 * <p>That absence is not, by itself, a test of BR-FLEET-006 — the rule describes what the ingestion
 * pipeline does with an <em>unknown</em> identifier, and nothing in this module ingests anything.
 * BR-FLEET-006 stays in the traceability baseline until MOD-10 exists and can demonstrate it.
 */
@Service
@BusinessRule("BR-AUD-002")
public class RegisterDeviceUseCase {

  private final DeviceRepository deviceRepository;
  private final DeviceCredentialHasher credentialHasher;
  private final AuditPort auditPort;

  public RegisterDeviceUseCase(
      DeviceRepository deviceRepository,
      DeviceCredentialHasher credentialHasher,
      AuditPort auditPort) {
    this.deviceRepository = deviceRepository;
    this.credentialHasher = credentialHasher;
    this.auditPort = auditPort;
  }

  @Transactional
  public Device execute(RegisterDeviceCommand command) {
    TenantId tenantId = TenantContext.require();

    Device device =
        Device.register(
            tenantId,
            DeviceIdentifier.of(command.deviceIdentifier()),
            command.vendorCode(),
            credentialHasher.hash(command.credentialSecret()));

    Device saved = deviceRepository.save(device);

    auditPort.record(
        AuditRecord.builder()
            .tenantId(tenantId)
            .actor(command.actorId(), AuditRecord.ActorType.USER, command.actorRole())
            .action("DEVICE_REGISTERED")
            .subject("Device", saved.id().value())
            .after(describe(saved))
            .build());

    return saved;
  }

  private static Map<String, Object> describe(Device device) {
    Map<String, Object> values = new LinkedHashMap<>();
    values.put("deviceIdentifier", device.deviceIdentifier().value());
    values.put("vendorCode", device.vendorCode());
    return values;
  }
}
