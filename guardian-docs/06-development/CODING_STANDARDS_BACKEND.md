# BACKEND CODING STANDARDS

**Document tier:** 6 — Development
**Stack:** Java 21, Spring Boot 3.x, Gradle (Kotlin DSL), PostgreSQL, Flyway

Structural rules are in [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md); their enforcement in [`ARCHITECTURE_ENFORCEMENT.md`](ARCHITECTURE_ENFORCEMENT.md). This document covers how the code inside those structures is written.

---

## Language

Java 21. Use `record` for immutable carriers (commands, DTOs, value objects), sealed interfaces for closed hierarchies, pattern-matching `switch` for exhaustive dispatch, and text blocks for SQL.

`var` only where the type is obvious from the right-hand side.

**No Lombok.** Records cover most of what it was used for, and IDE-generated boilerplate is greppable in a way annotation processing is not.

---

## Immutability

Domain objects are immutable. State changes return new instances:

```java
public School deactivate() {
    return new School(id, organizationId, code, name, timezone, Status.INACTIVE, version);
}
```

Fields `final`. Collections defensively copied on the way in and returned unmodifiable.

---

## Null

**`null` never crosses a public boundary.** Use `Optional` for absent return values.

`Optional` is a return type only — never a field, never a parameter. An optional parameter means two methods.

Constructor parameters are validated:

```java
public School(SchoolId id, /* … */) {
    this.id = Objects.requireNonNull(id, "id");
    this.code = Objects.requireNonNull(code, "code");
}
```

---

## Value Objects Over Primitives

```java
public record SchoolId(UUID value) {
    public SchoolId {
        Objects.requireNonNull(value, "value");
    }
}
```

```java
// wrong — nothing stops these being swapped
void assign(UUID studentId, UUID stopId);

// right — the compiler stops it
void assign(StudentId studentId, StopId stopId);
```

In a domain with a dozen UUID-keyed entities, swapping two arguments is a defect the type system should catch. It matters more here than in most systems: swapping a student and a stop in a boarding call produces a plausible-looking, wrong safety record.

Validation lives in the value object, so an invalid `Coordinates` cannot exist.

---

## Errors

Typed domain exceptions carrying an error code — never strings or booleans.

```java
public abstract class DomainException extends RuntimeException {
    private final ErrorCode errorCode;
    private final Map<String, Object> context;
}

public class VehicleDocumentExpiredException extends DomainException {
    public VehicleDocumentExpiredException(VehicleId vehicleId, String documentType, LocalDate expiredOn) {
        super(ErrorCode.VEHICLE_DOCUMENT_EXPIRED,
              Map.of("vehicleId", vehicleId, "documentType", documentType, "expiredOn", expiredOn));
    }
}
```

**No user-facing message in the exception** (BR-CFG-005). The `ErrorCode` maps to a localised `messageKey`, and the `context` populates its variables.

One `@RestControllerAdvice` maps domain exceptions to the envelope in [`ERROR_CATALOG.md`](../04-api/ERROR_CATALOG.md). Never catch and rethrow at multiple layers; never swallow.

Errors returned to clients leak no internal detail — no stack traces, no SQL, no internal identifiers.

---

## Transactions

`@Transactional` on the **use case**, never on a repository or a controller.

```java
@Transactional
public BoardingEvent execute(RecordBoardingCommand command) {
    var event = boardingRepository.save(domainEvent);
    auditPort.record(AuditRecord.of(...));   // SAME transaction — BR-AUD-002 🔴
    domainEvents.publishAfterCommit(new StudentBoarded(event));
    return event;
}
```

Three rules:

1. **Audit writes share the transaction.** If audit fails, the change rolls back (BR-AUD-002 🔴).
2. **Domain events publish after commit** — a consumer must never observe state that later rolls back.
3. **No outbound call inside a transaction** — no HTTP, no provider SDK, no notification dispatch. A slow provider would hold a database transaction open and turn a provider outage into a database outage ([`INTEGRATION_ARCHITECTURE.md`](../02-system-design/INTEGRATION_ARCHITECTURE.md)).

Keep transactions short. Read-only where applicable.

---

## Business Rule References

Every rule implementation cites its ID:

```java
/** BR-FLEET-002: a vehicle with an expired mandatory document may not be assigned. */
private void assertVehicleEligible(Vehicle vehicle) { … }
```

This is what makes the traceability check meaningful and lets a reader find the *why* without guessing.

---

## Repository Methods

Named for intent, not mechanism:

```java
List<Trip> findActiveTripsForVehicle(VehicleId vehicleId);   // yes
List<TripEntity> findByVehicleIdAndStatusIn(...);            // no — leaks the ORM
```

**Every history or list query is bounded** — a time range, a limit, or both. An unbounded query against `position_history` will find billions of rows ([`INDEXING_AND_PARTITIONING.md`](../03-database/INDEXING_AND_PARTITIONING.md)).

Explicit fetch strategies; no lazy-loading surprises escaping the adapter.

---

## Logging

```java
log.info("Trip started tripId={} vehicleId={} manifestSize={}",
         trip.id(), trip.vehicleId(), manifest.size());
```

Structured JSON with correlation ID and tenant ID on every entry.

**Never logged:** passwords, tokens, OTPs, provider credentials, full child records, guardian contact details. **Students appear as IDs, never names** — verified by a test scanning log output against a sensitive-field denylist ([`AUDIT_AND_LOGGING.md`](../02-system-design/AUDIT_AND_LOGGING.md)).

Log at the boundary where a decision is made, not at every layer the call passes through.

---

## Concurrency

Optimistic locking via the `version` column; a conflict returns `409`, never a silent overwrite.

No shared mutable state. No `synchronized` in application code — if coordination is needed, the database is the coordination point.

Scheduled jobs are idempotent and safe to run concurrently across instances, guarded by a database lock.

---

## Comments

Comment **why**, not what.

```java
// received_at, not device_time: a device buffering through a coverage gap
// reports hours-old positions, which would scatter writes into old partitions.
```

Javadoc on public application and domain APIs. **No commented-out code. No `TODO` without a linked issue** ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §15).

---

## Formatting

Google Java Format, 120 columns, enforced by Spotless in CI. Import order fixed; no wildcard imports. Static analysis via Error Prone and SpotBugs; findings above threshold fail the build.

---

## Dependencies

Every addition is justified in review. Prefer the JDK, then Spring Boot's managed dependencies. Versions come from the Spring Boot BOM. Dependency and container scanning runs in CI; findings above threshold fail the build.

---

## Checklist Before Merge

- [ ] Business rule IDs cited on rule implementations
- [ ] Audit write in the same transaction, where applicable
- [ ] No outbound calls inside a transaction
- [ ] Domain free of framework imports
- [ ] Endpoint declares a permission
- [ ] Errors typed, with codes in the catalog
- [ ] No sensitive data in logs
- [ ] Queries bounded and indexed
- [ ] Tenant isolation test present for new tables

Full gate: [`DEFINITION_OF_DONE.md`](DEFINITION_OF_DONE.md).
