package com.guardian.staff.infrastructure.config;

import java.time.Clock;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Provides {@link Clock} for expiry checks that depend on "today" (BR-STAFF-001, BR-STAFF-002,
 * BR-STAFF-003).
 *
 * <p>Injected rather than called via {@code LocalDate.now()} directly so a test can fix the instant
 * an expiry or verification decision is made against.
 *
 * <p>{@code @ConditionalOnMissingBean} so this backs off if another module (guardian-fleet already
 * defines one) has already supplied {@link Clock} — exactly one {@code Clock} bean exists
 * platform-wide regardless of how many modules ship a config class for it.
 */
@Configuration
class StaffClockConfig {

  @Bean
  @ConditionalOnMissingBean(Clock.class)
  Clock clock() {
    return Clock.systemUTC();
  }
}
