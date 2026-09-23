package com.guardian.architecture;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Proves that documented business rules are actually enforced.
 *
 * <p>{@code DOCUMENT_HIERARCHY.md} invariant 2: every business rule ID has at least one test
 * referencing it. <strong>A rule documented but untested is worse than an undocumented one</strong>
 * — it creates confidence that nothing supports.
 *
 * <p>This test is the mechanism that stops "documentation is the source of truth" decaying into an
 * aspiration as the codebase grows.
 *
 * <p>Areas whose module has not been built yet are exempted via {@code traceability-baseline.txt}.
 * That file only ever shrinks: removing a line is part of delivering a module. The exemption is
 * deliberate and visible rather than silent — see
 * guardian-docs/06-development/DEFINITION_OF_DONE.md on documented versus silent incompleteness.
 */
class BusinessRuleTraceabilityTest {

  private static final Path BUSINESS_RULES = DocsPath.of("01-product-discovery/BUSINESS_RULES.md");

  /** Matches a rule table row, capturing the ID and the rule text (which may contain 🔴). */
  private static final Pattern RULE_ROW =
      Pattern.compile("^\\|\\s*(BR-[A-Z]+-\\d{3})\\s*\\|(.*)$", Pattern.MULTILINE);

  @Test
  @DisplayName("every implemented business rule is referenced by at least one test")
  void everyImplementedRuleHasATest() throws IOException {
    Set<String> pendingAreas = pendingAreas();
    Set<String> referenced = referencedRules();

    Set<String> untested = new TreeSet<>();
    for (RuleEntry rule : documentedRules()) {
      if (isPending(rule.id(), pendingAreas) || referenced.contains(rule.id())) {
        continue;
      }
      untested.add(rule.id());
    }

    assertThat(untested)
        .as(
            """
            Business rules documented in BUSINESS_RULES.md with no @BusinessRule test.

            Either write the test, or — if the module is not built yet — add its area
            prefix to traceability-baseline.txt. Do not delete the rule.
            """)
        .isEmpty();
  }

  @Test
  @DisplayName("every @BusinessRule reference names a rule that actually exists")
  void everyReferencedRuleIsDocumented() throws IOException {
    Set<String> documented = new TreeSet<>();
    documentedRules().forEach(rule -> documented.add(rule.id()));

    Set<String> unknown = new TreeSet<>(referencedRules());
    unknown.removeAll(documented);

    // Catches typos, and rules removed from the documentation without their tests.
    assertThat(unknown)
        .as("rule IDs referenced in tests but absent from BUSINESS_RULES.md")
        .isEmpty();
  }

  @Test
  @DisplayName("the pending-areas baseline does not exempt an already-implemented area")
  void baselineDoesNotExemptImplementedAreas() throws IOException {
    Set<String> pendingAreas = pendingAreas();
    Set<String> referenced = referencedRules();

    Set<String> staleEntries = new TreeSet<>();
    for (String entry : pendingAreas) {
      boolean isAreaEntry = !entry.matches("BR-[A-Z]+-\\d{3}");
      if (isAreaEntry && referenced.stream().anyMatch(id -> id.startsWith(entry + "-"))) {
        staleEntries.add(entry);
      }
      // A rule listed individually that now has a test is simply done.
      if (!isAreaEntry && referenced.contains(entry)) {
        staleEntries.add(entry);
      }
    }

    // Keeps the baseline shrinking. Once an area has any coverage it must be replaced by the
    // specific rule IDs still outstanding, so newly documented rules in a live module are held
    // to the standard instead of hiding behind a blanket exemption.
    assertThat(staleEntries)
        .as(
            """
            Baseline entries that already have tests.

            An area prefix with coverage must be replaced by the individual rule IDs still
            outstanding. A rule ID with coverage must simply be deleted.
            """)
        .isEmpty();
  }

  // --- helpers ------------------------------------------------------------------------

  private record RuleEntry(String id, boolean safetyCritical) {}

  private static Set<RuleEntry> documentedRules() throws IOException {
    String content = Files.readString(BUSINESS_RULES);
    Matcher matcher = RULE_ROW.matcher(content);
    Set<RuleEntry> rules = new LinkedHashSet<>();
    while (matcher.find()) {
      rules.add(new RuleEntry(matcher.group(1), matcher.group(2).contains("🔴")));
    }
    return rules;
  }

  /**
   * Whether a rule is exempt.
   *
   * <p>An entry is either a whole area ({@code BR-INC}) for a module that does not exist yet, or a
   * single rule ID ({@code BR-TEN-006}) for one unbuilt behaviour inside a module that otherwise is
   * built. Area entries alone were too coarse: they would have exempted every future rule in a
   * module that is already half-delivered, which is precisely where a missed rule is most likely.
   */
  private static boolean isPending(String ruleId, Set<String> baseline) {
    return baseline.contains(ruleId)
        || baseline.stream().anyMatch(entry -> ruleId.startsWith(entry + "-"));
  }

  private static Set<String> pendingAreas() throws IOException {
    Set<String> areas = new LinkedHashSet<>();
    try (InputStream in =
        BusinessRuleTraceabilityTest.class
            .getClassLoader()
            .getResourceAsStream("traceability-baseline.txt")) {
      if (in == null) {
        return areas;
      }
      String content = new String(in.readAllBytes(), StandardCharsets.UTF_8);
      content
          .lines()
          .map(String::trim)
          .filter(line -> !line.isEmpty() && !line.startsWith("#"))
          .forEach(areas::add);
    }
    return areas;
  }

  /** Source roots searched for {@code @BusinessRule} citations. */
  private static final List<Path> SOURCE_ROOTS =
      List.of(
          Path.of("../guardian-common/src"),
          Path.of("../guardian-tenancy/src"),
          Path.of("../guardian-identity/src"),
          Path.of("../guardian-student/src"),
          Path.of("../guardian-guardian/src"),
          Path.of("../guardian-fleet/src"),
          Path.of("../guardian-staff/src"),
          Path.of("../guardian-routes/src"),
          Path.of("../guardian-trip/src"),
          Path.of("../guardian-boarding/src"),
          Path.of("../guardian-absence/src"),
          Path.of("../guardian-notification/src"),
          Path.of("../guardian-parent/src"),
          Path.of("src"));

  /** Captures the argument list of a {@code @BusinessRule(...)} citation. */
  private static final Pattern BUSINESS_RULE_CITATION =
      Pattern.compile("@BusinessRule\\s*\\(([^)]*)\\)", Pattern.DOTALL);

  private static final Pattern QUOTED_RULE_ID = Pattern.compile("\"(BR-[A-Z]+-\\d{3})\"");

  /**
   * Collects every business rule cited anywhere in the source tree.
   *
   * <p>Reads source files rather than reflecting over compiled classes. Bytecode scanning was tried
   * first and silently missed the concrete test classes under Gradle's isolated test classloader —
   * the worst possible failure mode for this check, because an empty result set makes every
   * assertion pass while proving nothing. Reading source sees exactly what a reviewer sees and
   * cannot be defeated by classpath composition.
   */
  private static Set<String> referencedRules() throws IOException {
    Set<String> referenced = new LinkedHashSet<>();

    for (Path root : SOURCE_ROOTS) {
      if (!Files.isDirectory(root)) {
        continue;
      }
      try (Stream<Path> files = Files.walk(root)) {
        List<Path> javaFiles =
            files
                .filter(Files::isRegularFile)
                .filter(path -> path.toString().endsWith(".java"))
                .toList();

        for (Path file : javaFiles) {
          collectFrom(referenced, Files.readString(file, StandardCharsets.UTF_8));
        }
      }
    }
    return referenced;
  }

  private static void collectFrom(Set<String> target, String source) {
    Matcher citations = BUSINESS_RULE_CITATION.matcher(source);
    while (citations.find()) {
      Matcher ids = QUOTED_RULE_ID.matcher(citations.group(1));
      while (ids.find()) {
        target.add(ids.group(1));
      }
    }
  }
}
