import 'package:equatable/equatable.dart';

/// An authenticated console session.
///
/// Lives in `core/` rather than under `features/login/`: the session is not the sign-in
/// screen's private result. [RestClient] needs its access token on every request, the shell
/// needs to know who is signed in, and the router keys the whole console off its lifecycle.
/// Filing it under one feature would have every other part of the app importing that feature
/// to reach it.
class Session extends Equatable {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  /// JWT, RS256, fifteen minutes (AUTHENTICATION_API.md §Token Reference).
  ///
  /// **Carries no permissions or roles** (BR-IAM-004). They are resolved server-side on
  /// every request, which is what makes "revoke this person's access to children's data"
  /// take effect on the next request rather than the next token.
  final String accessToken;

  /// Opaque, server-stored, and single-use. Rotated on every refresh; presenting a consumed
  /// one revokes the entire token family and raises a security alert (BR-IAM-009).
  final String refreshToken;

  final DateTime expiresAt;
  final AuthenticatedUser user;

  /// Whether the access token should be replaced before the next call.
  ///
  /// Refreshes early rather than at expiry. An access token that expires mid-request means
  /// a 401 on an operator's action — during an incident, that is a wasted round trip on the
  /// screen where delay costs most.
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
    this.scopes = const [],
  });

  final String id;
  final String firstName;
  final String lastName;

  /// Drives console language and locale formatting (ADR-0007).
  ///
  /// Held on the user rather than the browser: an operator signing in from a shared
  /// workstation should not inherit the last person's language.
  final String preferredLocale;

  /// Server-supplied roles — **UI affordances only** (BR-IAM-001, BR-IAM-004).
  ///
  /// What these must never do is decide whether an action is *allowed*. The server
  /// re-resolves permissions on every request; a client that gates on this list is enforcing
  /// a rule the person it is gating can edit in their own browser. Hiding a control the
  /// server would refuse is a courtesy, not a control (ENGINEERING_PRINCIPLES.md §6).
  final List<String> roles;

  /// The organisations or schools this user's roles apply to.
  ///
  /// Also affordance-only. Scope is re-checked per object server-side, because holding a
  /// permission never implies access to a specific record
  /// (SECURITY_ARCHITECTURE.md §Authorisation).
  final List<AuthScope> scopes;

  /// The school this user's role is scoped to, or null if they hold no single-school scope
  /// (an `ORGANIZATION`- or `PLATFORM`-scoped role, e.g. `ORG_ADMIN` or `SUPER_ADMIN`, which
  /// oversees more than one school and so has no one id to default to).
  ///
  /// Used only to pre-fill and auto-load a school-scoped screen (Drivers, Vehicles, Routes)
  /// for the common case — a `TRANSPORT_MANAGER` or `SCHOOL_ADMIN` signing in already knows
  /// which school they run, and shouldn't have to paste its id to see their own roster. Still
  /// affordance only, like every other use of [scopes] here: the server re-scopes every
  /// request regardless of what this returns.
  String? get schoolScopeId {
    for (final scope in scopes) {
      if (scope.level == 'SCHOOL') return scope.refId;
    }
    return null;
  }

  /// The organization this user's role is scoped to, or null if they hold no single-organization
  /// scope (a `PLATFORM`-scoped role, e.g. `SUPER_ADMIN`, which oversees more than one
  /// organization and so has no one id to default to — or a `SCHOOL`-scoped role, which has
  /// [schoolScopeId] instead and never needs this one).
  ///
  /// Used only to skip the organization step of `SchoolPickerField` for an `ORG_ADMIN`, who
  /// already knows which organization they run and should go straight to picking one of its
  /// schools. Affordance only, like [schoolScopeId]: the server re-scopes every request
  /// regardless of what this returns.
  ///
  /// Compared against `'ORG'`, not `'ORGANIZATION'` — matching the wire value `user_scopes`
  /// and `IssuedSession.ScopeView` actually send (`UserScope.Level.ORG.name()`, per
  /// `MOD-02-identity.md`'s `scope_level` column). This getter originally checked
  /// `'ORGANIZATION'`, a guess made before the backend's scope plumbing existed; it was
  /// never exercised end-to-end until now, which is how the mismatch stayed hidden.
  String? get organizationScopeId {
    for (final scope in scopes) {
      if (scope.level == 'ORG') return scope.refId;
    }
    return null;
  }

  String get displayName => '$firstName $lastName'.trim();

  /// Initials for the account control. Falls back to a single letter rather than an empty
  /// string, so the control never renders as a blank circle.
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) return '?';
    if (last.isEmpty) return first.substring(0, 1).toUpperCase();
    if (first.isEmpty) return last.substring(0, 1).toUpperCase();
    return '${first.substring(0, 1)}${last.substring(0, 1)}'.toUpperCase();
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'preferredLocale': preferredLocale,
        'roles': roles,
        'scopes': [for (final scope in scopes) scope.toJson()],
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
      scopes: (json['scopes'] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(AuthScope.fromJson)
          .whereType<AuthScope>()
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props =>
      [id, firstName, lastName, preferredLocale, roles, scopes];
}

/// One `{ level, refId }` pair from the login response — the reach of a role.
class AuthScope extends Equatable {
  const AuthScope({required this.level, required this.refId});

  /// `PLATFORM`, `ORGANIZATION`, or `SCHOOL`. Kept as the wire string rather than parsed
  /// into an enum: the console does not branch on it, and an unrecognised level from a newer
  /// server must survive the round trip intact rather than collapse to a default.
  final String level;

  final String refId;

  Map<String, Object?> toJson() => {'level': level, 'refId': refId};

  static AuthScope? fromJson(Map<String, Object?> json) {
    final level = json['level'];
    final refId = json['refId'];
    if (level is! String || refId is! String) return null;
    return AuthScope(level: level, refId: refId);
  }

  @override
  List<Object?> get props => [level, refId];
}
