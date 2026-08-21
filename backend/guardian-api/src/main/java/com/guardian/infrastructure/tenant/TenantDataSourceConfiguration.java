package com.guardian.infrastructure.tenant;

import javax.sql.DataSource;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Puts {@link TenantAwareDataSource} in front of the real one.
 *
 * <p>Without this the class is inert and nothing ever issues {@code SET LOCAL app.tenant_id}. That
 * failure mode is worth naming, because it is silent in the direction that matters: with the GUC
 * never set, every RLS predicate compares against NULL and every tenant-scoped query returns
 * nothing. Isolation still holds — the system fails closed — but the application appears to have no
 * data, and the cause is a wrapper that was written and never wired.
 *
 * <p>A {@link BeanPostProcessor} rather than a {@code @Bean} that replaces the DataSource, because
 * Spring Boot builds the DataSource from {@code spring.datasource.*} and the connection pool.
 * Rebuilding it here would mean re-implementing that configuration and diverging from it the first
 * time a property is added. Wrapping leaves Boot in charge of construction.
 *
 * <p>Ordered before the JPA entity manager is created — a {@code BeanPostProcessor} sees the
 * DataSource as it is initialised, so everything that injects one receives the wrapper.
 */
@Configuration
public class TenantDataSourceConfiguration {

  @Bean
  static BeanPostProcessor tenantAwareDataSourcePostProcessor() {
    return new BeanPostProcessor() {
      @Override
      public Object postProcessAfterInitialization(Object bean, String beanName)
          throws BeansException {
        // Guards against double-wrapping if this ever runs twice: a nested wrapper would issue
        // SET LOCAL twice per connection, which is harmless but hides the mistake.
        if (bean instanceof DataSource dataSource && !(bean instanceof TenantAwareDataSource)) {
          return new TenantAwareDataSource(dataSource);
        }
        return bean;
      }
    };
  }
}
