package com.guardian.tenancy.application.port;

import com.guardian.tenancy.domain.OrganizationCode;

/**
 * The one lookup in this module that runs without tenant context — the same shape as {@code
 * PreAuthenticationDirectory} in guardian-identity, for the same reason.
 *
 * <p>An organization's code is unique across the whole platform (BR-TEN-007), but {@link
 * com.guardian.tenancy.application.usecase.CreateOrganizationUseCase} runs before the tenant being
 * checked against exists, and the actor's own tenant context (a platform-operations organization,
 * for a {@code SUPER_ADMIN}) is not it. An ordinary RLS-scoped read cannot answer "does any
 * organization use this code" — only its own row is visible. This port is implemented by a {@code
 * SECURITY DEFINER} SQL function (V11__organization_code_resolution.sql) granted narrowly to the
 * application role, returning only a boolean — never a row, never another organization's data.
 */
public interface OrganizationCodeDirectory {

  /** Whether any organization on the platform already uses this code. */
  boolean existsGlobally(OrganizationCode code);
}
