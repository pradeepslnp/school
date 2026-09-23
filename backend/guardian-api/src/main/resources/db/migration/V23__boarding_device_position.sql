-- V23 — Device position on boarding events (MOD-09, BR-BOARD-002)
--
-- BR-BOARD-002 lists what every boarding event records: "student, trip, type, actor,
-- verification method, DEVICE POSITION, occurred_at, and recorded_at." TRIPS_BOARDING_API.md's
-- request body sends `latitude` and `longitude` accordingly. V5 created the table without them.
--
-- The position is not a nicety. It is what lets an investigation answer "was the bus actually at
-- Green Park when the attendant recorded this child boarding there?" — the single most useful
-- check against a well-meaning attendant tapping through a manifest from memory at the depot,
-- and the only evidence available at all before MOD-10 exists to stream positions.
--
-- Nullable, deliberately. A handset can have location off, be indoors, or be in a basement car
-- park, and refusing to record a child boarding because GPS is unavailable would trade a
-- complete safety record for a precise one. A boarding event with no position is worth far more
-- than no boarding event.

ALTER TABLE boarding_events
    ADD COLUMN device_latitude  NUMERIC(9,6),
    ADD COLUMN device_longitude NUMERIC(9,6);

ALTER TABLE boarding_events
    ADD CONSTRAINT ck_boarding_latitude
        CHECK (device_latitude IS NULL OR device_latitude BETWEEN -90 AND 90),
    ADD CONSTRAINT ck_boarding_longitude
        CHECK (device_longitude IS NULL OR device_longitude BETWEEN -180 AND 180),
    -- Half a coordinate is not a position. Recording one without the other would produce a row
    -- that looks located and is not, which is worse than an honestly empty one.
    ADD CONSTRAINT ck_boarding_position_complete
        CHECK ((device_latitude IS NULL) = (device_longitude IS NULL));

COMMENT ON COLUMN boarding_events.device_latitude IS
    'Where the recording device was when the event was captured (BR-BOARD-002). Null when the '
    'handset had no fix — a boarding event without a position still counts.';

-- Reads that matter: "what happened to this child on this trip", in the order it happened.
-- The parent read model, the manifest projection and reconciliation all ask exactly this.
CREATE INDEX idx_boarding_events_trip_student
    ON boarding_events (tenant_id, trip_id, student_id, occurred_at);
