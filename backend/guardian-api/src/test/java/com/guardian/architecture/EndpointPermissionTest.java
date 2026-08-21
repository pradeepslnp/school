package com.guardian.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static org.assertj.core.api.Assertions.assertThat;

import com.guardian.common.BusinessRule;
import com.guardian.common.security.RequiresPermission;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption.DoNotIncludeTests;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Security invariants for HTTP endpoints.
 *
 * <p>Deny-by-default (BR-IAM-002) is enforced at build time rather than left to review: an endpoint
 * that declares no permission cannot ship.
 */
@AnalyzeClasses(packages = "com.guardian", importOptions = DoNotIncludeTests.class)
class EndpointPermissionTest {

  /** The permission matrix, resolved in the sibling {@code guardian-docs} repository. */
  private static final Path PERMISSION_MATRIX =
      DocsPath.of("01-product-discovery/PERMISSION_MATRIX.md");

  private static final Pattern PERMISSION_PATTERN = Pattern.compile("`(PERM-[A-Z0-9-]+)`");

  @ArchTest
  @BusinessRule("BR-IAM-002")
  static final ArchRule every_endpoint_declares_a_permission =
      methods()
          .that()
          .areAnnotatedWith("org.springframework.web.bind.annotation.GetMapping")
          .or()
          .areAnnotatedWith("org.springframework.web.bind.annotation.PostMapping")
          .or()
          .areAnnotatedWith("org.springframework.web.bind.annotation.PutMapping")
          .or()
          .areAnnotatedWith("org.springframework.web.bind.annotation.PatchMapping")
          .or()
          .areAnnotatedWith("org.springframework.web.bind.annotation.DeleteMapping")
          .should()
          .beAnnotatedWith(RequiresPermission.class)
          .orShould()
          .beAnnotatedWith("com.guardian.common.security.PublicEndpoint")
          .because(
              "access is deny-by-default (BR-IAM-002); an endpoint with no declared permission"
                  + " must not be reachable");

  @Test
  @BusinessRule("BR-IAM-002")
  @DisplayName("every declared permission exists in the permission matrix")
  void declaredPermissionsExistInTheMatrix() throws IOException {
    Set<String> documented = documentedPermissions();
    assertThat(documented).as("permission matrix should be readable and non-empty").isNotEmpty();

    JavaClasses classes =
        new ClassFileImporter()
            .withImportOption(new DoNotIncludeTests())
            .importPackages("com.guardian");

    Set<String> undocumented = new HashSet<>();
    classes.forEach(
        javaClass ->
            javaClass
                .getMethods()
                .forEach(
                    method ->
                        method
                            .tryGetAnnotationOfType(RequiresPermission.class)
                            .ifPresent(
                                annotation -> {
                                  if (!documented.contains(annotation.value())) {
                                    undocumented.add(
                                        javaClass.getSimpleName()
                                            + "#"
                                            + method.getName()
                                            + " → "
                                            + annotation.value());
                                  }
                                })));

    // The code cannot drift from the matrix: the matrix is parsed, not duplicated here.
    assertThat(undocumented)
        .as("permissions used in code but absent from PERMISSION_MATRIX.md")
        .isEmpty();
  }

  private static Set<String> documentedPermissions() throws IOException {
    String content = Files.readString(PERMISSION_MATRIX);
    Matcher matcher = PERMISSION_PATTERN.matcher(content);
    Set<String> permissions = new HashSet<>();
    while (matcher.find()) {
      permissions.add(matcher.group(1));
    }
    return permissions;
  }
}
