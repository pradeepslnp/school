import 'dart:async';

import 'package:flutter/material.dart';

import '../core/session/session.dart';
import '../core/session/session_manager.dart';
import '../features/login/ui/login_route.dart';
import '../features/organizations/ui/organization_list_route.dart';
import '../features/platform_health/ui/platform_health_route.dart';
import '../features/roles/ui/role_reference_screen.dart';
import '../features/routes/ui/route_list_route.dart';
import '../features/school_settings/ui/school_settings_route.dart';
import '../features/shell/console_destination.dart';
import '../features/shell/ui/console_shell.dart';
import '../features/staff/ui/staff_list_route.dart';
import '../features/students/ui/student_list_route.dart';
import '../features/users/ui/user_list_route.dart';
import '../features/vehicles/ui/vehicle_list_route.dart';
import 'theme.dart';

/// Where the console is.
///
/// A sealed type rather than a string, so every place that reasons about location handles
/// both cases. The browser URL is derived from it, not the other way round.
sealed class AdminRoutePath {
  const AdminRoutePath();

  /// The browser address for this location.
  String get location;
}

/// The unauthenticated entry point.
final class SignInPath extends AdminRoutePath {
  const SignInPath();

  static const String path = '/sign-in';

  @override
  String get location => path;
}

/// Anywhere inside the authenticated console.
final class ConsolePath extends AdminRoutePath {
  const ConsolePath([this.location = '/']);

  @override
  final String location;
}

/// Translates between the browser address bar and [AdminRoutePath].
///
/// Real URLs matter more here than in the mobile apps: an operator handling an incident
/// shares a link to an alert with a colleague, and reloads a tab that has been open all day.
class ConsoleRouteInformationParser
    extends RouteInformationParser<AdminRoutePath> {
  const ConsoleRouteInformationParser();

  @override
  Future<AdminRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final path = routeInformation.uri.path;
    if (path == SignInPath.path) return const SignInPath();
    return ConsolePath(path.isEmpty ? '/' : path);
  }

  @override
  RouteInformation? restoreRouteInformation(AdminRoutePath configuration) =>
      RouteInformation(uri: Uri.parse(configuration.location));
}

/// Decides what the console shows, from one input: the session.
///
/// **The auth status is the router's source of truth**, not a redirect rule bolted onto a
/// route table. Signing in, being revoked mid-incident (BR-IAM-007), and a refresh token
/// failing all arrive the same way — as a status change — so there is no path by which a
/// screen holding child data stays mounted after the session that authorised it has ended.
///
/// Navigator 2.0 with no routing package. The console's routes are few and entirely derived
/// from auth status plus a location string; a router package would add a dependency and a
/// second place for redirect rules to live.
class ConsoleRouterDelegate extends RouterDelegate<AdminRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AdminRoutePath> {
  ConsoleRouterDelegate({
    required SessionManager sessionManager,
    required Future<void> Function() onSignOut,
  })  : _sessionManager = sessionManager,
        _onSignOut = onSignOut {
    _subscription = _sessionManager.statusStream.listen(_onStatusChanged);
  }

  final SessionManager _sessionManager;

  /// Runs the full sign-out — server revocation and local clear. Supplied by the composition
  /// root, because the router should not know that signing out involves a network call.
  final Future<void> Function() _onSignOut;

  late final StreamSubscription<AuthStatus> _subscription;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Where inside the console the operator is. Retained across a sign-out so a session that
  /// ended on its own returns them to the screen they were on, once they sign in again.
  String _consoleLocation = '/';

  bool _isSigningOut = false;

  @override
  AdminRoutePath get currentConfiguration => switch (_sessionManager.status) {
        AuthSignedIn() => ConsolePath(_consoleLocation),
        // Reported as sign-in while the stored session is still being read. The splash below
        // is on screen for a frame or two; publishing a console URL for it would put an
        // address in history that the operator was never actually at.
        AuthUnknown() || AuthSignedOut() => const SignInPath(),
      };

  @override
  Future<void> setNewRoutePath(AdminRoutePath configuration) async {
    if (configuration is ConsolePath) {
      _consoleLocation = configuration.location;
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _sessionManager.status;

    return Navigator(
      key: navigatorKey,
      pages: [
        switch (status) {
          AuthUnknown() => const MaterialPage<void>(
              key: ValueKey('admin_boot'),
              child: _BootSplash(),
            ),
          AuthSignedOut(:final reason) => MaterialPage<void>(
              key: const ValueKey('admin_sign_in'),
              child: LoginRoute(signedOutReason: reason),
            ),
          AuthSignedIn(:final session) => MaterialPage<void>(
              key: const ValueKey('admin_console'),
              child: ConsoleShell(
                user: session.user,
                isSigningOut: _isSigningOut,
                onSignOut: _signOut,
                destinations: ConsoleDestinations.visibleTo(session.user.roles),
                selectedDestinationId: _selectedDestinationId(session),
                onDestinationSelected: _goTo,
                child: _screenFor(_consoleLocation, session),
              ),
            ),
        },
      ],
      onDidRemovePage: (page) {
        // Nothing to remove: the stack is one page deep and is derived entirely from auth
        // status. Declared because Navigator requires it, and left empty deliberately rather
        // than mutating a page list that is not the source of truth.
      },
    );
  }

  void _goTo(ConsoleDestination destination) {
    if (_consoleLocation == destination.location) return;
    _consoleLocation = destination.location;
    notifyListeners();
  }

  String? _selectedDestinationId(Session session) {
    for (final destination in ConsoleDestinations.visibleTo(session.user.roles)) {
      if (destination.location == _consoleLocation) return destination.id;
    }
    return null;
  }

  /// The screen for the current location, or null for [ConsoleShell] to fall back to
  /// [NoModulesNotice] — an unrecognised location, or one the signed-in user cannot reach
  /// (BR-IAM-001: never trust the client's own idea of what it may show).
  ///
  /// A `switch` on a location string rather than a route table: with one console location
  /// wired, a table would be one case dressed up as infrastructure. Revisit once a second
  /// location lands — creating and viewing an individual organization (A-40/A-41) still share
  /// this one location and are reached by an in-page `Navigator` push instead, see
  /// `OrganizationListRoute`.
  Widget? _screenFor(String location, Session session) {
    final visible = ConsoleDestinations.visibleTo(session.user.roles);

    if (location == '/organizations' &&
        visible.any((destination) => destination.location == '/organizations')) {
      return OrganizationListRoute(actorRoles: session.user.roles);
    }
    final schoolId = session.user.schoolScopeId;
    // Only reaches `SchoolPickerField` when `schoolId` is null (ORG_ADMIN or SUPER_ADMIN) —
    // see `StudentListRoute.initialOrganizationId`.
    final organizationId = session.user.organizationScopeId;

    if (location == '/students' &&
        visible.any((destination) => destination.location == '/students')) {
      return StudentListRoute(initialSchoolId: schoolId, initialOrganizationId: organizationId);
    }
    if (location == '/staff' &&
        visible.any((destination) => destination.location == '/staff')) {
      return StaffListRoute(initialSchoolId: schoolId, initialOrganizationId: organizationId);
    }
    if (location == '/vehicles' &&
        visible.any((destination) => destination.location == '/vehicles')) {
      return VehicleListRoute(initialSchoolId: schoolId, initialOrganizationId: organizationId);
    }
    if (location == '/routes' &&
        visible.any((destination) => destination.location == '/routes')) {
      return RouteListRoute(initialSchoolId: schoolId, initialOrganizationId: organizationId);
    }
    if (location == '/users' &&
        visible.any((destination) => destination.location == '/users')) {
      return UserListRoute(
        actorRoles: session.user.roles,
        initialOrganizationId: organizationId,
        initialSchoolId: schoolId,
      );
    }
    if (location == '/platform-health' &&
        visible.any((destination) => destination.location == '/platform-health')) {
      return const PlatformHealthRoute();
    }
    if (location == '/roles' &&
        visible.any((destination) => destination.location == '/roles')) {
      return const RoleReferenceScreen();
    }
    // Unlike the three destinations above, this one takes no pasted-id fallback: A-41 is
    // gated to `SCHOOL_ADMIN` alone (ConsoleDestinations), a role that always carries a
    // single-school scope, so a null `schoolScopeId` here means the token's scopes are
    // malformed rather than a role this screen should degrade gracefully for.
    if (location == '/school' &&
        visible.any((destination) => destination.location == '/school') &&
        schoolId != null) {
      return SchoolSettingsRoute(schoolId: schoolId);
    }
    return null;
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    _isSigningOut = true;
    notifyListeners();
    try {
      await _onSignOut();
    } finally {
      // Reset regardless of outcome. The session is gone either way — see
      // SessionManager.signOut — so leaving the control disabled would strand the operator
      // on a screen whose only action is already spent.
      _isSigningOut = false;
      notifyListeners();
    }
  }

  void _onStatusChanged(AuthStatus status) {
    // A session that ended deliberately should not restore the previous screen on the next
    // sign-in — that is usually a different person at a shared workstation.
    if (status is AuthSignedOut &&
        status.reason == SignOutReason.userRequested) {
      _consoleLocation = '/';
    }

    // `/` owns no screen of its own — see ConsoleDestinations' documentation on why there is
    // no A-01 yet. Land the operator on the first destination their roles actually grant
    // them, rather than showing NoModulesNotice to someone who does have somewhere to go.
    if (status is AuthSignedIn && _consoleLocation == '/') {
      final visible = ConsoleDestinations.visibleTo(status.session.user.roles);
      if (visible.isNotEmpty) {
        _consoleLocation = visible.first.location;
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// Shown while the stored session is being read.
///
/// A real state, not a formality: without it the console would render sign-in for a frame
/// before replacing it, which reads as a flicker and, to anyone who blinked, as a sign-out.
class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              excludeSemantics: true,
              child: Icon(
                Icons.shield_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Loading the console',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
