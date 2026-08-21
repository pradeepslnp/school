-- V900 — Demo data. NOT part of the production migration path.
--
-- Lives in `db/seed`, which is added to spring.flyway.locations only by the `demo` profile
-- (application-demo.yml). A production deployment never sees this file, so the separation is
-- structural rather than a naming convention someone has to remember.
--
-- ## Why the version is 900
--
-- Flyway orders by version across all locations. Sitting far above the real migrations means
-- the seed always runs last, and a new V7 later still applies cleanly rather than being
-- rejected as out-of-order.
--
-- ## Why every id is fixed
--
-- Two reasons. The seed is idempotent-ish under `ON CONFLICT DO NOTHING`, and — more
-- usefully — the parent app's own fixture ids are reused verbatim here, so the ids a
-- developer has already seen in guardian-parent-app now resolve to real rows.
--
-- ## SET LOCAL is load-bearing
--
-- Every table below is FORCE ROW LEVEL SECURITY, and FORCE applies to the table owner too —
-- which is who Flyway connects as. Without tenant context each INSERT below would be
-- rejected by its own WITH CHECK clause. This is the same mechanism the application uses per
-- request, exercised here at migration time.

SET LOCAL app.tenant_id = 'a0000000-0000-4000-a000-000000000001';

-- ---------------------------------------------------------------------------------------
-- Tenant, school
-- ---------------------------------------------------------------------------------------
INSERT INTO organizations (id, code, name, region_profile_code, status, contact_email)
VALUES ('a0000000-0000-4000-a000-000000000001', 'DEMO', 'Demo Education Trust', 'IN', 'ACTIVE',
        'office@demo-trust.example')
ON CONFLICT (id) DO NOTHING;

INSERT INTO schools (id, tenant_id, organization_id, code, name, timezone,
                     latitude, longitude, geofence_radius_m, status)
VALUES ('b0000000-0000-4000-a000-000000000001',
        'a0000000-0000-4000-a000-000000000001',
        'a0000000-0000-4000-a000-000000000001',
        'DPS-GP', 'Demo Public School, Green Park', 'Asia/Kolkata',
        28.558500, 77.206600, 150, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO student_classes (id, tenant_id, school_id, grade, section, academic_year)
VALUES ('b1000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'Class 5', 'B', '2026-27'),
       ('b1000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'Class 3', 'A', '2026-27')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- The signing-in guardian
--
-- The phone is stored in the canonical form PhoneNumber.of() produces: digits only, leading
-- zeros stripped. `8050602046` signs in against this row, paired with GUARDIAN_MAGIC_OTP=123123
-- from this profile — the parent app holds no test credentials of its own, so this is the only
-- thing that makes a sign-in work without a live handset.
--
-- No user_credentials row is seeded: RequestOtpUseCase creates the OTP on demand.
-- ---------------------------------------------------------------------------------------
INSERT INTO users (id, tenant_id, phone, first_name, last_name, preferred_locale, status)
VALUES ('c0000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        '8050602046', 'Meera', 'Sharma', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO guardians (id, tenant_id, user_id, first_name, last_name, phone, email, is_active)
VALUES ('c1000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c0000000-0000-4000-a000-000000000001', 'Meera', 'Sharma', '8050602046',
        'meera.sharma@example.com', true)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- The GUARDIAN role, and the grant of it
--
-- Not optional decoration. AccessTokenAuthenticationFilter resolves roles from the database on
-- every request and leaves the security context empty when a user holds none — deny by default
-- (BR-IAM-002). Without these two rows the sign-in above succeeds and issues a real token, and
-- then every authenticated call answers 401 as though that token were missing. In the parent
-- app that reads as being bounced back to the login screen the instant the dashboard loads,
-- which points suspicion at authentication rather than at authorisation, where it belongs.
--
-- `is_system_role` marks it as defined by the platform rather than by the tenant, matching
-- GuardianOtpSignInIT, which is the reference for what a working guardian's rows look like.
-- ---------------------------------------------------------------------------------------
INSERT INTO roles (id, tenant_id, code, name, is_system_role)
VALUES ('c5000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'GUARDIAN', 'Guardian', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('c6000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c0000000-0000-4000-a000-000000000001', 'c5000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- The signing-in transport manager — admin console demo access (IAM-001)
--
-- Anil, the persona ADMIN_WEB.md and PERSONAS.md write the console for. Signs in at
-- POST /auth/login with clientType ADMIN_WEB against:
--
--   email     anil@demo-trust.example
--   password  Guardian!Demo2026
--
-- The hash below is real Argon2id, computed with the exact parameters
-- Argon2SecretHasher uses (Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8: m=16384,
-- t=2, p=1, 32-byte hash, 16-byte salt) — StaffLoginUseCase exercises the genuine
-- verification path, not a bypass, unlike GUARDIAN_MAGIC_OTP for the guardian above. There
-- is no equivalent shortcut for a password: a fixed plaintext only works if something
-- computed its hash once, so it is computed here instead of at request time.
--
-- Regenerate if this account's password ever needs to change:
--   pip install argon2-cffi --break-system-packages
--   python3 -c "
--   import argon2
--   ph = argon2.PasswordHasher(time_cost=2, memory_cost=16384, parallelism=1,
--                               hash_len=32, salt_len=16, type=argon2.Type.ID)
--   print(ph.hash('your-new-password'))"
-- ---------------------------------------------------------------------------------------
INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('c7000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'anil@demo-trust.example', 'Anil', 'Kumar', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('c8000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c7000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$4aMNgZoPu6hZOS6VdcyBvA$'
        'nQ9McAt/QL3LMqaa28iCdK9IChEC+lJkQJyXKdNxjp4')
ON CONFLICT (id) DO NOTHING;

-- Matches AUTHENTICATION_API.md's own example login response verbatim.
INSERT INTO roles (id, tenant_id, code, name, is_system_role)
VALUES ('c9000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'TRANSPORT_MANAGER', 'Transport Manager', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('ca000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c7000000-0000-4000-a000-000000000001', 'c9000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- The signing-in driver — driver app demo access (IAM-002)
--
-- Signs in exactly as the guardian above does: POST /auth/otp/request with the phone, then
-- /auth/otp/verify with GUARDIAN_MAGIC_OTP=123123 and clientType DRIVER_APP. Both apps use
-- the phone-OTP flow, so the resolver they hit is the same auth_resolve_phone over `users` —
-- a transport_staff row alone is invisible to sign-in, which is why the `users` row below
-- comes first and the staff row points at it rather than the other way round.
--
--   phone  9990000001
--
-- Deliberately not 8050602046. BR-IAM-003 refuses a sign-in when a number resolves to more
-- than one user, so reusing the guardian's number here would break both accounts rather than
-- give the driver one.
--
-- To test on a real handset, change the phone on BOTH rows below — users.phone is what
-- sign-in resolves, transport_staff.phone is what the roster displays, and nothing in the
-- schema keeps them in step.
-- ---------------------------------------------------------------------------------------
INSERT INTO users (id, tenant_id, phone, first_name, last_name, preferred_locale, status)
VALUES ('cb000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        '9990000001', 'Ravi', 'Kumar', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- Same reason the GUARDIAN grant above is not optional: without a role,
-- AccessTokenAuthenticationFilter leaves the security context empty and every authenticated
-- call answers 401 behind a sign-in that looked like it worked. `DRIVER` is the role code
-- PERMISSION_MATRIX.md gives this persona.
INSERT INTO roles (id, tenant_id, code, name, is_system_role)
VALUES ('cc000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'DRIVER', 'Driver', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('cd000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'cb000000-0000-4000-a000-000000000001', 'cc000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- The staff record the console reads (STF-001), with user_id already populated — V9 leaves
-- that column null "until the person's account is activated", and the activation path
-- (MOD-02) is not built, so the seed does here what nothing in the application yet can.
--
-- VERIFIED rather than PENDING so BR-STAFF-001/002 eligibility passes: an unverified driver
-- is blocked from duty, which makes for a demo account that signs in and then cannot work.
-- verified_until is required alongside it (ck_staff_verified_until) and is set a year out
-- from whenever the seed runs, so this does not quietly lapse.
INSERT INTO transport_staff (id, tenant_id, school_id, user_id, staff_type, employee_code,
                             first_name, last_name, phone, verification_status,
                             verified_until, is_active)
VALUES ('ce000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'cb000000-0000-4000-a000-000000000001',
        'DRIVER', 'DRV-001', 'Ravi', 'Kumar', '9990000001', 'VERIFIED',
        CURRENT_DATE + INTERVAL '1 year', true)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- The signing-in platform operator — SUPER_ADMIN, organization onboarding (TEN-001)
--
-- A SUPER_ADMIN's own account still lives under some organization — `users.tenant_id` is
-- NOT NULL, and there is no separate "no tenant" concept in this schema (MULTI_TENANCY.md:
-- "Organization ← the tenant; tenant_id refers to this"). Seeded under a dedicated platform
-- organization rather than the demo trust, so the console can demonstrate the one thing that
-- actually distinguishes this role: creating an organization the operator does not already
-- belong to (CreateOrganizationUseCase mints a new tenant; see its class documentation).
--
-- Signs in at POST /auth/login with clientType ADMIN_WEB against:
--
--   email     priya@guardian-platform.example
--   password  Guardian!Platform2026
--
-- Hash computed the same way as Anil's above — see that comment for the regeneration
-- command; only the plaintext differs.
--
-- The tenant context set at the top of this file is the DEMO organization's own id, which
-- is exactly wrong for writing a *different* organization's rows — `organizations`' WITH
-- CHECK compares id to app.tenant_id (V1), and every other table below it compares
-- tenant_id the same way. Switched here to the platform organization's own generated id
-- before writing it and everything under it, the same bootstrap CreateOrganizationUseCase
-- performs at request time via TenantScopedTransaction — then switched back afterward so
-- the rest of this file, which is all DEMO-tenant data, is unaffected.
-- ---------------------------------------------------------------------------------------
SET LOCAL app.tenant_id = 'aa000000-0000-4000-a000-000000000001';

INSERT INTO organizations (id, code, name, region_profile_code, status, contact_email)
VALUES ('aa000000-0000-4000-a000-000000000001', 'PLATFORM', 'Guardian Platform Operations',
        'GLOBAL', 'ACTIVE', 'platform-ops@guardian.example')
ON CONFLICT (id) DO NOTHING;

INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
VALUES ('ab000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'priya@guardian-platform.example', 'Priya', 'Menon', 'en', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_credentials (id, tenant_id, user_id, credential_type, secret_hash)
VALUES ('ac000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'ab000000-0000-4000-a000-000000000001', 'PASSWORD',
        '$argon2id$v=19$m=16384,t=2,p=1$kNq2YT3DgBPJqSfQ13pgsQ$'
        'PXDF5Z953ProTUkuu/Ga0upy75U4OUov4ZV03KDydF0')
ON CONFLICT (id) DO NOTHING;

INSERT INTO roles (id, tenant_id, code, name, is_system_role)
VALUES ('ad000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'SUPER_ADMIN', 'Super Admin', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_roles (id, tenant_id, user_id, role_id)
VALUES ('ae000000-0000-4000-a000-000000000001', 'aa000000-0000-4000-a000-000000000001',
        'ab000000-0000-4000-a000-000000000001', 'ad000000-0000-4000-a000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- Back to the DEMO tenant for the remainder of this file.
SET LOCAL app.tenant_id = 'a0000000-0000-4000-a000-000000000001';

-- ---------------------------------------------------------------------------------------
-- Children — the two the parent app has always shown
-- ---------------------------------------------------------------------------------------
INSERT INTO students (id, tenant_id, school_id, student_class_id, admission_no,
                      first_name, last_name, date_of_birth, enrolment_status, transport_eligible)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'b1000000-0000-4000-a000-000000000001',
        'ADM-2026-0411', 'Aarav', 'Sharma', DATE '2015-04-18', 'ACTIVE', true),
       ('660e8400-e29b-41d4-a716-446655440001', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'b1000000-0000-4000-a000-000000000002',
        'ADM-2026-0412', 'Ananya', 'Sharma', DATE '2017-09-02', 'ACTIVE', true)
ON CONFLICT (id) DO NOTHING;

-- Rights are explicit (BR-GRD-001). This guardian holds all four, which is what makes the
-- absence and pickup-person screens reachable in the demo; a second guardian without
-- can_authorise_handover is seeded below so the refusal path (BR-GRD-006) is demonstrable.
INSERT INTO guardian_student_links (id, tenant_id, guardian_id, student_id, relationship_type,
                                    can_view, can_receive_notifications,
                                    can_authorise_handover, can_declare_absence,
                                    is_primary, is_active)
VALUES ('c2000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c1000000-0000-4000-a000-000000000001', '550e8400-e29b-41d4-a716-446655440000',
        'MOTHER', true, true, true, true, true, true),
       ('c2000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        'c1000000-0000-4000-a000-000000000001', '660e8400-e29b-41d4-a716-446655440001',
        'MOTHER', true, true, true, true, true, true)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- Fleet and route
-- ---------------------------------------------------------------------------------------
-- capacity was renamed to seating_capacity, and vehicle_type added NOT NULL, by
-- V8__fleet.sql (MOD-05) — this INSERT is updated to match rather than left to fail against
-- the new schema.
INSERT INTO vehicles (id, tenant_id, school_id, registration_no, display_name, vehicle_type, seating_capacity, status)
VALUES ('d0000000-0000-4000-a000-000000000012', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'DL1PC1234', 'Bus 12', 'BUS', 42, 'ACTIVE'),
       ('d0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'DL1PC5678', 'Bus 4', 'BUS', 36, 'ACTIVE')
ON CONFLICT (id) DO NOTHING;

INSERT INTO routes (id, tenant_id, school_id, code, name, default_vehicle_id, is_active)
VALUES ('e0000000-0000-4000-a000-000000000012', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'R-12', 'Green Park corridor',
        'd0000000-0000-4000-a000-000000000012', true),
       ('e0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'R-04', 'Lake View corridor',
        'd0000000-0000-4000-a000-000000000004', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO stops (id, tenant_id, route_id, sequence_no, name, latitude, longitude,
                   geofence_radius_m, scheduled_pickup_time, scheduled_drop_time, landmark)
VALUES ('e1000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000012', 1, 'Green Park', 28.560100, 77.206500,
        60, TIME '07:40', TIME '15:20', 'Opposite the metro gate 2'),
       ('e1000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000012', 2, 'Hauz Khas', 28.549500, 77.203200,
        60, TIME '07:52', TIME '15:08', 'Near the bus depot'),
       ('e1000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000004', 1, 'Lake View', 28.571200, 77.219800,
        60, TIME '07:35', TIME '15:25', 'By the community park')
ON CONFLICT (id) DO NOTHING;

INSERT INTO route_student_assignments (id, tenant_id, route_id, stop_id, student_id, direction, is_active)
VALUES ('e2000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000012', 'e1000000-0000-4000-a000-000000000001',
        '550e8400-e29b-41d4-a716-446655440000', 'PICKUP', true),
       ('e2000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000012', 'e1000000-0000-4000-a000-000000000001',
        '550e8400-e29b-41d4-a716-446655440000', 'DROP', true),
       ('e2000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000004', 'e1000000-0000-4000-a000-000000000003',
        '660e8400-e29b-41d4-a716-446655440001', 'PICKUP', true),
       ('e2000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001',
        'e0000000-0000-4000-a000-000000000004', 'e1000000-0000-4000-a000-000000000003',
        '660e8400-e29b-41d4-a716-446655440001', 'DROP', true)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- Today's trips
--
-- Relative to now() so the demo is alive whenever it is run rather than dated to whenever
-- the seed was written:
--
--   Bus 12 PICKUP    IN_PROGRESS, started 20 min ago, Aarav boarded 18 min ago  → "On the bus"
--   Bus 12 DROP      SCHEDULED this afternoon
--   Bus 4  PICKUP    COMPLETED, Ananya boarded and alighted at school           → "At school"
--   Bus 4  DROP      SCHEDULED this afternoon                                   → next bus 15:25
-- ---------------------------------------------------------------------------------------
INSERT INTO trips (id, tenant_id, school_id, route_id, vehicle_id, service_date, direction,
                   status, scheduled_start_time, started_at)
VALUES ('770e8400-e29b-41d4-a716-446655440010', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'e0000000-0000-4000-a000-000000000012',
        'd0000000-0000-4000-a000-000000000012', CURRENT_DATE, 'PICKUP',
        'IN_PROGRESS', TIME '07:15', now() - INTERVAL '20 minutes'),

       ('770e8400-e29b-41d4-a716-446655440011', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'e0000000-0000-4000-a000-000000000012',
        NULL, CURRENT_DATE, 'DROP', 'SCHEDULED', TIME '15:10', NULL),

       ('770e8400-e29b-41d4-a716-446655440020', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'e0000000-0000-4000-a000-000000000004',
        'd0000000-0000-4000-a000-000000000004', CURRENT_DATE, 'PICKUP',
        'COMPLETED', TIME '07:05', now() - INTERVAL '2 hours'),

       ('770e8400-e29b-41d4-a716-446655440021', 'a0000000-0000-4000-a000-000000000001',
        'b0000000-0000-4000-a000-000000000001', 'e0000000-0000-4000-a000-000000000004',
        NULL, CURRENT_DATE, 'DROP', 'SCHEDULED', TIME '15:25', NULL)
ON CONFLICT (id) DO NOTHING;

UPDATE trips SET ended_at = now() - INTERVAL '95 minutes'
WHERE id = '770e8400-e29b-41d4-a716-446655440020' AND ended_at IS NULL;

INSERT INTO trip_manifests (id, tenant_id, trip_id, student_id, expected_stop_id,
                            student_name_snapshot, sequence_no, status)
VALUES ('f0000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000',
        'e1000000-0000-4000-a000-000000000001', 'Aarav Sharma', 1, 'BOARDED'),
       ('f0000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000',
        'e1000000-0000-4000-a000-000000000001', 'Aarav Sharma', 1, 'EXPECTED'),
       ('f0000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440020', '660e8400-e29b-41d4-a716-446655440001',
        'e1000000-0000-4000-a000-000000000003', 'Ananya Sharma', 1, 'ALIGHTED'),
       ('f0000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440021', '660e8400-e29b-41d4-a716-446655440001',
        'e1000000-0000-4000-a000-000000000003', 'Ananya Sharma', 1, 'EXPECTED')
ON CONFLICT (id) DO NOTHING;

-- Boarding events. actor_id is the seeded guardian's user id purely so the column is
-- populated; in operation it is the driver or attendant who recorded the scan.
INSERT INTO boarding_events (id, tenant_id, trip_id, student_id, stop_id, event_type,
                             verification_method, actor_id, actor_role, client_event_id,
                             occurred_at, recorded_at, sync_state)
VALUES ('f1000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000',
        'e1000000-0000-4000-a000-000000000001', 'BOARD', 'QR_SCAN',
        'c0000000-0000-4000-a000-000000000001', 'ATTENDANT',
        'f1000000-0000-4000-a000-0000000000a1',
        now() - INTERVAL '18 minutes', now() - INTERVAL '18 minutes', 'SYNCED'),

       ('f1000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440020', '660e8400-e29b-41d4-a716-446655440001',
        'e1000000-0000-4000-a000-000000000003', 'BOARD', 'QR_SCAN',
        'c0000000-0000-4000-a000-000000000001', 'ATTENDANT',
        'f1000000-0000-4000-a000-0000000000a2',
        now() - INTERVAL '115 minutes', now() - INTERVAL '115 minutes', 'SYNCED'),

       ('f1000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001',
        '770e8400-e29b-41d4-a716-446655440020', '660e8400-e29b-41d4-a716-446655440001',
        NULL, 'ALIGHT', 'VISUAL',
        'c0000000-0000-4000-a000-000000000001', 'ATTENDANT',
        'f1000000-0000-4000-a000-0000000000a3',
        now() - INTERVAL '95 minutes', now() - INTERVAL '95 minutes', 'SYNCED')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- An authorised pickup person — the example PARENT_APP.md itself uses for P-07
-- ---------------------------------------------------------------------------------------
INSERT INTO authorised_pickup_persons (id, tenant_id, student_id, nominated_by_guardian_id,
                                       full_name, phone, relationship_note,
                                       valid_from, valid_until, is_active)
VALUES ('c3000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        '550e8400-e29b-41d4-a716-446655440000', 'c1000000-0000-4000-a000-000000000001',
        'Sunil Kumar', '919812345678', 'Uncle',
        now() - INTERVAL '2 days', now() + INTERVAL '5 days', true)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- Notification history (P-08)
--
-- body_fallback carries the catalog's own copy (NOTIFICATION_CATALOG.md); body_key is what
-- the client renders from once localisation lands (BR-CFG-005).
-- ---------------------------------------------------------------------------------------
INSERT INTO notifications (id, tenant_id, user_id, catalog_id, priority, body_key, body_params,
                           body_fallback, student_id, trip_id, occurred_at, read_at)
VALUES ('c4000000-0000-4000-a000-000000000001', 'a0000000-0000-4000-a000-000000000001',
        'c0000000-0000-4000-a000-000000000001', 'NTF-BOARD-01', 'STANDARD',
        'notification.board.boarded',
        '{"student":"Aarav","vehicle":"Bus 12","stop":"Green Park"}'::jsonb,
        'Aarav boarded Bus 12 at Green Park.',
        '550e8400-e29b-41d4-a716-446655440000', '770e8400-e29b-41d4-a716-446655440010',
        now() - INTERVAL '18 minutes', NULL),

       ('c4000000-0000-4000-a000-000000000002', 'a0000000-0000-4000-a000-000000000001',
        'c0000000-0000-4000-a000-000000000001', 'NTF-TRIP-01', 'INFO',
        'notification.trip.started', '{"vehicle":"Bus 12"}'::jsonb,
        'Bus 12 has started its morning route.',
        '550e8400-e29b-41d4-a716-446655440000', '770e8400-e29b-41d4-a716-446655440010',
        now() - INTERVAL '20 minutes', now() - INTERVAL '19 minutes'),

       ('c4000000-0000-4000-a000-000000000003', 'a0000000-0000-4000-a000-000000000001',
        'c0000000-0000-4000-a000-000000000001', 'NTF-BOARD-02', 'STANDARD',
        'notification.board.arrived_at_school', '{"student":"Ananya"}'::jsonb,
        'Ananya arrived at school.',
        '660e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440020',
        now() - INTERVAL '95 minutes', now() - INTERVAL '90 minutes'),

       ('c4000000-0000-4000-a000-000000000004', 'a0000000-0000-4000-a000-000000000001',
        'c0000000-0000-4000-a000-000000000001', 'NTF-TRIP-03', 'URGENT',
        'notification.trip.delayed', '{"vehicle":"Bus 4","minutes":"15"}'::jsonb,
        'Bus 4 is running about 15 minutes late this morning.',
        '660e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440020',
        now() - INTERVAL '2 hours', NULL)
ON CONFLICT (id) DO NOTHING;
