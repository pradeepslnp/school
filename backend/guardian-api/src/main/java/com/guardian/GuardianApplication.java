package com.guardian;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Application bootstrap.
 *
 * <p>The same modules are deployed in three roles — API, ingestion, and worker — selected by
 * profile. They are separated because their load profiles differ sharply, not because their code
 * does (guardian-docs/02-system-design/ARCHITECTURE_OVERVIEW.md).
 *
 * <p>{@code @EnableScheduling} is on for MOD-08's nightly trip generation (BR-TRIP-011). Because
 * generation is idempotent at the database — {@code uq_trips_route_date_direction} plus {@code ON
 * CONFLICT DO NOTHING} — every instance running it produces the same rows, so this needs no leader
 * election and no distributed lock. Any scheduled work added later that is <em>not</em> idempotent
 * must bring its own coordination; it does not inherit safety from this one.
 */
@SpringBootApplication
@EnableScheduling
@EnableTransactionManagement
public class GuardianApplication {

  public static void main(String[] args) {
    SpringApplication.run(GuardianApplication.class, args);
  }
}
