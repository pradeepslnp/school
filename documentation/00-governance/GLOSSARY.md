# GLOSSARY

**Document tier:** 0 — Governance
**Status:** Active

Canonical vocabulary. These terms mean exactly this in documentation, code, database columns, API fields, and UI copy. Synonyms listed under "Not called" are forbidden — consistency of naming is what lets the traceability model work.

---

## Tenancy

**Organization**
A school group. **The tenant** — the isolation and billing boundary. A single independent school is an organization containing one school.
*Not called:* client, customer, account, group.

**School**
A school within an organization. Has its own address, timings, and staff.

**Branch**
An optional subdivision of a school (campus, wing, shift). Present in the model so chains do not need a redesign; may be unused by a tenant.

**Tenant Context**
The resolved organization for the current request. Established once by a filter and propagated implicitly; never passed as a method argument.

---

## People

**Student**
A child transported by the platform. Belongs to exactly one school.

**Guardian**
An adult with a recorded relationship to a student and a defined set of rights over that student (view, receive notifications, authorise handover). A student may have several.
*Not called:* parent (in code). "Parent" is used in UI copy where it reads more naturally.

**Authorised Pickup Person**
An adult permitted to receive a student at handover who is not a guardian — for example, a relative or a domestic helper. Time-bounded and revocable.

**Driver**
The person operating a vehicle. Holds credentials with expiry tracked for compliance.

**Attendant**
The staff member responsible for students inside the vehicle. Performs boarding and handover verification.
*Also known as:* bus matron, conductor, helper. Use **Attendant** in code.

**Transport Manager**
School staff member who owns fleet, routes, and incident response.

**Super Admin**
Platform operator. Can act across organizations; every such action is audited.

---

## Fleet

**Vehicle**
A bus or van. Belongs to a school. Carries documents with expiry dates.

**Device**
A GPS unit fitted to a vehicle. Reports position; may report ignition, speed, and panic.

**Vehicle Document**
A compliance artefact (registration, fitness, insurance, permit) with an expiry date. Document *types* are tenant configuration, not code — see [`PRODUCT_PRINCIPLES.md`](../PRODUCT_PRINCIPLES.md) §5.

---

## Routes and Trips

**Route**
A named, ordered sequence of stops served by a school, normally with a default vehicle.

**Stop**
A geographic point on a route with a name, coordinates, geofence radius, and scheduled time.

**Route Assignment**
The link between a student and a stop on a route, for a direction. A student may have a different pickup and drop stop.

**Trip**
**One execution of a route, on one date, in one direction.** The central operational entity. Has a lifecycle:

```
SCHEDULED → STARTED → IN_PROGRESS → COMPLETED → CLOSED
                  ↘ CANCELLED
```

**Direction**
`PICKUP` (home → school) or `DROP` (school → home).

**Trip Close**
The reconciliation step after a trip completes, at which every expected student must be accounted for. See `BR-TRIP-020`.

---

## Safety Events

**Boarding Event**
An immutable record that a student boarded (`BOARD`) or alighted (`ALIGHT`) a vehicle, with actor, time, location, method, and trip.
*Immutable:* corrections are new compensating records, never updates.

**Handover**
Verified release of a student to a guardian or authorised pickup person at a drop stop.

**Handover Verification Method**
How the receiving adult was verified — QR code, OTP, PIN, or attendant visual confirmation. Which methods are acceptable is tenant configuration.

**Override**
A permitted deviation from a rule (for example, releasing a student to an unverified adult). Requires a reason, an authorised actor, and an audit record. Overrides are never silent.

**Left-Behind Detection**
The control that identifies a student who boarded but has no corresponding alight record at trip close. See `BR-SAFE-001`.

**SOS**
A panic alert raised by a driver, attendant, or device. Highest-priority event class; escalates on a timer until acknowledged.

**Incident**
A recorded event affecting safety or service — breakdown, accident, behavioural issue, medical event. Has severity, status, and an escalation trail.

---

## Tracking

**Position**
A timestamped location report from a device: coordinates, speed, heading, ignition state.

**Live Position**
The most recent position of a vehicle, held in a hot cache for fast reads.

**Position History**
The durable time-series record of positions, retained per tenant policy.

**Geofence**
A circular area around a stop or school. Entry and exit generate events.

**Route Deviation**
A vehicle exceeding the configured corridor distance from its route path.

**ETA**
Estimated time of arrival of a trip at a specific stop.

---

## Notifications

**Notification Event**
A domain occurrence that may notify someone — for example `STUDENT_BOARDED`.

**Notification Template**
Tenant- and locale-specific rendering of an event into channel content.

**Channel**
A delivery mechanism: push, SMS, email, in-app.

**Notification Preference**
A recipient's per-event, per-channel opt-in. Safety-critical notifications ignore preferences — see `BR-NTF-006`.

---

## Access Control

**Role**
A named set of permissions, scoped to an organization.

**Permission**
A single capability, identified as `PERM-<AREA>-<ACTION>`, for example `PERM-TRIP-VIEW`.

**Scope**
The boundary within which a permission applies: platform, organization, school, route, or own-children.

---

## Records

**Audit Record**
Append-only entry: actor, action, subject, timestamp, source, reason. Written in the same transaction as the change it describes.

**Soft Delete**
Marking a row inactive rather than removing it. Safety and audit records are never deleted, soft or otherwise, before their retention period elapses.

---

## Naming Conventions

| Context | Style | Example |
|---|---|---|
| Java class | PascalCase | `BoardingEvent` |
| Java package | lowercase, feature-first | `com.guardian.trip.domain` |
| Database table | snake_case, plural | `boarding_events` |
| Database column | snake_case | `boarded_at` |
| JSON field | camelCase | `boardedAt` |
| Dart class | PascalCase | `BoardingEvent` |
| Dart file | snake_case | `boarding_event.dart` |
| Enum value | SCREAMING_SNAKE | `IN_PROGRESS` |
| Feature ID | `AREA-nnn` | `TRK-003` |
| Business rule ID | `BR-AREA-nnn` | `BR-BOARD-004` |
