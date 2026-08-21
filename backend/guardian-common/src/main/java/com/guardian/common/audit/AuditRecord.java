package com.guardian.common.audit;

import com.guardian.common.tenant.TenantId;
import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * An append-only record of a safety-relevant action.
 *
 * <p>Written in the same transaction as the change it describes (BR-AUD-002). No update or delete
 * path exists within the retention period (BR-AUD-001) — enforced by database grants and a trigger,
 * not by convention.
 *
 * @param actorRole the role held <em>at the time</em>; roles change, and the record must show what
 *     was true when the action happened
 * @param reason required for overrides (BR-AUD-004) — an override without a reason is not evidence
 * @param subjectType polymorphic reference with no foreign key: a subject may be archived while its
 *     audit trail must remain readable
 */
public record AuditRecord(
    TenantId tenantId,
    UUID actorId,
    ActorType actorType,
    String actorRole,
    String action,
    String subjectType,
    UUID subjectId,
    String reason,
    Source source,
    UUID correlationId,
    Map<String, Object> beforeValues,
    Map<String, Object> afterValues,
    Instant occurredAt) {

  public AuditRecord {
    Objects.requireNonNull(tenantId, "tenantId");
    Objects.requireNonNull(actorType, "actorType");
    Objects.requireNonNull(action, "action");
    Objects.requireNonNull(subjectType, "subjectType");
    Objects.requireNonNull(subjectId, "subjectId");
    Objects.requireNonNull(source, "source");
    Objects.requireNonNull(occurredAt, "occurredAt");
    beforeValues = Collections.unmodifiableMap(new LinkedHashMap<>(nullToEmpty(beforeValues)));
    afterValues = Collections.unmodifiableMap(new LinkedHashMap<>(nullToEmpty(afterValues)));
  }

  private static Map<String, Object> nullToEmpty(Map<String, Object> values) {
    return values == null ? Map.of() : values;
  }

  public enum ActorType {
    USER,
    SYSTEM,
    DEVICE,
    PLATFORM_OPERATOR
  }

  public enum Source {
    API,
    DEVICE,
    JOB,
    PLATFORM_OPS
  }

  public static Builder builder() {
    return new Builder();
  }

  /** Fluent construction — an audit record has many optional fields and few required ones. */
  public static final class Builder {
    private TenantId tenantId;
    private UUID actorId;
    private ActorType actorType = ActorType.USER;
    private String actorRole;
    private String action;
    private String subjectType;
    private UUID subjectId;
    private String reason;
    private Source source = Source.API;
    private UUID correlationId;
    private Map<String, Object> beforeValues = Map.of();
    private Map<String, Object> afterValues = Map.of();
    private Instant occurredAt = Instant.now();

    public Builder tenantId(TenantId tenantId) {
      this.tenantId = tenantId;
      return this;
    }

    public Builder actor(UUID actorId, ActorType actorType, String actorRole) {
      this.actorId = actorId;
      this.actorType = actorType;
      this.actorRole = actorRole;
      return this;
    }

    public Builder action(String action) {
      this.action = action;
      return this;
    }

    public Builder subject(String subjectType, UUID subjectId) {
      this.subjectType = subjectType;
      this.subjectId = subjectId;
      return this;
    }

    public Builder reason(String reason) {
      this.reason = reason;
      return this;
    }

    public Builder source(Source source) {
      this.source = source;
      return this;
    }

    public Builder correlationId(UUID correlationId) {
      this.correlationId = correlationId;
      return this;
    }

    public Builder before(Map<String, Object> beforeValues) {
      this.beforeValues = beforeValues;
      return this;
    }

    public Builder after(Map<String, Object> afterValues) {
      this.afterValues = afterValues;
      return this;
    }

    public Builder occurredAt(Instant occurredAt) {
      this.occurredAt = occurredAt;
      return this;
    }

    public AuditRecord build() {
      return new AuditRecord(
          tenantId,
          actorId,
          actorType,
          actorRole,
          action,
          subjectType,
          subjectId,
          reason,
          source,
          correlationId,
          beforeValues,
          afterValues,
          occurredAt);
    }
  }
}
