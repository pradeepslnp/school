# ENTITY RELATIONSHIP DIAGRAM

**Document tier:** 3 — Database
**Status:** Active

Diagrams show key columns only. Standard columns (`id`, `tenant_id`, audit columns, `version`) are omitted — see [`CONVENTIONS.md`](CONVENTIONS.md). Full specifications in [`tables/`](tables/).

---

## Tenancy, Identity, Configuration

```mermaid
erDiagram
    ORGANIZATIONS {
        varchar code UK
        varchar name
        uuid region_profile_id FK
        varchar status
    }
    SCHOOLS {
        uuid organization_id FK
        varchar code
        varchar name
        varchar timezone
    }
    BRANCHES {
        uuid school_id FK
        varchar name
    }
    USERS {
        varchar email
        varchar phone
        varchar status
    }
    ROLES {
        varchar code
        varchar name
    }
    PERMISSIONS {
        varchar code UK
    }
    USER_ROLES {
        uuid user_id FK
        uuid role_id FK
    }
    USER_SCOPES {
        uuid user_id FK
        varchar scope_level
        uuid scope_ref_id
    }
    SESSIONS {
        uuid user_id FK
        varchar refresh_token_hash
        timestamptz expires_at
        boolean is_revoked
    }
    REGION_PROFILES {
        varchar code UK
        varchar country_code
    }

    ORGANIZATIONS ||--o{ SCHOOLS : contains
    SCHOOLS ||--o{ BRANCHES : "may have"
    REGION_PROFILES ||--o{ ORGANIZATIONS : configures
    USERS ||--o{ USER_ROLES : has
    ROLES ||--o{ USER_ROLES : "granted via"
    ROLES ||--o{ ROLE_PERMISSIONS : grants
    PERMISSIONS ||--o{ ROLE_PERMISSIONS : "granted via"
    USERS ||--o{ USER_SCOPES : "scoped by"
    USERS ||--o{ SESSIONS : holds
```

`permissions` is platform reference data — no `tenant_id`, no RLS. Tenants assign permissions to roles; they cannot invent permissions ([`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md)).

---

## Students and Guardians

```mermaid
erDiagram
    STUDENTS {
        uuid school_id FK
        varchar admission_no
        varchar first_name
        varchar last_name
        date date_of_birth
        varchar enrolment_status
        uuid student_class_id FK
        varchar photo_ref
    }
    STUDENT_CREDENTIALS {
        uuid student_id FK
        varchar credential_type
        varchar credential_hash
        boolean is_active
    }
    GUARDIANS {
        uuid user_id FK
        varchar first_name
        varchar last_name
        varchar phone
    }
    GUARDIAN_STUDENT_LINKS {
        uuid guardian_id FK
        uuid student_id FK
        varchar relationship_type
        boolean can_view
        boolean can_receive_notifications
        boolean can_authorise_handover
        boolean can_declare_absence
        boolean is_active
    }
    AUTHORISED_PICKUP_PERSONS {
        uuid student_id FK
        uuid nominated_by_guardian_id FK
        varchar full_name
        varchar phone
        varchar photo_ref
        timestamptz valid_from
        timestamptz valid_until
        boolean is_active
    }
    CUSTODY_RESTRICTIONS {
        uuid student_id FK
        uuid restricted_guardian_id FK
        varchar restriction_type
        text reason
        boolean is_active
    }

    STUDENTS ||--o{ STUDENT_CREDENTIALS : carries
    STUDENTS ||--o{ GUARDIAN_STUDENT_LINKS : "linked to"
    GUARDIANS ||--o{ GUARDIAN_STUDENT_LINKS : "linked to"
    STUDENTS ||--o{ AUTHORISED_PICKUP_PERSONS : "may be collected by"
    GUARDIAN_STUDENT_LINKS ||--o{ AUTHORISED_PICKUP_PERSONS : nominates
    STUDENTS ||--o{ CUSTODY_RESTRICTIONS : protected_by
    GUARDIANS ||--o{ CUSTODY_RESTRICTIONS : restricted_by
```

**The four boolean rights columns are the design point** (BR-GRD-001). `relationship_type` is descriptive; the booleans are authoritative. `custody_restrictions` overrides them entirely (BR-GRD-008, BR-HAND-006).

---

## Fleet, Staff, Routes

```mermaid
erDiagram
    VEHICLES {
        uuid school_id FK
        varchar registration_no
        integer seating_capacity
        varchar status
    }
    VEHICLE_DOCUMENTS {
        uuid vehicle_id FK
        varchar document_type
        date issued_on
        date expires_on
        boolean is_mandatory
    }
    DEVICES {
        uuid vehicle_id FK
        varchar device_identifier UK
        varchar vendor_code
        boolean is_active
    }
    TRANSPORT_STAFF {
        uuid school_id FK
        uuid user_id FK
        varchar staff_type
        varchar verification_status
        date verified_until
    }
    STAFF_CREDENTIALS {
        uuid staff_id FK
        varchar credential_type
        varchar credential_class
        date expires_on
    }
    ROUTES {
        uuid school_id FK
        varchar name
        uuid default_vehicle_id FK
        boolean is_active
    }
    STOPS {
        uuid route_id FK
        integer sequence_no
        varchar name
        numeric latitude
        numeric longitude
        integer geofence_radius_m
        time scheduled_pickup_time
        time scheduled_drop_time
    }
    ROUTE_STUDENT_ASSIGNMENTS {
        uuid route_id FK
        uuid stop_id FK
        uuid student_id FK
        varchar direction
        boolean is_active
    }

    VEHICLES ||--o{ VEHICLE_DOCUMENTS : holds
    VEHICLES ||--o| DEVICES : "fitted with"
    TRANSPORT_STAFF ||--o{ STAFF_CREDENTIALS : holds
    ROUTES ||--o{ STOPS : "ordered by sequence_no"
    ROUTES ||--o{ ROUTE_STUDENT_ASSIGNMENTS : serves
    STOPS ||--o{ ROUTE_STUDENT_ASSIGNMENTS : "boarding point"
    VEHICLES ||--o{ ROUTES : "default vehicle"
```

`document_type` and `credential_type` values come from the region profile (ADR-0007) — they are reference data, not an enum in code.

---

## Trips and Safety Events

The evidentiary core of the platform.

```mermaid
erDiagram
    TRIPS {
        uuid route_id FK
        uuid vehicle_id FK
        date service_date
        varchar direction
        varchar status
        timestamptz started_at
        timestamptz completed_at
        timestamptz closed_at
    }
    TRIP_STAFF {
        uuid trip_id FK
        uuid staff_id FK
        varchar role
        timestamptz assigned_at
    }
    TRIP_MANIFESTS {
        uuid trip_id FK
        uuid student_id FK
        uuid expected_stop_id FK
        varchar status
    }
    TRIP_MANIFEST_AMENDMENTS {
        uuid trip_id FK
        uuid student_id FK
        varchar amendment_type
        uuid actor_id
        text reason
    }
    BOARDING_EVENTS {
        uuid trip_id FK
        uuid student_id FK
        uuid stop_id FK
        varchar event_type
        varchar verification_method
        uuid actor_id
        uuid client_event_id UK
        uuid corrects_event_id FK
        boolean is_override
        text override_reason
        timestamptz occurred_at
        timestamptz recorded_at
        integer clock_skew_seconds
    }
    HANDOVERS {
        uuid boarding_event_id FK
        uuid received_by_guardian_id FK
        uuid received_by_pickup_person_id FK
        varchar verification_method
        boolean is_override
        text override_reason
        varchar unverified_receiver_name
    }
    RECONCILIATIONS {
        uuid trip_id FK
        varchar status
        timestamptz started_at
        timestamptz resolved_at
    }
    RECONCILIATION_ITEMS {
        uuid reconciliation_id FK
        uuid student_id FK
        varchar exception_type
        varchar resolution_outcome
        uuid resolved_by FK
        timestamptz resolved_at
    }
    ABSENCE_DECLARATIONS {
        uuid student_id FK
        uuid declared_by_guardian_id FK
        date absence_date
        varchar direction
        boolean is_cancelled
    }

    TRIPS ||--o{ TRIP_STAFF : "crewed by"
    TRIPS ||--o{ TRIP_MANIFESTS : "expects"
    TRIPS ||--o{ TRIP_MANIFEST_AMENDMENTS : amended_by
    TRIPS ||--o{ BOARDING_EVENTS : records
    BOARDING_EVENTS ||--o| HANDOVERS : "alight completed by"
    BOARDING_EVENTS ||--o| BOARDING_EVENTS : corrects
    TRIPS ||--o| RECONCILIATIONS : "closed by"
    RECONCILIATIONS ||--o{ RECONCILIATION_ITEMS : "exceptions"
```

Structural safety properties visible in this diagram:

- `boarding_events.client_event_id` is unique — idempotent offline sync (BR-BOARD-009, ADR-0008).
- `boarding_events.corrects_event_id` self-references — corrections append, never overwrite (BR-BOARD-001).
- `handovers.boarding_event_id` is `NOT NULL` — no handover without an alight record (BR-HAND-004).
- `handovers` has both a guardian and a pickup-person FK, exactly one of which is set unless `is_override` is true (BR-HAND-001, BR-HAND-003).
- `reconciliation_items` gates `trips.status = CLOSED` (BR-SAFE-001, BR-TRIP-009).

---

## Tracking, Alerts, Notifications

```mermaid
erDiagram
    POSITION_HISTORY {
        uuid vehicle_id FK
        uuid trip_id FK
        numeric latitude
        numeric longitude
        numeric speed_mps
        integer heading_deg
        boolean ignition_on
        timestamptz device_time
        timestamptz received_at
    }
    TRIP_ETAS {
        uuid trip_id FK
        uuid stop_id FK
        timestamptz estimated_arrival
        timestamptz calculated_at
    }
    ALERT_RULES {
        varchar rule_type
        numeric threshold_value
        integer duration_seconds
        boolean is_enabled
    }
    ALERTS {
        uuid trip_id FK
        uuid vehicle_id FK
        varchar alert_type
        varchar severity
        varchar status
        timestamptz opened_at
        timestamptz resolved_at
        uuid resolved_by FK
    }
    NOTIFICATIONS {
        varchar catalog_id
        varchar priority_class
        uuid subject_student_id FK
        uuid trip_id FK
        timestamptz created_at
    }
    NOTIFICATION_DELIVERIES {
        uuid notification_id FK
        uuid recipient_user_id FK
        varchar channel
        varchar status
        varchar provider_reference
        text failure_reason
        integer attempt_no
    }
    NOTIFICATION_PREFERENCES {
        uuid user_id FK
        varchar catalog_id
        varchar channel
        boolean is_enabled
    }
    NOTIFICATION_TEMPLATES {
        varchar catalog_id
        varchar channel
        varchar locale
        text body_template
    }

    TRIPS ||--o{ POSITION_HISTORY : "tracked by"
    TRIPS ||--o{ TRIP_ETAS : estimates
    TRIPS ||--o{ ALERTS : raises
    ALERT_RULES ||--o{ ALERTS : "evaluated into"
    NOTIFICATIONS ||--o{ NOTIFICATION_DELIVERIES : "attempted via"
```

`position_history` is partitioned by `received_at` (daily) — see [`INDEXING_AND_PARTITIONING.md`](INDEXING_AND_PARTITIONING.md).

`notification_deliveries` holds one row **per attempt**, not per notification — that is what makes "why was I not told?" answerable (BR-NTF-005).

---

## Incidents and Audit

```mermaid
erDiagram
    SOS_ALERTS {
        uuid trip_id FK
        uuid raised_by_user_id FK
        numeric latitude
        numeric longitude
        varchar status
        timestamptz raised_at
        timestamptz acknowledged_at
        uuid acknowledged_by FK
        varchar resolution_outcome
    }
    INCIDENTS {
        uuid trip_id FK
        uuid student_id FK
        varchar incident_type
        varchar severity
        varchar status
        text description
        varchar resolution_outcome
    }
    INCIDENT_ESCALATIONS {
        uuid incident_id FK
        uuid sos_alert_id FK
        integer level
        timestamptz notified_at
        timestamptz acknowledged_at
    }
    AUDIT_RECORDS {
        uuid actor_id
        varchar actor_role
        varchar action
        varchar subject_type
        uuid subject_id
        text reason
        varchar source
        uuid correlation_id
        jsonb before_values
        jsonb after_values
        timestamptz occurred_at
    }
    DATA_ACCESS_RECORDS {
        uuid actor_id
        uuid student_id FK
        varchar access_type
        varchar purpose
        uuid correlation_id
        timestamptz occurred_at
    }

    SOS_ALERTS ||--o{ INCIDENT_ESCALATIONS : escalates
    INCIDENTS ||--o{ INCIDENT_ESCALATIONS : escalates
    TRIPS ||--o{ SOS_ALERTS : "raised on"
    TRIPS ||--o{ INCIDENTS : "occurred on"
```

`audit_records` and `data_access_records` deliberately carry **no foreign keys to the entities they describe** — a subject may be soft-deleted or archived while its audit trail must remain readable and intact. They store `subject_type` + `subject_id` instead (BR-AUD-001).
