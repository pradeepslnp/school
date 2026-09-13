import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/rest_client.dart';
import '../core/session/session_manager.dart';
import '../core/session/shared_preferences_session_store.dart';
import '../features/audit/data_provider/audit_data_provider.dart';
import '../features/audit/repository/audit_repository.dart';
import '../features/custody_restrictions/data_provider/custody_restriction_data_provider.dart';
import '../features/custody_restrictions/repository/custody_restriction_repository.dart';
import '../features/auth_recovery/data_provider/auth_recovery_data_provider.dart';
import '../features/auth_recovery/repository/auth_recovery_repository.dart';
import '../features/guardians/data_provider/guardian_data_provider.dart';
import '../features/guardians/repository/guardian_repository.dart';
import '../features/login/data_provider/login_data_provider.dart';
import '../features/login/repository/login_repository.dart';
import '../features/organizations/data_provider/organization_data_provider.dart';
import '../features/organizations/repository/organization_onboarding_repository.dart';
import '../features/platform_health/data_provider/platform_health_data_provider.dart';
import '../features/platform_health/repository/platform_health_repository.dart';
import '../features/routes/data_provider/duty_assignment_data_provider.dart';
import '../features/routes/data_provider/route_data_provider.dart';
import '../features/routes/repository/duty_assignment_repository.dart';
import '../features/routes/repository/route_repository.dart';
import '../features/route_assignments/data_provider/route_assignment_data_provider.dart';
import '../features/route_assignments/repository/route_assignment_repository.dart';
import '../features/routes/repository/stop_repository.dart';
import '../features/staff/data_provider/staff_data_provider.dart';
import '../features/students/data_provider/student_data_provider.dart';
import '../features/students/import/data_provider/student_import_data_provider.dart';
import '../features/students/import/repository/student_import_repository.dart';
import '../features/students/repository/student_repository.dart';
import '../features/staff/repository/staff_repository.dart';
import '../features/users/data_provider/user_data_provider.dart';
import '../features/users/repository/user_repository.dart';
import '../features/vehicles/data_provider/vehicle_data_provider.dart';
import '../features/vehicles/repository/vehicle_repository.dart';
import 'acting_organization.dart';
import 'app_config.dart';
import 'locale_controller.dart';
import 'workspace_context.dart';

/// The console's composition root.
///
/// Everything is constructed once, here, and injected downwards
/// (ENGINEERING_PRINCIPLES.md §5). There is no service locator and no mutable static state:
/// a widget or a bloc that could reach a singleton could not be tested without it, and the
/// pieces this class wires together — an HTTP client and a session store — are precisely the
/// ones a test must be able to replace.
class AppDependencies {
  AppDependencies._({
    required this.config,
    required this.restClient,
    required this.sessionManager,
    required this.loginRepository,
    required this.organizationOnboardingRepository,
    required this.staffRepository,
    required this.studentRepository,
    required this.studentImportRepository,
    required this.vehicleRepository,
    required this.routeRepository,
    required this.stopRepository,
    required this.routeAssignmentRepository,
    required this.dutyAssignmentRepository,
    required this.userRepository,
    required this.platformHealthRepository,
    required this.guardianRepository,
    required this.custodyRestrictionRepository,
    required this.auditRepository,
    required this.authRecoveryRepository,
    required this.workspaceContext,
    required this.actingOrganization,
    required this.localeController,
  });

  final AppConfig config;
  final RestClient restClient;
  final SessionManager sessionManager;
  final LoginRepository loginRepository;

  /// Organization/school transport (TEN-001, TEN-002). Backs onboarding and the Organizations
  /// list (A-40, `SUPER_ADMIN` only) as well as School (A-41, `SCHOOL_ADMIN` only) — two
  /// screens with disjoint audiences sharing one repository because both are, underneath,
  /// reads and writes on organizations and schools; see `ConsoleDestinations`.
  final OrganizationOnboardingRepository organizationOnboardingRepository;

  /// Transport staff registration (A-23, STF-001) — reached by roles holding
  /// `PERM-STAFF-MANAGE` (PERMISSION_MATRIX.md); see `ConsoleDestinations`.
  final StaffRepository staffRepository;

  /// The student register (A-10, STU-001) — reached by roles holding `PERM-STUDENT-VIEW`,
  /// though only `SUPER_ADMIN`/`ORG_ADMIN`/`SCHOOL_ADMIN` are offered the write affordances;
  /// see `StudentListScreen`.
  final StudentRepository studentRepository;

  /// Bulk student import (A-12, STU-002) — reached from the register by roles holding
  /// `PERM-STUDENT-IMPORT` (`SUPER_ADMIN` / `ORG_ADMIN` / `SCHOOL_ADMIN`).
  final StudentImportRepository studentImportRepository;

  /// Vehicle registration (A-20, FLT-001) — reached by roles holding `PERM-VEHICLE-MANAGE`
  /// (PERMISSION_MATRIX.md); see `ConsoleDestinations`.
  final VehicleRepository vehicleRepository;

  /// Route creation (A-30, RTE-001) — reached by roles holding `PERM-ROUTE-MANAGE`
  /// (PERMISSION_MATRIX.md); see `ConsoleDestinations`.
  final RouteRepository routeRepository;

  /// A route's stops (RTE-001, A-31 interim) — reached from the Routes screen; written with
  /// `PERM-ROUTE-MANAGE`.
  final StopRepository stopRepository;

  /// A student's pickup/drop assignments (RTE-003, A-11) — reached from the student detail
  /// screen; written with `PERM-ROUTE-ASSIGN-STUDENT`.
  final RouteAssignmentRepository routeAssignmentRepository;

  /// Duty (crew) assignment (STF-004) — reached from the Routes screen by roles holding
  /// `PERM-DUTY-ASSIGN` (PERMISSION_MATRIX.md); see `RouteCrewDialog`.
  final DutyAssignmentRepository dutyAssignmentRepository;

  /// Administrative-user management (IAM-005, IAM-008, screen A-43) — reached by roles
  /// holding `PERM-USER-VIEW`; see `ConsoleDestinations`.
  final UserRepository userRepository;

  /// Platform health (screen A-62) — `SUPER_ADMIN` only (`PERM-PLATFORM-HEALTH-VIEW`); see
  /// `ConsoleDestinations`.
  final PlatformHealthRepository platformHealthRepository;

  /// A student's guardians (parents) — links, and the sign-in each parent gets from
  /// their phone (GRD-001, GRD-002, screen A-11). Reached from the student detail
  /// screen by roles holding `PERM-GUARDIAN-LINK`.
  final GuardianRepository guardianRepository;

  /// Custody restrictions on a student (GRD-006, screen A-14) — a safety-critical override,
  /// reached from the student record by roles holding `PERM-CUSTODY-RESTRICTION-MANAGE`. Never
  /// exposed to any guardian-facing surface (BR-GRD-008 🔴).
  final CustodyRestrictionRepository custodyRestrictionRepository;

  /// The audit trail and override register (AUD-002, AUD-003, screens A-54/A-55) — read-only,
  /// reached by roles holding `PERM-AUDIT-VIEW`; see `ConsoleDestinations`.
  final AuditRepository auditRepository;

  /// Account activation and password recovery (IAM-009, IAM-010, ADR-0012) — the public
  /// accept-invitation, forgot-password, and reset-password pages. No session required.
  final AuthRecoveryRepository authRecoveryRepository;

  /// The school id remembered across the Drivers, Vehicles, and Routes screens for this
  /// session — see `WorkspaceContext`.
  final WorkspaceContext workspaceContext;

  /// The organization a platform operator is acting in, or null in the ordinary case — see
  /// [ActingOrganization].
  final ActingOrganization actingOrganization;

  /// The operator's chosen console language, persisted across sessions (ADR-0013). See
  /// `LocaleController`.
  final LocaleController localeController;

  /// Builds everything and restores any existing session.
  ///
  /// Called once from `main`, before the first frame, so the console never renders sign-in
  /// to someone who is already authenticated.
  static Future<AppDependencies> bootstrap(AppConfig config) async {
    // The session manager and the HTTP client each need the other: every request needs a
    // token, and obtaining a token is a request. The knot is tied with a `late` binding and
    // closures rather than by giving either one a setter — the closures are only invoked
    // once a request is in flight, by which point both objects exist, and neither type ends
    // up with a mutable field that could be repointed later.
    late final SessionManager sessionManager;

    final actingOrganization = ActingOrganization();

    final restClient = RestClient(
      baseUrl: config.apiBaseUrl,
      clientType: LoginDataProvider.clientType,
      accessTokenProvider: () => sessionManager.accessToken(),
      // Sends X-Guardian-Organization while a platform operator is working inside another
      // organization (ADR-0016). The server authorizes and audits it; this only reports where
      // the console currently is.
      actingOrganizationProvider: () => actingOrganization.value,
      onUnauthorized: () => sessionManager.handleUnauthorized(),
    );

    final loginRepository = LoginRepository(
      dataProvider: LoginDataProvider(client: restClient),
    );

    final organizationOnboardingRepository = OrganizationOnboardingRepository(
      dataProvider: OrganizationDataProvider(client: restClient),
    );

    final staffRepository = StaffRepository(
      dataProvider: StaffDataProvider(client: restClient),
    );

    final studentRepository = StudentRepository(
      dataProvider: StudentDataProvider(client: restClient),
    );

    final studentImportRepository = StudentImportRepository(
      dataProvider: StudentImportDataProvider(client: restClient),
    );

    final vehicleRepository = VehicleRepository(
      dataProvider: VehicleDataProvider(client: restClient),
    );

    final routeRepository = RouteRepository(
      dataProvider: RouteDataProvider(client: restClient),
    );

    final stopRepository = StopRepository(
      dataProvider: RouteDataProvider(client: restClient),
    );

    final routeAssignmentRepository = RouteAssignmentRepository(
      dataProvider: RouteAssignmentDataProvider(client: restClient),
    );

    final dutyAssignmentRepository = DutyAssignmentRepository(
      dataProvider: DutyAssignmentDataProvider(client: restClient),
    );

    final userRepository = UserRepository(
      dataProvider: UserDataProvider(client: restClient),
    );

    final platformHealthRepository = PlatformHealthRepository(
      dataProvider: PlatformHealthDataProvider(client: restClient),
    );

    final guardianRepository = GuardianRepository(
      dataProvider: GuardianDataProvider(client: restClient),
    );

    final custodyRestrictionRepository = CustodyRestrictionRepository(
      dataProvider: CustodyRestrictionDataProvider(client: restClient),
    );

    final auditRepository = AuditRepository(
      dataProvider: AuditDataProvider(client: restClient),
    );

    final authRecoveryRepository = AuthRecoveryRepository(
      dataProvider: AuthRecoveryDataProvider(client: restClient),
    );

    final workspaceContext = WorkspaceContext();

    // Read once at bootstrap, before the first frame — the same reasoning as
    // `SessionManager.restore()` below: the console's starting language must be known before
    // anything renders, not applied a frame later as a visible relanguaging.
    final localeController = await LocaleController.bootstrap(
      platformLocale: PlatformDispatcher.instance.locale,
    );

    sessionManager = SessionManager(
      // Durable across reloads, and re-validated against the server on every restore —
      // ADR-0015, which records why this overrides CODING_STANDARDS_FLUTTER.md §Security and
      // what would replace it. `InMemorySessionStore` remains the safe default for any
      // client that has not accepted that trade.
      store: SharedPreferencesSessionStore(
        preferences: await SharedPreferences.getInstance(),
      ),
      refresher: loginRepository,
      // An elevation belongs to the operator who entered it, never to the next person at a
      // shared workstation (ADR-0016). Cleared however the session ends — sign-out, a
      // revoked token, or a refresh that failed.
      onSessionEnded: () async => actingOrganization.leave(),
    );

    final dependencies = AppDependencies._(
      config: config,
      restClient: restClient,
      sessionManager: sessionManager,
      loginRepository: loginRepository,
      organizationOnboardingRepository: organizationOnboardingRepository,
      staffRepository: staffRepository,
      studentRepository: studentRepository,
      studentImportRepository: studentImportRepository,
      vehicleRepository: vehicleRepository,
      routeRepository: routeRepository,
      stopRepository: stopRepository,
      routeAssignmentRepository: routeAssignmentRepository,
      dutyAssignmentRepository: dutyAssignmentRepository,
      userRepository: userRepository,
      platformHealthRepository: platformHealthRepository,
      guardianRepository: guardianRepository,
      custodyRestrictionRepository: custodyRestrictionRepository,
      auditRepository: auditRepository,
      authRecoveryRepository: authRecoveryRepository,
      workspaceContext: workspaceContext,
      actingOrganization: actingOrganization,
      localeController: localeController,
    );

    await sessionManager.restore();

    return dependencies;
  }

  /// Signs out.
  ///
  /// Revokes server-side first so the session is dead the moment the operator asks, then
  /// clears locally **whatever the server said**. A sign-out that leaves a usable token in
  /// the tab because the API was unreachable is not a sign-out — and on a shared workstation
  /// that is the next person operating under someone else's name in the audit trail
  /// (BR-AUD-001).
  Future<void> signOut() async {
    await loginRepository.revokeSessionOnServer();
    await sessionManager.signOut();
  }

  Future<void> dispose() async {
    await sessionManager.dispose();
    restClient.close();
    localeController.dispose();
  }
}

/// Makes [AppDependencies] available to the widget tree.
///
/// An `InheritedWidget` rather than a global: a test pumps a subtree under its own scope with
/// fakes, and a widget that forgot to be given dependencies fails loudly at build time
/// instead of quietly picking up production ones.
class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DependencyScope>();
    assert(scope != null, 'No DependencyScope above this widget');
    return scope!.dependencies;
  }

  /// A one-time read that does not subscribe to rebuilds.
  ///
  /// [of] cannot be called from `initState` — establishing an `InheritedWidget` dependency
  /// before the first build completes is a framework error. Screens that need a dependency
  /// once at entry (to seed a field from [WorkspaceContext], say) use this instead; anything
  /// that must react to a later change still needs [of] from `build`.
  static AppDependencies readOnce(BuildContext context) {
    final widget = context.findAncestorWidgetOfExactType<DependencyScope>();
    assert(widget != null, 'No DependencyScope above this widget');
    return widget!.dependencies;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
