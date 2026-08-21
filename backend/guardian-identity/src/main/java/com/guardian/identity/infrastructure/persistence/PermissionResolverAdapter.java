package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.security.SystemRolePermissions;
import com.guardian.identity.application.port.PermissionResolver;
import com.guardian.identity.domain.UserId;
import java.util.HashSet;
import java.util.Set;
import org.springframework.stereotype.Component;

/** Implements {@link PermissionResolver} over JPA. */
@Component
class PermissionResolverAdapter implements PermissionResolver {

  private final PermissionJpaRepository jpaRepository;

  PermissionResolverAdapter(PermissionJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Set<String> resolve(UserId userId) {
    Set<String> resolved = new HashSet<>();

    for (PermissionJpaRepository.RoleGrantRow row : jpaRepository.findRoleGrants(userId.value())) {
      if (row.isSystemRole()) {
        // The row's permissionCode is ignored, not merely absent. A stray role_permissions row
        // against a system role is never consulted, which is what makes "the matrix templates are
        // fixed, not tenant-configurable" true of the system rather than only of the convention.
        resolved.addAll(SystemRolePermissions.permissionsOf(row.getRoleCode()));
      } else if (row.getPermissionCode() != null) {
        resolved.add(row.getPermissionCode());
      }
    }

    return Set.copyOf(resolved);
  }
}
