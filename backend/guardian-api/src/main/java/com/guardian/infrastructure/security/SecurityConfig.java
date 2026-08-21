package com.guardian.infrastructure.security;

import com.guardian.infrastructure.tenant.TenantContextFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * The HTTP security chain.
 *
 * <p>Without this class Spring Security's defaults apply: HTTP Basic against a generated password
 * printed at startup, on every endpoint including the ones a guardian uses to sign in. That is not
 * a hypothetical — {@code spring-boot-starter-security} is on the classpath, so the defaults were
 * in force until this existed.
 *
 * <h2>Filter placement</h2>
 *
 * <p>{@link AccessTokenAuthenticationFilter} and {@link TenantContextFilter} are registered
 * <strong>inside</strong> this chain, not as servlet filters, and their automatic servlet
 * registration is switched off below. The reason is specific and easy to get wrong: Spring
 * Security's {@code SecurityContextHolderFilter} loads the context at the start of its chain and
 * clears it at the end. A filter that authenticates earlier in the servlet chain has its work
 * discarded the moment the security chain starts — the request then arrives at the controller
 * unauthenticated, with nothing in the log to say why.
 *
 * <p>The tenant filter is placed immediately after the token filter, because it reads the tenant
 * off the principal the token filter established. Reversed, it would find an empty context and
 * every tenant-scoped query would return nothing.
 *
 * <h2>What is public</h2>
 *
 * <p>Deny-by-default (BR-IAM-002): {@code anyRequest().authenticated()} is the last rule, so an
 * endpoint added tomorrow is protected without anyone remembering to protect it. The exceptions are
 * enumerated, and each one is an endpoint that cannot require authentication because it is how
 * authentication is obtained or verified.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Bean
  SecurityFilterChain securityFilterChain(
      HttpSecurity http,
      AccessTokenAuthenticationFilter accessTokenFilter,
      TenantContextFilter tenantContextFilter,
      RestAuthenticationEntryPoint entryPoint)
      throws Exception {

    return http
        // Applies the policy in CorsConfig. Without this the bean exists and does nothing:
        // Spring Security's chain runs before Spring MVC's CORS handling, so an un-enabled
        // chain rejects the preflight OPTIONS — which carries no Authorization header and so
        // fails `anyRequest().authenticated()` — and the browser never sends the real request.
        // Enabled here, the CORS filter answers preflight and short-circuits before authorization.
        .cors(Customizer.withDefaults())
        // No browser form posts and no cookie-borne credentials: the API is called with a
        // bearer token, which is not attached automatically and so cannot be forged this way.
        // This holds only while CorsConfig keeps allowCredentials false — see the note there.
        .csrf(csrf -> csrf.disable())
        // No HTTP session is ever created. A session would be a second, invisible credential
        // alongside the token, with its own lifetime and its own revocation problem.
        .sessionManagement(
            session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .httpBasic(basic -> basic.disable())
        .formLogin(form -> form.disable())
        .authorizeHttpRequests(
            auth ->
                auth.requestMatchers("/api/v1/auth/**")
                    .permitAll()
                    .requestMatchers("/.well-known/**")
                    .permitAll()
                    // Liveness and readiness only. The full actuator surface stays authenticated:
                    // /actuator/env alone would disclose the datasource configuration.
                    .requestMatchers(HttpMethod.GET, "/actuator/health", "/actuator/health/**")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .exceptionHandling(handling -> handling.authenticationEntryPoint(entryPoint))
        .addFilterBefore(accessTokenFilter, UsernamePasswordAuthenticationFilter.class)
        .addFilterAfter(tenantContextFilter, AccessTokenAuthenticationFilter.class)
        .build();
  }

  /**
   * Stops Spring Boot also registering the token filter as a plain servlet filter.
   *
   * <p>Any {@code Filter} bean is auto-registered in the servlet chain. Left enabled, the filter
   * would run twice per request — once uselessly before the security chain, where its result is
   * discarded, and once inside it.
   */
  @Bean
  FilterRegistrationBean<AccessTokenAuthenticationFilter> disableAccessTokenFilterRegistration(
      AccessTokenAuthenticationFilter filter) {
    FilterRegistrationBean<AccessTokenAuthenticationFilter> registration =
        new FilterRegistrationBean<>(filter);
    registration.setEnabled(false);
    return registration;
  }

  /** Same reasoning as above, for the tenant filter. */
  @Bean
  FilterRegistrationBean<TenantContextFilter> disableTenantContextFilterRegistration(
      TenantContextFilter filter) {
    FilterRegistrationBean<TenantContextFilter> registration = new FilterRegistrationBean<>(filter);
    registration.setEnabled(false);
    return registration;
  }
}
