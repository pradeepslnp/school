package com.guardian.identity.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * Spring Data repository for permission resolution. Package-private — callers use {@link
 * com.guardian.identity.application.port.PermissionResolver}.
 *
 * <p>Extends {@link Repository} rather than {@code JpaRepository}: this exposes one projection and
 * has no CRUD surface. {@code UserEntity} appears only to satisfy the type parameter — {@code
 * roles}, {@code user_roles}, {@code role_permissions} and {@code permissions} have no entities,
 * and mapping four tables to produce a set of strings would be weight with no reader.
 *
 * <p>Nothing here filters on {@code tenant_id}: row-level security applies that predicate
 * (ADR-0001). {@code permissions} is the exception that proves it — platform reference data with no
 * {@code tenant_id} and no policy, readable by every tenant.
 */
interface PermissionJpaRepository extends Repository<UserEntity, UUID> {

  /**
   * One row per (role, granted permission) pair for a user.
   *
   * <p>The join to {@code role_permissions} is a LEFT JOIN because system roles have no rows there
   * — their permissions come from {@code SystemRolePermissions}, so {@code permissionCode} is null
   * for every system-role row and the caller reads {@code systemRole} to decide which source
   * applies. An inner join would silently drop system roles entirely and deny every request they
   * make.
   */
  @Query(
      value =
          """
          SELECT r.code           AS roleCode,
                 r.is_system_role AS systemRole,
                 p.code           AS permissionCode
          FROM user_roles ur
          JOIN roles r ON r.id = ur.role_id
          LEFT JOIN role_permissions rp ON rp.role_id = r.id
          LEFT JOIN permissions p ON p.id = rp.permission_id
          WHERE ur.user_id = :userId
          """,
      nativeQuery = true)
  List<RoleGrantRow> findRoleGrants(@Param("userId") UUID userId);

  /** Projection for {@link #findRoleGrants}. */
  interface RoleGrantRow {

    String getRoleCode();

    boolean isSystemRole();

    /** Null for system roles, which resolve from code rather than from {@code role_permissions}. */
    String getPermissionCode();
  }
}
