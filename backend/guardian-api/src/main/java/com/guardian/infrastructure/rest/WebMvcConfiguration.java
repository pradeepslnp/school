package com.guardian.infrastructure.rest;

import com.guardian.infrastructure.security.PermissionEnforcementInterceptor;
import java.util.List;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Registers the platform's controller argument resolvers and handler interceptors.
 *
 * <p>Both registrations are load-bearing for authorization, and both fail open if omitted.
 *
 * <p>{@link CurrentActorArgumentResolver}: an unregistered resolver leaves {@code CurrentActor}
 * parameters to Spring's default model-attribute binding, which would populate them from the
 * request. See that class for why that is an impersonation hole rather than a binding quirk.
 *
 * <p>{@link PermissionEnforcementInterceptor}: a {@code HandlerInterceptor} bean is not applied by
 * declaration alone. Without the registration below the interceptor exists, is injected, and is
 * never called — every {@code @RequiresPermission} would go unchecked at runtime while still
 * passing the build-time architecture test, which is exactly the gap it was written to close.
 */
@Configuration
public class WebMvcConfiguration implements WebMvcConfigurer {

  private final CurrentActorArgumentResolver currentActorArgumentResolver;
  private final CallerAccessArgumentResolver callerAccessArgumentResolver;
  private final PermissionEnforcementInterceptor permissionEnforcementInterceptor;

  public WebMvcConfiguration(
      CurrentActorArgumentResolver currentActorArgumentResolver,
      CallerAccessArgumentResolver callerAccessArgumentResolver,
      PermissionEnforcementInterceptor permissionEnforcementInterceptor) {
    this.currentActorArgumentResolver = currentActorArgumentResolver;
    this.callerAccessArgumentResolver = callerAccessArgumentResolver;
    this.permissionEnforcementInterceptor = permissionEnforcementInterceptor;
  }

  @Override
  public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
    // Added ahead of Spring's defaults: custom resolvers are consulted first, so this wins over
    // model-attribute binding for the same parameter type.
    resolvers.add(currentActorArgumentResolver);
    // Same reasoning: CallerAccess must never be bound from request parameters.
    resolvers.add(callerAccessArgumentResolver);
  }

  @Override
  public void addInterceptors(InterceptorRegistry registry) {
    // No path patterns: the interceptor is a no-op for handlers that declare no permission, and
    // enumerating paths here would be a second place for an endpoint to be forgotten.
    registry.addInterceptor(permissionEnforcementInterceptor);
  }
}
