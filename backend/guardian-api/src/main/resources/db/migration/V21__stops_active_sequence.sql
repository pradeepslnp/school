-- V21 — Stop sequence numbers are unique among a route's ACTIVE stops only (BR-ROUTE-002)
--
-- See docs/03-database/tables/MOD-07-routes.md and docs/04-api/FLEET_STAFF_ROUTES_API.md
-- § PUT /routes/{id}/stops.
--
-- Editing a route's stops deactivates the ones removed rather than deleting them: trips that
-- already ran reference them (trip_manifests, boarding_events), and that evidence must survive.
-- V5's uq_stops_route_sequence counted those inactive rows too, so the second save of any
-- route's stops failed on a sequence number an old, inactive stop still held. Only active stops
-- make up the route today, so only they need distinct sequence numbers.
--
-- The partial unique index replaces both V5's constraint and idx_stops_route, which indexed the
-- same columns under the same predicate.
-- ---------------------------------------------------------------------------------------
ALTER TABLE stops DROP CONSTRAINT uq_stops_route_sequence;
DROP INDEX idx_stops_route;

CREATE UNIQUE INDEX uq_stops_route_sequence
    ON stops (tenant_id, route_id, sequence_no) WHERE is_active;
