/// Shared domain types for the administration console.
///
/// A local stand-in for the missing `guardian_core` package (see `pubspec.yaml`). When
/// `guardian_core` is restored this file should be deleted and its types imported from
/// there — the shapes are kept deliberately compatible with the driver and parent apps'
/// `core/domain.dart` so the merge is mechanical.
///
/// **No Flutter imports.** This is the domain layer; keeping `package:flutter` out of it is
/// what lets these rules be tested without a widget binding, and is what keeps the console's
/// meaning portable if ADR-0003 is reversed and the view layer is rebuilt in React
/// (CODING_STANDARDS_FLUTTER.md §guardian_core).
library;

/// The outcome of a domain operation.
///
/// Expected failures — wrong credentials, a locked account, an unreachable API — are
/// returned, not thrown. Code that has to remember a `try` around every call eventually
/// forgets one, and the forgotten one is always on the path nobody exercised.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.code, {this.messageKey, this.businessRule, this.detail});

  final ErrorCode code;

  /// Localisation key supplied by the API (BR-CFG-005).
  ///
  /// The UI renders from this, never from a server-supplied display string — the server
  /// does not know which language the operator reads (API_STANDARDS.md §Error).
  final String? messageKey;

  /// The business rule that caused the refusal, e.g. `BR-GRD-002`. Always present on a
  /// `422` (ERROR_CATALOG.md §Conventions).
  ///
  /// This console is the surface where it matters most: ADMIN_WEB.md A-06 requires every
  /// safety-exception row to carry the rule ID that caught it, so "what happened" and
  /// "which control caught it" are answerable together.
  final String? businessRule;

  /// Internal diagnostic detail. **Never rendered.** For logs and bug reports only.
  final String? detail;
}

/// The error codes this console can currently meet, from [`ERROR_CATALOG.md`].
///
/// An enum rather than a raw string so a `switch` on an outcome is exhaustive and a typo is
/// a compile error. [ErrorCode.unknown] exists because new codes ship additively within
/// `v1` (API_STANDARDS.md) — a deployed console will meet a code it was not built with, and
/// must say so plainly rather than guess at the nearest familiar one.
///
/// **Scope is deliberate.** Only the cross-cutting codes are here: authentication,
/// authorisation, tenancy, validation, and transport. Every screen can meet these. Domain
/// codes — `STUDENT_*`, `VEHICLE_*`, `ROUTE_*` — are added by the feature that first meets
/// them, because an enum case no screen can produce is dead code that still has to be
/// handled in every exhaustive switch (ENGINEERING_PRINCIPLES.md §7, §15).
enum ErrorCode {
  // --- Authentication ---
  authCredentialsInvalid,
  authTokenMissing,
  authTokenExpired,
  authTokenInvalid,
  authSessionRevoked,
  authRefreshReuseDetected,
  authAccountLocked,

  // --- Authorisation and tenancy ---
  authPermissionDenied,
  authScopeDenied,

  /// Cross-tenant access. The API answers `404`, not `403` — the resource is invisible
  /// rather than forbidden, so its existence cannot be probed (BR-TEN-004).
  authTenantMismatch,

  /// Platform-operator elevation attempted without a justification (BR-TEN-004).
  authJustificationRequired,

  // --- Validation ---
  validationFailed,
  validationRequiredFieldMissing,
  validationInvalidFormat,
  validationValueOutOfRange,

  // --- Tenancy ---
  // First met by the organization-onboarding screen (TEN-001, TEN-002) — see the note on
  // ErrorCode's own documentation about when a domain code is added.
  orgCodeAlreadyExists,
  schoolCodeAlreadyExists,

  // --- Transport staff ---
  // First met by the Drivers screen's edit dialog (STF-001) — see the note above on when a
  // domain code is added.
  staffEmployeeCodeExists,

  // --- Students ---
  // First met by the student register (A-10, STU-001). `studentAdmissionNoExists` is the one
  // the office actually hits: two people entering the same admission number from the same
  // paper list is ordinary, and the message must name the field rather than say "conflict".
  studentNotFound,
  studentAdmissionNoExists,
  studentNotActive,

  // --- Transport & system ---
  rateLimitExceeded,
  dependencyUnavailable,
  internalError,

  /// A code this build does not recognise. Shown as unknown, never mapped onto a neighbour.
  unknown;

  static ErrorCode fromWire(String? wire) => switch (wire) {
        'AUTH_CREDENTIALS_INVALID' => authCredentialsInvalid,
        'AUTH_TOKEN_MISSING' => authTokenMissing,
        'AUTH_TOKEN_EXPIRED' => authTokenExpired,
        'AUTH_TOKEN_INVALID' => authTokenInvalid,
        'AUTH_SESSION_REVOKED' => authSessionRevoked,
        'AUTH_REFRESH_REUSE_DETECTED' => authRefreshReuseDetected,
        'AUTH_ACCOUNT_LOCKED' => authAccountLocked,
        'AUTH_PERMISSION_DENIED' => authPermissionDenied,
        'AUTH_SCOPE_DENIED' => authScopeDenied,
        'AUTH_TENANT_MISMATCH' => authTenantMismatch,
        'AUTH_JUSTIFICATION_REQUIRED' => authJustificationRequired,
        'VALIDATION_FAILED' => validationFailed,
        'VALIDATION_REQUIRED_FIELD_MISSING' => validationRequiredFieldMissing,
        'VALIDATION_INVALID_FORMAT' => validationInvalidFormat,
        'VALIDATION_VALUE_OUT_OF_RANGE' => validationValueOutOfRange,
        'ORG_CODE_ALREADY_EXISTS' => orgCodeAlreadyExists,
        'SCHOOL_CODE_ALREADY_EXISTS' => schoolCodeAlreadyExists,
        'STAFF_EMPLOYEE_CODE_EXISTS' => staffEmployeeCodeExists,
        'STUDENT_NOT_FOUND' => studentNotFound,
        'STUDENT_ADMISSION_NO_EXISTS' => studentAdmissionNoExists,
        'STUDENT_NOT_ACTIVE' => studentNotActive,
        'RATE_LIMIT_EXCEEDED' => rateLimitExceeded,
        'DEPENDENCY_UNAVAILABLE' => dependencyUnavailable,
        'INTERNAL_ERROR' => internalError,
        _ => unknown,
      };

  /// Whether the session is over and the operator must sign in again.
  ///
  /// [authRefreshReuseDetected] is included: the whole token family is revoked when reuse is
  /// detected, so the legitimate user is signed out too (BR-IAM-009). That is the intended
  /// trade — a captured refresh token for an account that can read every child's record in a
  /// school is not something to resolve gently.
  bool get endsSession =>
      this == authSessionRevoked ||
      this == authRefreshReuseDetected ||
      this == authTokenInvalid ||
      this == authCredentialsInvalid;
}
