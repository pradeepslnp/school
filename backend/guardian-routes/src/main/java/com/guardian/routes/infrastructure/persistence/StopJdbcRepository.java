package com.guardian.routes.infrastructure.persistence;

import com.guardian.routes.application.port.StopRepository;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.Stop;
import com.guardian.routes.domain.StopId;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Implements {@link StopRepository} with plain JDBC against {@code stops} directly, rather than JPA
 * — a stop has no lifecycle of its own outside its route (it is always replaced as a full list,
 * never edited in place), so a JPA entity and mapper would be machinery this class is the only
 * caller of.
 *
 * <p>{@code tenant_id} is taken from the session's own RLS context ({@code
 * current_setting('app.tenant_id')}), matching {@code JdbcPickupPersonRepository} and every other
 * plain-JDBC writer in this codebase, rather than passed as a bound parameter.
 */
@Component
class StopJdbcRepository implements StopRepository {

  private final JdbcTemplate jdbcTemplate;

  StopJdbcRepository(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  public List<Stop> findByRoute(RouteId routeId) {
    return jdbcTemplate.query(
        """
        SELECT id, sequence_no, name, latitude, longitude, geofence_radius_m,
               scheduled_pickup_time, scheduled_drop_time, landmark
        FROM stops
        WHERE route_id = ? AND is_active
        ORDER BY sequence_no
        """,
        StopJdbcRepository::toStop,
        routeId.value());
  }

  /**
   * Deletes every existing stop for this route and inserts the replacement set, in one transaction
   * — matching {@code PUT /routes/{id}/stops}'s "replaces the full ordered list" contract
   * (FLEET_STAFF_ROUTES_API.md). A soft delete (is_active = false) rather than a hard DELETE: stops
   * are referenced by {@code trip_manifests.expected_stop_id} for trips that have already run, and
   * an edit to today's route must not orphan yesterday's evidence.
   */
  @Override
  public void replaceAll(RouteId routeId, List<Stop> stops) {
    jdbcTemplate.update(
        "UPDATE stops SET is_active = false WHERE route_id = ? AND is_active", routeId.value());

    for (Stop stop : stops) {
      jdbcTemplate.update(
          """
          INSERT INTO stops
              (id, tenant_id, route_id, sequence_no, name, latitude, longitude,
               geofence_radius_m, scheduled_pickup_time, scheduled_drop_time, landmark)
          VALUES (?, NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                  ?, ?, ?, ?, ?, ?, ?, ?, ?)
          """,
          stop.id().value(),
          routeId.value(),
          stop.sequenceNo(),
          stop.name(),
          stop.latitude(),
          stop.longitude(),
          stop.geofenceRadiusM(),
          stop.scheduledPickupTime().map(Time::valueOf).orElse(null),
          stop.scheduledDropTime().map(Time::valueOf).orElse(null),
          stop.landmark().orElse(null));
    }
  }

  private static Stop toStop(ResultSet rs, int rowNum) throws SQLException {
    Time pickup = rs.getTime("scheduled_pickup_time");
    Time drop = rs.getTime("scheduled_drop_time");
    return new Stop(
        StopId.of(rs.getObject("id", UUID.class)),
        rs.getInt("sequence_no"),
        rs.getString("name"),
        rs.getDouble("latitude"),
        rs.getDouble("longitude"),
        rs.getInt("geofence_radius_m"),
        pickup == null ? null : pickup.toLocalTime(),
        drop == null ? null : drop.toLocalTime(),
        rs.getString("landmark"));
  }
}
