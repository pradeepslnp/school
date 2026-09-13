package com.guardian.infrastructure.tenant;

import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantId;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Component;

/**
 * The platform-operations path across the tenant boundary (BR-TEN-004).
 *
 * <p>BR-TEN-004 forbids reading or writing another organization's data <em>except through an
 * explicitly permissioned platform-operations path, which is always audited</em>. This is that
 * path, and the three words matter separately:
 *
 * <ul>
 *   <li><strong>Explicit.</strong> A platform operator names the organization they are acting in,
 *       per request, in {@link #HEADER}. Nothing is implicit and nothing is sticky: a request
 *       without the header acts in the operator's own tenant, as every other session does.
 *   <li><strong>Permissioned.</strong> The header is honoured only for {@code SUPER_ADMIN}, whose
 *       scope is {@code PLATFORM} (PERMISSION_MATRIX.md). Anyone else sending it is refused
 *       outright — see {@link #authorize}.
 *   <li><strong>Audited.</strong> {@link TenantContextFilter} writes an audit record for every
 *       elevated request, into the target organization's own trail (BR-AUD-005).
 * </ul>
 *
 * <h2>Why this does not reintroduce the attack RLS exists to stop</h2>
 *
 * {@link SecurityContextTenantResolver} documents the rule this class is the sole exception to: the
 * tenant comes from the token, never from the request. That rule exists because a client-supplied
 * tenant would let <em>any</em> authenticated user address another organization's children.
 *
 * <p>What makes this exception safe is that the header is not trusted — it is a <em>request</em>
 * that the server authorizes against the token's own role before honouring. The decision still
 * comes from the credential; only the target is named by the client, and only a role the token
 * proves may name one. For every other caller the header is not ignored but rejected, so an attempt
 * to escalate fails loudly rather than silently succeeding at the caller's own scope.
 *
 * <p>Row-level security is untouched: {@code guardian_app} still holds no {@code BYPASSRLS}, every
 * policy still compares {@code tenant_id} to {@code app.tenant_id}, and an elevated request is
 * confined to exactly one organization — the one it named. This widens who may set that variable,
 * never what the variable does.
 */
@Component
public class PlatformElevation {

  /**
   * Names the organization a platform operator is acting in.
   *
   * <p>A header rather than a query parameter: it applies uniformly to every endpoint, cannot
   * collide with a resource's own parameters, and does not end up in a bookmarked URL that would
   * make a cross-tenant action look like an ordinary link.
   */
  public static final String HEADER = "X-Guardian-Organization";

  /** The only role whose scope is {@code PLATFORM} (PERMISSION_MATRIX.md §Roles). */
  private static final String PLATFORM_ROLE = "SUPER_ADMIN";

  /**
   * The organization this request asks to act in, or empty when it asks for none.
   *
   * <p>Parsing only — this says nothing about whether the caller may have it. {@link #authorize}
   * decides that, and the caller of this method must not act on the result before asking.
   *
   * @throws PermissionDeniedException when the header is present but not a UUID. A malformed target
   *     is refused rather than ignored: silently falling back to the operator's own tenant would
   *     run the request somewhere other than where they asked, which for a write is the worst of
   *     the available outcomes.
   */
  public Optional<TenantId> requestedOrganization(HttpServletRequest request) {
    String raw = request.getHeader(HEADER);
    if (raw == null || raw.isBlank()) {
      return Optional.empty();
    }

    try {
      return Optional.of(TenantId.of(UUID.fromString(raw.trim())));
    } catch (IllegalArgumentException e) {
      throw new PermissionDeniedException(
          "%s is not a valid organization identifier".formatted(HEADER));
    }
  }

  /**
   * Refuses the elevation unless the actor holds the platform role.
   *
   * <p>Deliberately a refusal and not a silent downgrade to the actor's own tenant. A non-platform
   * caller sending this header is either mistaken or probing; both are worth surfacing, and neither
   * should be answered with data.
   */
  public void authorize(CurrentActor actor) {
    if (!PLATFORM_ROLE.equals(actor.role())) {
      throw new PermissionDeniedException(
          "Acting in another organization requires the %s role".formatted(PLATFORM_ROLE));
    }
  }
}
