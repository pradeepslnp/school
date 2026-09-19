package com.guardian.architecture;

import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.common.BusinessRule;
import com.guardian.common.security.SystemRolePermissions;
import java.io.IOException;
import java.util.Set;
import java.util.TreeSet;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * {@link SystemRolePermissions} cannot name a permission the matrix does not define.
 *
 * <p>{@link EndpointPermissionTest} checks the codes endpoints <em>require</em>; this checks the
 * codes roles are <em>granted</em>. Nothing else covers the latter, and the two fail differently:
 * an undefined code in an endpoint annotation makes that endpoint unreachable, while an undefined
 * code in a role's grant set is simply inert — the role silently lacks a permission the matrix says
 * it holds, and the first symptom is a staff member refused mid-shift.
 *
 * <p><strong>Not checked here:</strong> whether each role's grants match the matrix grid cell by
 * cell. Parsing the granted, narrowed, and blank columns is a larger piece of work; until it
 * exists, a permission moved to the wrong role's set passes this test. The set sizes asserted below
 * are a coarse substitute — they catch a wholesale omission, not a misplacement.
 */
class SystemRolePermissionsDocConsistencyTest {

  @Test
  @BusinessRule("BR-IAM-002")
  @DisplayName("every granted permission exists in the permission matrix")
  void grantedPermissionsExistInTheMatrix() throws IOException {
    Set<String> documented = PermissionMatrixDoc.permissions();
    assertThat(documented).as("permission matrix should be readable and non-empty").isNotEmpty();

    Set<String> undocumented = new TreeSet<>();
    for (String roleCode : SystemRolePermissions.roleCodes()) {
      for (String permission : SystemRolePermissions.permissionsOf(roleCode)) {
        if (!documented.contains(permission)) {
          undocumented.add(roleCode + " -> " + permission);
        }
      }
    }

    assertThat(undocumented)
        .as("permissions granted in SystemRolePermissions but absent from PERMISSION_MATRIX.md")
        .isEmpty();
  }

  @Test
  @DisplayName("every role in the permission matrix has a grant set")
  void everyMatrixRoleIsRepresented() {
    assertThat(SystemRolePermissions.roleCodes())
        .containsExactlyInAnyOrder(
            "SUPER_ADMIN",
            "ORG_ADMIN",
            "SCHOOL_ADMIN",
            "PRINCIPAL",
            "TRANSPORT_MANAGER",
            "VENDOR_STAFF",
            "DRIVER",
            "ATTENDANT",
            "GUARDIAN");
  }

  /**
   * Counts transcribed from the matrix, counting a narrowed grant as held.
   *
   * <p>A checksum, not a specification. It fails loudly if a row is dropped during a matrix edit,
   * which is the failure mode the code-vs-document split invites.
   */
  @Test
  @DisplayName("grant set sizes match the matrix")
  void grantSetSizesMatchTheMatrix() {
    assertThat(SystemRolePermissions.permissionsOf("SUPER_ADMIN")).hasSize(62);
    assertThat(SystemRolePermissions.permissionsOf("ORG_ADMIN")).hasSize(55);
    assertThat(SystemRolePermissions.permissionsOf("SCHOOL_ADMIN")).hasSize(56);
    assertThat(SystemRolePermissions.permissionsOf("PRINCIPAL")).hasSize(25);
    assertThat(SystemRolePermissions.permissionsOf("TRANSPORT_MANAGER")).hasSize(45);
    assertThat(SystemRolePermissions.permissionsOf("VENDOR_STAFF")).hasSize(11);
    assertThat(SystemRolePermissions.permissionsOf("DRIVER")).hasSize(14);
    assertThat(SystemRolePermissions.permissionsOf("ATTENDANT")).hasSize(19);
    assertThat(SystemRolePermissions.permissionsOf("GUARDIAN")).hasSize(12);
  }

  @Test
  @BusinessRule("BR-IAM-002")
  @DisplayName("an unknown role grants nothing")
  void unknownRoleGrantsNothing() {
    assertThat(SystemRolePermissions.permissionsOf("NOT_A_ROLE")).isEmpty();
  }
}
