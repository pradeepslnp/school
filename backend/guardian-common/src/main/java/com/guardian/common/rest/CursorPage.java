package com.guardian.common.rest;

import java.util.List;
import java.util.Objects;

/**
 * One page of a collection, with the cursor that reaches the next.
 *
 * <p>A controller returns this instead of a bare {@code List} when the collection can grow without
 * bound. {@code ResponseEnvelopeAdvice} unpacks it into the envelope API_STANDARDS.md specifies —
 * the items become {@code data}, the cursor becomes {@code meta.pagination} — so the shape on the
 * wire is the documented one and no controller assembles it by hand.
 *
 * <p><strong>Cursor, never offset.</strong> An offset re-scans the rows it skips, and shifts under
 * concurrent inserts so that a row is returned twice or missed entirely. On a student register the
 * second of those is a child absent from a list somebody is checking.
 *
 * @param nextCursor opaque to the client; null on the last page
 */
public record CursorPage<T>(List<T> items, String nextCursor, int limit) {

  public CursorPage {
    items = List.copyOf(Objects.requireNonNull(items, "items"));
  }

  public static <T> CursorPage<T> of(List<T> items, String nextCursor, int limit) {
    return new CursorPage<>(items, nextCursor, limit);
  }

  public boolean hasMore() {
    return nextCursor != null;
  }
}
