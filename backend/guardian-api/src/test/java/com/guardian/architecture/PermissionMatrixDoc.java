package com.guardian.architecture;

import java.io.IOException;
import java.nio.file.Files;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Reads the permission codes out of {@code PERMISSION_MATRIX.md}.
 *
 * <p>Shared by the tests that assert code cannot drift from the matrix — the document is parsed
 * rather than duplicated, so a permission renamed there fails the build here.
 */
final class PermissionMatrixDoc {

  private static final Pattern PERMISSION_PATTERN = Pattern.compile("`(PERM-[A-Z0-9-]+)`");

  private PermissionMatrixDoc() {}

  /** Every permission code the matrix documents. */
  static Set<String> permissions() throws IOException {
    String content = Files.readString(DocsPath.of("01-product-discovery/PERMISSION_MATRIX.md"));
    Matcher matcher = PERMISSION_PATTERN.matcher(content);
    Set<String> permissions = new HashSet<>();
    while (matcher.find()) {
      permissions.add(matcher.group(1));
    }
    return permissions;
  }
}
