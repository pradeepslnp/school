import 'package:equatable/equatable.dart';

/// An authenticated driver or attendant session.
///
/// Lives in `core/` rather than under `features/login/` — a deliberate difference from the
/// parent app. Here the session is not the login screen's private result: [RestClient] needs
/// its access token on every request, the sync engine needs to know when it has ended, and
/// the local-store wipe hangs off its lifecycle. Filing it under one feature would have every
/// other part of the app importing that feature to get at it.
class Session extends Equatable {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;

  /// Opaque, server-stored, and single-use. Rotated on every refresh; presenting a consumed
  /// one revokes the entire token family and raises a security alert (BR-IAM-009).
  final String refreshToken;

  final DateTime expiresAt;
  final AuthenticatedUser user;

  /// Whether the access token should be replaced before the next call.
  ///
  /// Refreshes early rather than at expiry. The access token lives fifteen minutes
  /// (ADR-0006), and one that expires mid-request on a bus becomes a failed boarding
  /// submission that has to be retried from the queue.
  bool isExpiringWithin(Duration window, {required DateTime now}) =>
      now.add(window).isAfter(expiresAt);

  Map<String, Object?> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'user': user.toJson(),
      };

  static Session? fromJson(Map<String, Object?> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final expiresAt = json['expiresAt'];
    final user = json['user'];

    if (accessToken is! String ||
        refreshToken is! String ||
        expiresAt is! String ||
        user is! Map<String, Object?>) {
      return null;
    }

    final parsedExpiry = DateTime.tryParse(expiresAt);
    final parsedUser = AuthenticatedUser.fromJson(user);
    if (parsedExpiry == null || parsedUser == null) return null;

    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: parsedExpiry.toUtc(),
      user: parsedUser,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, user];
}

/// The signed-in member of staff.
class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.preferredLocale,
    this.roles = const [],
  });

  final String id;
  final String firstName;
  final String lastName;

  /// Drives app language. Held on the user, not the device: driver handsets are shared, and
  /// the person holding it may not read the language the last shift set.
  final String preferredLocale;

  /// Server-supplied roles — **UI affordances only** (BR-IAM-001, BR-IAM-004).
  ///
  /// This app genuinely needs them: a driver and an attendant see different screens, and
  /// where an attendant is assigned, boarding belongs to them (BR-STAFF-005). What the roles
  /// must never do is decide whether an action is *allowed* — the server re-resolves
  /// permissions on every request, and a client that gates on this list is enforcing a rule
  /// an attacker can edit.
  final List<String> roles;

  bool get isAttendant => roles.contains('ATTENDANT');
  bool get isDriver => roles.contains('DRIVER');

  String get displayName => '$firstName $lastName'.trim();

  Map<String, Object?> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'preferredLocale': preferredLocale,
        'roles': roles,
      };

  static AuthenticatedUser? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String) return null;

    return AuthenticatedUser(
      id: id,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      preferredLocale: json['preferredLocale'] as String? ?? 'en',
      roles: (json['roles'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, preferredLocale, roles];
}
