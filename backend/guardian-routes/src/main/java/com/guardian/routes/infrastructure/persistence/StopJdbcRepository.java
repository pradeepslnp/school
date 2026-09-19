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
 * — a stop has no lifecycle of its own outside its route (it is always written as a full list), so
 * a JPA entity and mapper would be machinery this class is the only caller of.
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
   * Makes {@code stops} the route's active stop list, in one transaction.
   *
   * <ol>
   *   <li>Active stops not in the list are deactivated — never deleted: trips that already ran
   *       reference them, and yesterday's evidence must survive an edit to today's route.
   *   <li>The remaining active stops are moved out of the way ({@code sequence_no + 1000000}), so
   *       re-numbering them can never collide with {@code uq_stops_route_sequence} mid-update.
   *   <li>Each stop is written by id: an existing one updated in place — keeping every student
   *       assignment that points at it — and a new one inserted.
   * </ol>
   *
   * <p>The use case has already checked that every existing id belongs to this route; the {@code
   * WHERE} on the update repeats it so a stop can never be moved between routes here.
   */
  @Override
  public void replaceAll(RouteId routeId, List<Stop> stops) {
    UUID[] keptIds = stops.stream().map(stop -> stop.id().value()).toArray(UUID[]::new);

    jdbcTemplate.update(
        connection -> {
          var statement =
              connection.prepareStatement(
                  """
                  UPDATE stops SET is_active = false, updated_at = now(), version = version + 1
                  WHERE route_id = ? AND is_active AND id <> ALL (?)
                  """);
          statement.setObject(1, routeId.value());
          statement.setArray(2, connection.createArrayOf("uuid", keptIds));
          return statement;
        });

    jdbcTemplate.update(
        "UPDATE stops SET sequence_no = sequence_no + 1000000 WHERE route_id = ? AND is_active",
        routeId.value());

    for (Stop stop : stops) {
      jdbcTemplate.update(
          """
          INSERT INTO stops
              (id, tenant_id, route_id, sequence_no, name, latitude, longitude,
               geofence_radius_m, scheduled_pickup_time, scheduled_drop_time, landmark)
          VALUES (?, NULLIF(current_setting('app.tenant_id', true), '')::uuid,
                  ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT (id) DO UPDATE SET
              sequence_no = EXCLUDED.sequence_no,
              name = EXCLUDED.name,
              latitude = EXCLUDED.latitude,
              longitude = EXCLUDED.longitude,
              geofence_radius_m = EXCLUDED.geofence_radius_m,
              scheduled_pickup_time = EXCLUDED.scheduled_pickup_time,
              scheduled_drop_time = EXCLUDED.scheduled_drop_time,
              landmark = EXCLUDED.landmark,
              updated_at = now(),
              version = stops.version + 1
          WHERE stops.route_id = EXCLUDED.route_id AND stops.is_active
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
