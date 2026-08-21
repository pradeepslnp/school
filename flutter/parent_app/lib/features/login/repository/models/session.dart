import 'package:equatable/equatable.dart';

/// An authenticated guardian session.
///
/// `roles` and `scopes` from the API are deliberately **not** modelled here. They exist
/// only to shape UI affordances, and holding them in the session invites treating them as
/// authorisation — which they are not. Every request re-resolves permissions server-side
/// (ADR-0006, BR-IAM-004).
class Session extends Equatable {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;

  /// Opaque and single-use. Rotated on every refresh; presenting a consumed token
  /// invalidates the whole session family (BR-IAM-009).
  final String refreshToken;

  final DateTime expiresAt;
  final AuthenticatedUser user;

  /// Whether the access token should be refreshed before the next call.
  ///
  /// Refreshes early rather than at expiry: a token that expires mid-request produces a
  /// failure the parent sees as the app being broken.
  bool isExpiringWithin(Duration window, {DateTime? now}) =>
      (now ?? DateTime.now().toUtc()).add(window).isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, user];
}

class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.preferredLocale,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// Drives app language. Held on the user, not the device: a shared phone and a parent
  /// who reads a different language than the handset default are both ordinary here.
  final String preferredLocale;

  String get displayName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, firstName, lastName, preferredLocale];
}
