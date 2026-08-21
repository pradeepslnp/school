package com.guardian.infrastructure.rest;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.security.CurrentActor;
import com.guardian.infrastructure.tenant.GuardianPrincipal;
import org.springframework.core.MethodParameter;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

/**
 * Supplies {@link CurrentActor} to controller methods from the authenticated security context.
 *
 * <p>Without this, Spring MVC treats an unannotated {@code CurrentActor} parameter as a model
 * attribute and tries to build one from request parameters — which means a client could supply
 * {@code ?userId=…} and have it accepted as the acting user. That is not a binding inconvenience;
 * it is impersonation, and it is precisely what BR-IAM-001 forbids ("resolved server-side from the
 * session, never from client-supplied claims").
 *
 * <p>So this resolver reads {@link GuardianPrincipal} and nothing else. There is no path here that
 * consults the request body, the query string, or a header.
 */
@Component
public class CurrentActorArgumentResolver implements HandlerMethodArgumentResolver {

  @Override
  public boolean supportsParameter(MethodParameter parameter) {
    return CurrentActor.class.equals(parameter.getParameterType());
  }

  @Override
  public Object resolveArgument(
      MethodParameter parameter,
      ModelAndViewContainer mavContainer,
      NativeWebRequest webRequest,
      WebDataBinderFactory binderFactory) {

    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

    if (authentication == null
        || !authentication.isAuthenticated()
        || !(authentication.getPrincipal() instanceof GuardianPrincipal principal)) {
      // Reached only if an endpoint declaring CurrentActor is somehow permitted through the
      // filter chain unauthenticated. Failing loudly beats handing the method a null actor and
      // letting an audit record be written with no attributable author (BR-AUD-003).
      throw new MissingActorException();
    }

    return principal.actor();
  }

  /**
   * No authenticated actor where one is required.
   *
   * <p>A 401 rather than a 500: the caller's remedy is to authenticate, and the global handler
   * already maps {@link ErrorCode#AUTH_TOKEN_MISSING} to that.
   */
  public static class MissingActorException extends RuntimeException {
    MissingActorException() {
      super(ErrorCode.AUTH_TOKEN_MISSING.name());
    }
  }
}
