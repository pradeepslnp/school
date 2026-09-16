package com.guardian.search.domain;

import com.guardian.common.error.BusinessRuleViolationException;
import com.guardian.common.error.ErrorCode;
import java.util.Locale;
import java.util.Map;

/**
 * What an operator typed into global search, and the forms it is compared in (SRC-001).
 *
 * <p><strong>Held to a minimum length.</strong> Every search that shows a student writes a
 * data-access record for that student (BR-IAM-012 🔴). A one- or two-character query matches a
 * large share of a school and would record reads of children nobody was looking for, so the server
 * refuses it; the console not sending one is a courtesy, not the control.
 *
 * <p>A query is compared three ways: as text, case-insensitively, against names, codes, and email;
 * as digits against phone numbers, which the platform stores digits-only (so "80506 02046" finds
 * "8050602046"); and letters-and-digits-only against vehicle registrations (so "ka01ab" finds
 * "KA-01-AB-1234").
 */
public final class SearchQuery {

  public static final int MIN_LENGTH = 3;
  public static final int MAX_LENGTH = 100;

  /** Fewer digits than this are part of a word, not a number worth matching phones against. */
  private static final int MIN_DIGITS = 3;

  private final String text;
  private final String lower;
  private final String digits;
  private final String alphanumeric;

  private SearchQuery(String text, String lower, String digits, String alphanumeric) {
    this.text = text;
    this.lower = lower;
    this.digits = digits;
    this.alphanumeric = alphanumeric;
  }

  /**
   * @throws BusinessRuleViolationException {@code VALIDATION_VALUE_OUT_OF_RANGE} when the trimmed
   *     query is shorter than {@link #MIN_LENGTH} or longer than {@link #MAX_LENGTH}
   */
  public static SearchQuery of(String raw) {
    String trimmed = raw == null ? "" : raw.strip();
    if (trimmed.length() < MIN_LENGTH || trimmed.length() > MAX_LENGTH) {
      throw new BusinessRuleViolationException(
          ErrorCode.VALIDATION_VALUE_OUT_OF_RANGE,
          "BR-IAM-012",
          Map.of("field", "q", "minLength", MIN_LENGTH, "maxLength", MAX_LENGTH));
    }
    String lower = trimmed.toLowerCase(Locale.ROOT);
    String digits = trimmed.replaceAll("\\D", "");
    String alphanumeric = lower.replaceAll("[^\\p{L}\\p{N}]", "");
    return new SearchQuery(
        trimmed,
        lower,
        digits.length() >= MIN_DIGITS ? digits : null,
        alphanumeric.isEmpty() ? null : alphanumeric);
  }

  /** The query as typed, trimmed. */
  public String text() {
    return text;
  }

  /** A {@code LIKE} pattern matching the query anywhere in a lower-cased value. */
  public String containsPattern() {
    return "%" + escapeLike(lower) + "%";
  }

  /** A {@code LIKE} pattern matching values that start with the query — used to rank. */
  public String prefixPattern() {
    return escapeLike(lower) + "%";
  }

  /** A {@code LIKE} pattern over digits-only values, or null when the query is not a number. */
  public String digitsPattern() {
    return digits == null ? null : "%" + digits + "%";
  }

  /** A {@code LIKE} pattern over letters-and-digits-only values. */
  public String alphanumericPattern() {
    return alphanumeric == null ? containsPattern() : "%" + escapeLike(alphanumeric) + "%";
  }

  /** Whether {@code value} contains the query, compared as {@link #containsPattern()} compares. */
  public boolean matchesText(String value) {
    return value != null && value.toLowerCase(Locale.ROOT).contains(lower);
  }

  /** Whether {@code value}'s digits contain the query's digits. */
  public boolean matchesDigits(String value) {
    return digits != null && value != null && value.replaceAll("\\D", "").contains(digits);
  }

  /** Whether {@code value}'s letters and digits contain the query's. */
  public boolean matchesAlphanumeric(String value) {
    return alphanumeric != null
        && value != null
        && value.toLowerCase(Locale.ROOT).replaceAll("[^\\p{L}\\p{N}]", "").contains(alphanumeric);
  }

  private static String escapeLike(String value) {
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
  }
}
