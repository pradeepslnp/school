package com.guardian.trip.infrastructure.schedule;

import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.trip.application.usecase.MaterialiseTripsUseCase;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Generates each tenant's trips ahead of the day they run (BR-TRIP-011).
 *
 * <p>Runs in the worker role. Three design points worth stating, because each one is a place this
 * could have gone wrong quietly:
 *
 * <ul>
 *   <li><strong>It generates several days ahead, not just tomorrow.</strong> A job that only ever
 *       produced the next day would leave a gap every time the worker was down for a night, and the
 *       first symptom would be an entire school with no bus. Because generation is idempotent,
 *       re-covering days that already have trips costs one conflicting insert each and fixes the
 *       gap automatically.
 *   <li><strong>It iterates tenants explicitly.</strong> A background job has no request and
 *       therefore no tenant, and under row-level security a query with no tenant context returns
 *       nothing — the safe default, and the reason this must set context per organization rather
 *       than "just run the query". {@code scheduling_active_tenant_ids()} (V22) is the narrow
 *       {@code SECURITY DEFINER} function that lets it enumerate them.
 *   <li><strong>One tenant's failure does not stop the others.</strong> A malformed
 *       {@code operating_days} in one organization must not cost every other school its buses, so
 *       each tenant is attempted independently and failures are logged and counted.
 * </ul>
 *
 * <p>No distributed lock. Two instances running this simultaneously produce the same rows and the
 * unique constraint discards the duplicates — cheaper and more robust than coordinating them.
 */
@Component
public class TripGenerationJob {

  private static final Logger log = LoggerFactory.getLogger(TripGenerationJob.class);

  private final MaterialiseTripsUseCase materialiseTrips;
  private final JdbcTemplate jdbc;
  private final Clock clock;
  private final int horizonDays;

  public TripGenerationJob(
      MaterialiseTripsUseCase materialiseTrips,
      JdbcTemplate jdbc,
      Clock clock,
      @Value("${guardian.trips.generation-horizon-days:3}") int horizonDays) {
    this.materialiseTrips = materialiseTrips;
    this.jdbc = jdbc;
    this.clock = clock;
    this.horizonDays = horizonDays;
  }

  /**
   * Nightly, in the small hours of the server's zone.
   *
   * <p>The cron is configurable because "the small hours" is not the same instant for a platform
   * serving one country as for one serving several, and a generation run landing in the middle of a
   * school's morning would create trips for a day already under way.
   */
  @Scheduled(cron = "${guardian.trips.generation-cron:0 15 1 * * *}")
  public void generate() {
    LocalDate from = LocalDate.now(clock);
    List<UUID> tenants = activeTenantIds();

    int created = 0;
    int failed = 0;

    for (UUID tenantId : tenants) {
      try {
        created +=
            TenantContext.runAs(
                TenantId.of(tenantId),
                () -> {
                  int subtotal = 0;
                  for (int offset = 0; offset <= horizonDays; offset++) {
                    subtotal += materialiseTrips.execute(from.plusDays(offset), null);
                  }
                  return subtotal;
                });
      } catch (RuntimeException e) {
        failed++;
        // The tenant id, never the exception's message at WARN with data in it — a generation
        // failure is operational, and the detail belongs in the stack trace, not in a log line
        // that may be shipped somewhere less protected.
        log.warn("Trip generation failed for tenant {}", tenantId, e);
      }
    }

    log.info(
        "Trip generation complete: {} trips created across {} tenants ({} failed), horizon {} days",
        created,
        tenants.size() - failed,
        failed,
        horizonDays);
  }

  private List<UUID> activeTenantIds() {
    return jdbc.query(
        "SELECT tenant_id FROM scheduling_active_tenant_ids()",
        (rs, rowNum) -> rs.getObject("tenant_id", UUID.class));
  }
}
