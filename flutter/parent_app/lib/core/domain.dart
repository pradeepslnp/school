import 'package:flutter/foundation.dart';

/// Shared domain types for the parent app.
///
/// This is a local replacement for the missing `guardian_core` package used by
/// the original monorepo. It keeps the app compile-ready while preserving the
/// existing business rules and error vocabulary.

/// Shared result type for domain operations.
sealed class Result<T> {
  const Result();
}

/// Successful operation outcome.
final class Success<T> extends Result<T> {
  const Success(this.value) : super();

  final T value;
}

/// Failed operation outcome.
final class Failure<T> extends Result<T> {
  const Failure(
    this.code, {
    this.messageKey,
    this.businessRule,
  }) : super();

  final ErrorCode code;
  final String? messageKey;
  final bool? businessRule;
}

/// Canonical error codes used by login and other core flows.
enum ErrorCode {
  authCredentialsInvalid,
  authOtpExpired,
  authOtpAlreadyUsed,
  authAccountLocked,
  rateLimitExceeded,
  dependencyUnavailable,
  validationFailed,
  /// The caller holds the permission but the resource is outside their scope — for this app,
  /// a student they are not linked to (BR-IAM-005). Deliberately indistinguishable from
  /// "no such student": telling them apart would confirm a particular child exists.
  authScopeDenied,
  absenceTripAlreadyStarted,
  guardianNotAuthorisedToNominate,
  pickupPersonOutsideValidity,
  trackingNotAvailableOutsideTrip,
  /// Lacks `can_authorise_handover` on this specific child (BR-GRD-006) — same underlying
  /// right as [guardianNotAuthorisedToNominate], distinct code because it guards requesting
  /// a release code (P-12) rather than nominating a pickup person (P-07).
  guardianNotAuthorisedForHandover,
  internalError,
  unknown,
  ;

  static ErrorCode fromWire(String? wire) {
    return switch (wire) {
      'AUTH_CREDENTIALS_INVALID' => ErrorCode.authCredentialsInvalid,
      'AUTH_OTP_EXPIRED' => ErrorCode.authOtpExpired,
      'AUTH_OTP_ALREADY_USED' => ErrorCode.authOtpAlreadyUsed,
      'AUTH_ACCOUNT_LOCKED' => ErrorCode.authAccountLocked,
      'RATE_LIMIT_EXCEEDED' => ErrorCode.rateLimitExceeded,
      'DEPENDENCY_UNAVAILABLE' => ErrorCode.dependencyUnavailable,
      'VALIDATION_FAILED' => ErrorCode.validationFailed,
      'AUTH_SCOPE_DENIED' => ErrorCode.authScopeDenied,
      'ABSENCE_TRIP_ALREADY_STARTED' => ErrorCode.absenceTripAlreadyStarted,
      'GUARDIAN_NOT_AUTHORISED_TO_NOMINATE' =>
        ErrorCode.guardianNotAuthorisedToNominate,
      'PICKUP_PERSON_OUTSIDE_VALIDITY' => ErrorCode.pickupPersonOutsideValidity,
      'TRACKING_NOT_AVAILABLE_OUTSIDE_TRIP' =>
        ErrorCode.trackingNotAvailableOutsideTrip,
      'GUARDIAN_NOT_AUTHORISED_FOR_HANDOVER' =>
        ErrorCode.guardianNotAuthorisedForHandover,
      'INTERNAL_ERROR' => ErrorCode.internalError,
      _ => ErrorCode.unknown,
    };
  }
}

/// Where a child is in their journey right now.
///
/// This is the answer the parent app exists to give (docs/05-ui/PARENT_APP.md). Shared
/// across every feature that shows a child's status — the dashboard, child detail, the live
/// map, and journey history — so it lives here rather than in one feature's model
/// (docs/06-development/PROJECT_STRUCTURE.md: "shared models used by several features live
/// in guardian_core").
enum JourneyState {
  /// No trip today, or between trips.
  atRest,

  /// Trip scheduled but not yet started.
  scheduled,

  /// Bus running, child not yet boarded.
  awaitingBoarding,

  /// On the vehicle.
  onBoard,

  /// Arrived at school.
  arrivedAtSchool,

  /// Handed over to an authorised adult.
  handedOver,

  /// Did not board at their stop (BR-SAFE-002).
  noShow,

  /// Guardian declared the child absent.
  absent,

  /// Boarded with no record of getting off (BR-SAFE-001). The one state that dominates
  /// the screen.
  unaccounted,

  /// The server reported a state this build does not recognise.
  ///
  /// New enum values ship additively within `v1` (docs/04-api/API_STANDARDS.md), so an app
  /// that has not been updated will meet one. It is shown as explicitly unknown rather than
  /// mapped onto the nearest familiar state: guessing "At school" for an unrecognised value
  /// would let this app hide exactly the state it exists to surface.
  unknown,
}

extension JourneyStateSeverity on JourneyState {
  /// Whether this state warrants a full-width critical banner rather than a card.
  ///
  /// Deliberately narrow. If more states creep in here the banner stops meaning
  /// "act now", which is the only thing it is for.
  bool get isCritical => this == JourneyState.unaccounted;

  bool get isWarning => this == JourneyState.noShow;
}

/// Which half of the day a journey leg belongs to.
///
/// Shared by child detail (today's two legs) and journey history (every past day's two
/// legs), so it lives here rather than in either feature's model.
enum JourneyDirection { morning, afternoon }

/// One child, named for a picker — nothing more.
///
/// Journey history, declare absence, and pickup persons are all per-child screens that a
/// guardian with more than one child needs to choose among (PARENT_APP.md P-05/P-06/P-07).
/// The dashboard already holds the full [ChildStatus] for each child; this is the minimal
/// slice those three features need, so they depend on a name and an id rather than on the
/// dashboard's model.
@immutable
class ChildOption {
  const ChildOption({required this.studentId, required this.displayName});

  final String studentId;
  final String displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildOption &&
          other.studentId == studentId &&
          other.displayName == displayName);

  @override
  int get hashCode => Object.hash(studentId, displayName);
}

/// A school-local timestamp.
///
/// This is intentionally very small: the app only needs to present a time and
/// compare freshness, and the full timezone handling is outside the current
/// scaffold.
@immutable
class SchoolTime {
  const SchoolTime(this.value, {this.timezoneId = 'UTC'});

  factory SchoolTime.fromUtc(
    DateTime utc, {
    required String timezoneId,
    required Duration offset,
  }) {
    return SchoolTime(utc.add(offset), timezoneId: timezoneId);
  }

  final DateTime value;

  /// The school's zone, carried alongside the value rather than discarded.
  ///
  /// A time without its zone is a time the UI cannot label, and BR-CFG-006 requires the
  /// label — a parent travelling abroad reading "07:42" with no zone has been told
  /// something false, not something incomplete.
  final String timezoneId;

  /// A display string in school-local 24-hour time.
  String get timeOfDay {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolTime &&
          other.value == value &&
          other.timezoneId == timezoneId;

  @override
  int get hashCode => Object.hash(value, timezoneId);
}
