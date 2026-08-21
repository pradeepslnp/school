import 'package:flutter/widgets.dart';

import '../core/network/rest_client.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_store.dart';
import '../features/login/data_provider/login_data_provider.dart';
import '../features/login/repository/login_repository.dart';
import '../features/organizations/data_provider/organization_data_provider.dart';
import '../features/organizations/repository/organization_onboarding_repository.dart';
import '../features/routes/data_provider/duty_assignment_data_provider.dart';
import '../features/routes/data_provider/route_data_provider.dart';
import '../features/routes/repository/duty_assignment_repository.dart';
import '../features/routes/repository/route_repository.dart';
import '../features/staff/data_provider/staff_data_provider.dart';
import '../features/students/data_provider/student_data_provider.dart';
import '../features/students/repository/student_repository.dart';
import '../features/staff/repository/staff_repository.dart';
import '../features/vehicles/data_provider/vehicle_data_provider.dart';
import '../features/vehicles/repository/vehicle_repository.dart';
import 'app_config.dart';
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
    required this.vehicleRepository,
    required this.routeRepository,
    required this.dutyAssignmentRepository,
    required this.workspaceContext,
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

  /// Vehicle registration (A-20, FLT-001) — reached by roles holding `PERM-VEHICLE-MANAGE`
  /// (PERMISSION_MATRIX.md); see `ConsoleDestinations`.
  final VehicleRepository vehicleRepository;

  /// Route creation (A-30, RTE-001) — reached by roles holding `PERM-ROUTE-MANAGE`
  /// (PERMISSION_MATRIX.md); see `ConsoleDestinations`.
  final RouteRepository routeRepository;

  /// Duty (crew) assignment (STF-004) — reached from the Routes screen by roles holding
  /// `PERM-DUTY-ASSIGN` (PERMISSION_MATRIX.md); see `RouteCrewDialog`.
  final DutyAssignmentRepository dutyAssignmentRepository;

  /// The school id remembered across the Drivers, Vehicles, and Routes screens for this
  /// session — see `WorkspaceContext`.
  final WorkspaceContext workspaceContext;

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

    final restClient = RestClient(
      baseUrl: config.apiBaseUrl,
      clientType: LoginDataProvider.clientType,
      accessTokenProvider: () => sessionManager.accessToken(),
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

    final vehicleRepository = VehicleRepository(
      dataProvider: VehicleDataProvider(client: restClient),
    );

    final routeRepository = RouteRepository(
      dataProvider: RouteDataProvider(client: restClient),
    );

    final dutyAssignmentRepository = DutyAssignmentRepository(
      dataProvider: DutyAssignmentDataProvider(client: restClient),
    );

    final workspaceContext = WorkspaceContext();

    sessionManager = SessionManager(
      store: InMemorySessionStore(),
      refresher: loginRepository,
    );

    final dependencies = AppDependencies._(
      config: config,
      restClient: restClient,
      sessionManager: sessionManager,
      loginRepository: loginRepository,
      organizationOnboardingRepository: organizationOnboardingRepository,
      staffRepository: staffRepository,
      studentRepository: studentRepository,
      vehicleRepository: vehicleRepository,
      routeRepository: routeRepository,
      dutyAssignmentRepository: dutyAssignmentRepository,
      workspaceContext: workspaceContext,
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
