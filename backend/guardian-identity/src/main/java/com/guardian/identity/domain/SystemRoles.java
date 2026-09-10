package com.guardian.identity.domain;

import java.util.Map;
import java.util.Set;

/**
 * The nine system-role templates from PERMISSION_MATRIX.md, and the rules for who may assign which
 * to whom and at what scope.
 *
 * <p>Their <em>permissions</em> live in {@code com.guardian.common.security.SystemRolePermissions}
 * — this class is the identity-domain view: display names, the administrative subset the Users
 * screen manages, the assignable-role hierarchy, and which roles are school- or route-bound
 * (BR-IAM-006). Both {@code CreateAdministrativeUserUseCase} and {@code
 * ChangeAdministrativeUserRoleUseCase} read from here so the "create with role X" and "change role
 * to X" paths cannot diverge on what X means.
 */
public final class SystemRoles {

  /**
   * The roles the Users screen (A-43) creates and reassigns — organisation and school
   * administration. {@code DRIVER}/{@code ATTENDANT} are managed from the Drivers screen (A-23);
   * {@code GUARDIAN} is never administered this way; {@code SUPER_ADMIN} is a platform-operator
   * account, not tenant-assignable.
   */
  public static final Set<String> ADMINISTRATIVE =
      Set.of("ORG_ADMIN", "SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER");

  /**
   * Which administrative roles a caller in {@code actorRole} may grant — a product decision, since
   * PERMISSION_MATRIX.md spells out no creation hierarchy. Mirrors {@code
   * CreateAdministrativeUserUseCase.ASSIGNABLE_ROLES}: a {@code SUPER_ADMIN} may set any of them
   * (finishing a customer's onboarding without waiting on their own admin); an {@code ORG_ADMIN}
   * the school-scoped ones within their organisation; a {@code SCHOOL_ADMIN} {@code
   * PRINCIPAL}/{@code TRANSPORT_MANAGER} within their school.
   */
  private static final Map<String, Set<String>> ASSIGNABLE_BY_ACTOR =
      Map.of(
          "SUPER_ADMIN", Set.of("ORG_ADMIN", "SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER"),
          "ORG_ADMIN", Set.of("SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER"),
          "SCHOOL_ADMIN", Set.of("PRINCIPAL", "TRANSPORT_MANAGER"));

  /** Roles whose reach is one school rather than the whole organisation (BR-IAM-006). */
  private static final Set<String> SCHOOL_SCOPED =
      Set.of("SCHOOL_ADMIN", "PRINCIPAL", "TRANSPORT_MANAGER");

  private SystemRoles() {}

  public static boolean isAdministrative(String roleCode) {
    return ADMINISTRATIVE.contains(roleCode);
  }

  public static boolean isSchoolScoped(String roleCode) {
    return SCHOOL_SCOPED.contains(roleCode);
  }

  public static Set<String> assignableBy(String actorRole) {
    return ASSIGNABLE_BY_ACTOR.getOrDefault(actorRole, Set.of());
  }

  public static boolean canAssign(String actorRole, String targetRoleCode) {
    return assignableBy(actorRole).contains(targetRoleCode);
  }

  /** The stored {@code roles.name} for a template code. */
  public static String displayName(String roleCode) {
    return switch (roleCode) {
      case "SUPER_ADMIN" -> "Super Admin";
      case "ORG_ADMIN" -> "Organization Admin";
      case "SCHOOL_ADMIN" -> "School Admin";
      case "PRINCIPAL" -> "Principal";
      case "TRANSPORT_MANAGER" -> "Transport Manager";
      default -> roleCode;
    };
  }
}
