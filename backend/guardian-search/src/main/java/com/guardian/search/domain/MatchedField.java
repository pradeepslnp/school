package com.guardian.search.domain;

/**
 * Which field of a record the query matched.
 *
 * <p>Returned so the console can show what was actually found — a phone number typed in should come
 * back as that number with the person it belongs to, not as a name the operator never typed.
 */
public enum MatchedField {
  NAME,
  ADMISSION_NO,
  PHONE,
  EMAIL,
  EMPLOYEE_CODE,
  REGISTRATION_NO,
  CODE
}
