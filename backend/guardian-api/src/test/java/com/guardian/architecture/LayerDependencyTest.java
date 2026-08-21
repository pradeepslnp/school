package com.guardian.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noFields;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.importer.ImportOption.DoNotIncludeTests;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * Architecture rules, enforced as build failures.
 *
 * <p>Documented architecture erodes; tested architecture does not. See
 * guardian-docs/06-development/ARCHITECTURE_ENFORCEMENT.md.
 *
 * <p>When one of these blocks legitimate work the answer is almost always to restructure the code —
 * never to disable the test. A disabled architecture test is an architecture that has already
 * eroded.
 */
@AnalyzeClasses(packages = "com.guardian", importOptions = DoNotIncludeTests.class)
class LayerDependencyTest {

  // --- Clean Architecture: dependencies point inward -----------------------------------

  @ArchTest
  static final ArchRule domain_depends_on_no_other_layer =
      noClasses()
          .that()
          .resideInAPackage("..domain..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage("..application..", "..infrastructure..", "..interfaces..")
          .because("the domain is the innermost layer and must not know its callers");

  @ArchTest
  static final ArchRule application_does_not_depend_on_infrastructure =
      noClasses()
          .that()
          .resideInAPackage("..application..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("..infrastructure..")
          .because("infrastructure implements application ports, not the reverse");

  @ArchTest
  static final ArchRule interfaces_do_not_reach_into_infrastructure =
      noClasses()
          .that()
          .resideInAPackage("..interfaces..")
          .should()
          .dependOnClassesThat()
          .resideInAPackage("..infrastructure..")
          .because("controllers call use cases, never repositories directly");

  // --- Framework isolation --------------------------------------------------------------

  @ArchTest
  static final ArchRule domain_is_free_of_frameworks =
      noClasses()
          .that()
          .resideInAPackage("..domain..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(
              "org.springframework..",
              "jakarta.persistence..",
              "jakarta.servlet..",
              "com.fasterxml.jackson..")
          .because(
              "safety records outlive framework choices; the domain must survive replacing any of"
                  + " them");

  @ArchTest
  static final ArchRule jpa_entities_stay_in_infrastructure =
      classes()
          .that()
          .areAnnotatedWith("jakarta.persistence.Entity")
          .should()
          .resideInAPackage("..infrastructure.persistence..")
          .because("a JPA entity reaching a client leaks the schema into the API contract");

  // --- Module boundaries ------------------------------------------------------------------

  @ArchTest
  static final ArchRule modules_are_free_of_cycles =
      slices()
          .matching("com.guardian.(*)..")
          .should()
          .beFreeOfCycles()
          .because("a dependency cycle between modules is a ball of mud in waiting");

  // --- Dependency injection ----------------------------------------------------------------

  @ArchTest
  static final ArchRule no_field_injection =
      noFields()
          .should()
          .beAnnotatedWith("org.springframework.beans.factory.annotation.Autowired")
          .because("constructor injection makes dependencies explicit and objects testable");

  @ArchTest
  static final ArchRule service_dependencies_are_final =
      fields()
          .that()
          .areDeclaredInClassesThat()
          .areAnnotatedWith("org.springframework.stereotype.Service")
          .and()
          .areNotStatic()
          .should()
          .beFinal()
          .because("mutable service state is shared mutable state");

  // --- Integration boundaries ---------------------------------------------------------------

  @ArchTest
  static final ArchRule no_provider_sdks_inside_the_domain =
      noClasses()
          .that()
          .resideInAnyPackage("..domain..", "..application..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage("com.google.firebase..", "com.twilio..", "software.amazon.awssdk..")
          .because("providers live behind ports (ADR-0004, ADR-0005), so a new vendor is additive");
}
