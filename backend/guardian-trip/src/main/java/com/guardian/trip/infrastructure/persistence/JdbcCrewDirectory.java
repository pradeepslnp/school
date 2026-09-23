package com.guardian.trip.infrastructure.persistence;

import com.guardian.trip.application.port.CrewDirectory;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Resolves a signed-in user to their transport-staff record (MOD-06's table, MOD-08's question).
 *
 * <p>A single-column lookup, deliberately kept here rather than obtained through a MOD-06 use case:
 * there is no rule in it, and a use case whose only job is to return a foreign key would be
 * indirection without meaning.
 *
 * <p>Inactive staff are excluded. A driver whose record has been deactivated should not be
 * recognised as rostered crew on their next request, and returning their id would let the roster
 * check pass for someone the platform has already stood down.
 */
@Component
public class JdbcCrewDirectory implements CrewDirectory {

  private final JdbcTemplate jdbc;

  public JdbcCrewDirectory(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public Optional<UUID> staffIdForUser(UUID userId) {
    return jdbc
        .query(
            """
            SELECT id FROM transport_staff
            WHERE user_id = ? AND is_active
            """,
            (rs, rowNum) -> rs.getObject("id", UUID.class),
            userId)
        .stream()
        .findFirst();
  }
}
