package com.guardian.architecture;

import java.nio.file.Path;

/**
 * Locates the {@code guardian-docs} repository from a test.
 *
 * <p>Documentation lives in a sibling repository rather than this one, so the architecture tests
 * that parse it need a path that survives being cloned somewhere other than a developer's laptop.
 * The default assumes the conventional layout — every Guardian repository checked out side by side
 * in one parent directory — and {@code GUARDIAN_DOCS_PATH} overrides it for CI, where the checkout
 * location is the build system's choice rather than ours.
 *
 * <p>Nothing here degrades gracefully when the docs are missing. That is deliberate: {@link
 * BusinessRuleTraceabilityTest} and {@link EndpointPermissionTest} exist to prove documented rules
 * are enforced, and a test that quietly skips when it cannot find the documentation would report
 * success for a guarantee it never checked.
 */
final class DocsPath {

  /** Relative to a Gradle module directory ({@code guardian-backend/guardian-api}). */
  private static final String DEFAULT_DOCS_ROOT = "../../guardian-docs";

  private static final String ENV_VAR = "GUARDIAN_DOCS_PATH";

  private DocsPath() {}

  /**
   * Resolves a path within the docs repository.
   *
   * @param relative path relative to the docs repository root, e.g. {@code
   *     "01-product-discovery/BUSINESS_RULES.md"}
   */
  static Path of(String relative) {
    String root = System.getenv(ENV_VAR);
    if (root == null || root.isBlank()) {
      root = DEFAULT_DOCS_ROOT;
    }
    return Path.of(root).resolve(relative);
  }
}
