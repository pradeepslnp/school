package com.guardian.fleet.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Map;
import java.util.Objects;

/**
 * A GPS device's hardware identifier (IMEI, serial number, or vendor-issued ID).
 *
 * <p><strong>Globally unique</strong>, not scoped to a tenant — ingestion resolves the device
 * before it knows the tenant (guardian-docs/02-system-design/REALTIME_TRACKING_DESIGN.md). An
 * unknown identifier is logged and ignored by the ingestion pipeline, never auto-registered
 * (BR-FLEET-006) — auto-registration would let anyone inject positions for a vehicle they do not
 * own.
 */
public record DeviceIdentifier(String value) {

  private static final int MAX_LENGTH = 128;

  public DeviceIdentifier {
    Objects.requireNonNull(value, "value");
    value = value.trim();
    if (value.isEmpty() || value.length() > MAX_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_INVALID_FORMAT, "BR-FLEET-006", Map.of("field", "deviceIdentifier"));
    }
  }

  public static DeviceIdentifier of(String value) {
    return new DeviceIdentifier(value);
  }

  @Override
  public String toString() {
    return value;
  }
}
