package com.guardian.fleet.infrastructure.config;

import java.time.Clock;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Provides {@link Clock} for expiry checks that depend on "today" (BR-FLEET-002, BR-FLEET-003).
 *
 * <p>Injected rather than called via {@code LocalDate.now()} directly so a test can fix the instant
 * an expiry decision is made against — an expiry boundary test that depends on the day it happens
 * to run is not a test, it is a coin flip.
 *
 * <p>{@code @ConditionalOnMissingBean} so a later module, or a test's {@code @TestConfiguration},
 * can supply its own {@link Clock} without a bean collision — this becomes the platform default the
 * moment a second module needs one.
 */
@Configuration
class FleetClockConfig {

  @Bean
  @ConditionalOnMissingBean(Clock.class)
  Clock clock() {
    return Clock.systemUTC();
  }
}
