import 'package:flutter/foundation.dart';

/// The organization a platform operator is currently acting in, or null for an ordinary
/// session acting in its own (ADR-0016).
///
/// ## What this is, and what it is not
///
/// It is **not** an authorization. Setting it only makes the console send
/// `X-Guardian-Organization` on subsequent requests; the server honours that header solely
/// for a token proving the `SUPER_ADMIN` role, refuses it outright for anyone else, and
/// audits every request that carries it (BR-TEN-004, BR-AUD-005). A value here therefore
/// grants nothing the signed-in token does not already carry — which is why it is safe for
/// this to live in ordinary client state rather than behind a guard of its own.
///
/// Held app-wide rather than per screen because it must apply to every request the console
/// makes while the operator is working inside that organization — a students list and the
/// route editor beside it have to agree about where they are.
///
/// Cleared on sign-out with the rest of the session's state, so the next operator on a shared
/// workstation never inherits someone else's elevation.
class ActingOrganization extends ValueNotifier<String?> {
  ActingOrganization() : super(null);

  /// Enters [organizationId], or leaves it null-safe when given null.
  ///
  /// Assigning the same value is a no-op in `ValueNotifier`, so re-selecting the current
  /// organization does not churn every listening screen.
  void enter(String? organizationId) => value = organizationId;

  /// Returns to the operator's own organization.
  void leave() => value = null;
}
