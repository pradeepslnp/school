/// Shared domain types for the driver and attendant app.
///
/// A local stand-in for the missing `guardian_core` package (see `pubspec.yaml`). When
/// `guardian_core` is restored this file should be deleted and its types imported from
/// there — the shapes are kept deliberately compatible with the parent app's `core/domain.dart`
/// so the merge is mechanical.
///
/// **No Flutter imports.** This is the domain layer; keeping `package:flutter` out of it is
/// what lets these rules be tested without a widget binding, and is enforced for
/// `guardian_core` by a dependency test (CODING_STANDARDS_FLUTTER.md §guardian_core).
library;

/// The outcome of a domain operation.
///
/// Expected failures — a wrong OTP, a refused boarding, no network — are returned, not
/// thrown. In this app "the request failed" is an ordinary condition on a route, and code
/// that has to remember a `try` around every call eventually forgets one.
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
  /// does not know which language the attendant reads.
  final String? messageKey;

  /// The business rule that caused the refusal, e.g. `BR-SAFE-003`. Always present on a
  /// `422` (ERROR_CATALOG.md §Conventions).
  final String? businessRule;

  /// Internal diagnostic detail. **Never rendered.** For logs and bug reports only.
  final String? detail;
}

/// Every error code this app can meet, from [`ERROR_CATALOG.md`].
///
/// An enum rather than a raw string so a `switch` on an outcome is exhaustive and a typo is
/// a compile error. [ErrorCode.unknown] exists because new codes ship additively within
/// `v1` (API_STANDARDS.md) — an app in the field will meet a code it was not built with, and
/// must show that plainly rather than guess at the nearest familiar one.
enum ErrorCode {
  // --- Authentication & authorisation ---
  authCredentialsInvalid,
  authTokenMissing,
  authTokenExpired,
  authTokenInvalid,
  authSessionRevoked,
  authRefreshReuseDetected,
  authAccountLocked,
  authOtpExpired,
  authOtpAlreadyUsed,
  authPermissionDenied,
  authScopeDenied,

  // --- Validation ---
  validationFailed,
  validationRequiredFieldMissing,
  validationInvalidFormat,

  // --- Trips ---
  tripInvalidStatusTransition,
  tripVehicleOnAnotherTrip,
  tripNotStarted,
  tripAlreadyCompleted,
  tripManifestImmutable,
  tripAmendmentReasonRequired,
  tripReconciliationIncomplete,
  tripNotAuthorisedActor,

  // --- Trip-start eligibility gate (BR-TRIP-004) ---
  //
  // Modelled individually rather than as one "cannot start" code. A driver refused at
  // 6:30 AM with a generic refusal cannot act; a driver told the fitness certificate
  // expired can call the manager and get another vehicle (TRIPS_BOARDING_API.md).
  vehicleDocumentExpired,
  vehicleNotActive,
  vehicleCapacityExceeded,
  staffLicenceExpired,
  staffLicenceClassInvalid,
  staffNotVerified,
  staffVerificationLapsed,
  staffAlreadyOnActiveTrip,
  attendantRequired,

  // --- Boarding (BRD-*) ---
  boardingStudentNotOnManifest,
  boardingAlreadyBoarded,
  boardingNotBoarded,
  boardingWrongStop,
  boardingWrongVehicle,
  boardingOverrideReasonRequired,
  boardingEventImmutable,
  boardingCredentialInvalid,

  // --- Handover ---
  handoverReceiverNotAuthorised,
  handoverVerificationFailed,
  handoverAlreadyRecorded,
  handoverRequiresAlightEvent,
  handoverOverrideRequiresReceiverIdentity,
  handoverRefusedCustodyRestriction,
  custodyRestrictionActive,
  pickupPersonOutsideValidity,
  pickupPersonRevoked,
  reconciliationResolutionIncomplete,

  // --- Incidents ---
  sosAlreadyAcknowledged,
  sosCannotBeDeleted,
  incidentResolutionRequired,

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
        'AUTH_OTP_EXPIRED' => authOtpExpired,
        'AUTH_OTP_ALREADY_USED' => authOtpAlreadyUsed,
        'AUTH_PERMISSION_DENIED' => authPermissionDenied,
        'AUTH_SCOPE_DENIED' => authScopeDenied,
        'VALIDATION_FAILED' => validationFailed,
        'VALIDATION_REQUIRED_FIELD_MISSING' => validationRequiredFieldMissing,
        'VALIDATION_INVALID_FORMAT' => validationInvalidFormat,
        'TRIP_INVALID_STATUS_TRANSITION' => tripInvalidStatusTransition,
        'TRIP_VEHICLE_ON_ANOTHER_TRIP' => tripVehicleOnAnotherTrip,
        'TRIP_NOT_STARTED' => tripNotStarted,
        'TRIP_ALREADY_COMPLETED' => tripAlreadyCompleted,
        'TRIP_MANIFEST_IMMUTABLE' => tripManifestImmutable,
        'TRIP_AMENDMENT_REASON_REQUIRED' => tripAmendmentReasonRequired,
        'TRIP_RECONCILIATION_INCOMPLETE' => tripReconciliationIncomplete,
        'TRIP_NOT_AUTHORISED_ACTOR' => tripNotAuthorisedActor,
        'VEHICLE_DOCUMENT_EXPIRED' => vehicleDocumentExpired,
        'VEHICLE_NOT_ACTIVE' => vehicleNotActive,
        'VEHICLE_CAPACITY_EXCEEDED' => vehicleCapacityExceeded,
        'STAFF_LICENCE_EXPIRED' => staffLicenceExpired,
        'STAFF_LICENCE_CLASS_INVALID' => staffLicenceClassInvalid,
        'STAFF_NOT_VERIFIED' => staffNotVerified,
        'STAFF_VERIFICATION_LAPSED' => staffVerificationLapsed,
        'STAFF_ALREADY_ON_ACTIVE_TRIP' => staffAlreadyOnActiveTrip,
        'ATTENDANT_REQUIRED' => attendantRequired,
        'BOARDING_STUDENT_NOT_ON_MANIFEST' => boardingStudentNotOnManifest,
        'BOARDING_ALREADY_BOARDED' => boardingAlreadyBoarded,
        'BOARDING_NOT_BOARDED' => boardingNotBoarded,
        'BOARDING_WRONG_STOP' => boardingWrongStop,
        'BOARDING_WRONG_VEHICLE' => boardingWrongVehicle,
        'BOARDING_OVERRIDE_REASON_REQUIRED' => boardingOverrideReasonRequired,
        'BOARDING_EVENT_IMMUTABLE' => boardingEventImmutable,
        'BOARDING_CREDENTIAL_INVALID' => boardingCredentialInvalid,
        'HANDOVER_RECEIVER_NOT_AUTHORISED' => handoverReceiverNotAuthorised,
        'HANDOVER_VERIFICATION_FAILED' => handoverVerificationFailed,
        'HANDOVER_ALREADY_RECORDED' => handoverAlreadyRecorded,
        'HANDOVER_REQUIRES_ALIGHT_EVENT' => handoverRequiresAlightEvent,
        'HANDOVER_OVERRIDE_REQUIRES_RECEIVER_IDENTITY' =>
          handoverOverrideRequiresReceiverIdentity,
        'HANDOVER_REFUSED_CUSTODY_RESTRICTION' =>
          handoverRefusedCustodyRestriction,
        'CUSTODY_RESTRICTION_ACTIVE' => custodyRestrictionActive,
        'PICKUP_PERSON_OUTSIDE_VALIDITY' => pickupPersonOutsideValidity,
        'PICKUP_PERSON_REVOKED' => pickupPersonRevoked,
        'RECONCILIATION_RESOLUTION_INCOMPLETE' =>
          reconciliationResolutionIncomplete,
        'SOS_ALREADY_ACKNOWLEDGED' => sosAlreadyAcknowledged,
        'SOS_CANNOT_BE_DELETED' => sosCannotBeDeleted,
        'INCIDENT_RESOLUTION_REQUIRED' => incidentResolutionRequired,
        'RATE_LIMIT_EXCEEDED' => rateLimitExceeded,
        'DEPENDENCY_UNAVAILABLE' => dependencyUnavailable,
        'INTERNAL_ERROR' => internalError,
        _ => unknown,
      };

  /// Whether the session is over and the user must sign in again.
  ///
  /// [authRefreshReuseDetected] is included: the whole token family is revoked when reuse is
  /// detected, so the legitimate user is signed out too (BR-IAM-009). That is the intended
  /// trade — a captured refresh token in a system holding children's locations is not
  /// something to resolve gently.
  bool get endsSession =>
      this == authSessionRevoked ||
      this == authRefreshReuseDetected ||
      this == authTokenInvalid ||
      this == authCredentialsInvalid;

  /// Whether repeating the identical request could plausibly succeed later.
  ///
  /// Drives the outbound queue's retry decision. Everything else is a refusal the server
  /// will repeat, so retrying only burns battery on a vehicle — the record is kept and
  /// surfaced for a human instead of retried forever
  /// (core/offline/sync_engine.dart).
  bool get isWorthRetrying =>
      this == dependencyUnavailable ||
      this == rateLimitExceeded ||
      this == internalError ||
      this == authTokenExpired;
}
