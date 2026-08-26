import 'package:flutter/material.dart';

/// One entry in the console's navigation.
///
/// A plain description, not a screen: the shell renders these and knows nothing about what
/// they lead to, so adding a module means adding a row to [ConsoleDestinations.all] rather
/// than editing the shell.
@immutable
class ConsoleDestination {
  const ConsoleDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.location,
    required this.availableOnNarrowLayout,
    this.requiredAnyRole,
  });

  /// Stable identifier — the screen ID from
  /// [`SCREEN_INVENTORY.md`](../../../guardian-docs/05-ui/SCREEN_INVENTORY.md), e.g. `A-01`.
  /// Used for keys and analytics, never displayed.
  final String id;

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// The URL this destination owns, e.g. `/alerts`.
  final String location;

  /// Whether this destination appears below 768 px.
  ///
  /// **Not a styling flag.** ADMIN_WEB.md §Responsive makes the narrow layout an explicit
  /// *incident-response subset* — dashboard, alerts, SOS, and live map only. Anil on a phone
  /// during an incident needs to act, not administer, and a bulk student import on a 5-inch
  /// screen is a mistake waiting to happen. Modelling it here makes the rule structural
  /// rather than something each new screen has to remember.
  final bool availableOnNarrowLayout;

  /// If set, this destination is shown only when the signed-in user holds at least one of
  /// these roles. Null means every signed-in operator sees it.
  ///
  /// **Affordance only, matching [AuthenticatedUser.roles]'s own documentation.** Hiding a
  /// link the server would refuse is a courtesy, not a control — `PERM-ORG-CREATE` is
  /// re-checked server-side on every request regardless of what this list says
  /// (BR-IAM-001, BR-IAM-004).
  final List<String>? requiredAnyRole;

  /// Whether [roles] satisfies [requiredAnyRole].
  bool visibleTo(List<String> roles) {
    final required = requiredAnyRole;
    if (required == null) return true;
    return required.any(roles.contains);
  }
}

/// The console's navigation, in order.
///
/// Each screen adds its own row here as it lands, in the order given by ADMIN_WEB.md — A-01
/// Operations Dashboard first for organization- and school-scoped staff, because that is
/// their landing screen and everything else is reached from it.
///
/// **A-40 is the one deliberate exception to that ordering.** A-01 is a per-organization
/// operations view; a `SUPER_ADMIN` platform operator does not belong to an organization
/// whose operations it would show (see `CreateOrganizationUseCase`'s documentation on what
/// distinguishes that role), so a dashboard built for school-level staff has nothing to
/// display for one. The organizations list (A-41) is what a platform operator actually needs
/// first — everything else here still waits for A-01 to exist. Adding one, and reopening
/// one already created, both live one `Navigator` push below this same location.
class ConsoleDestinations {
  const ConsoleDestinations._();

  static const List<ConsoleDestination> all = <ConsoleDestination>[
    ConsoleDestination(
      id: 'A-40',
      label: 'Organizations',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment,
      location: '/organizations',
      // A platform operator handling an onboarding call may well be doing it from a phone —
      // unlike the rest of A-40's future scope (editing, suspending), *creating* a new
      // tenant is a short, linear form and fits the narrow layout without redesign.
      availableOnNarrowLayout: true,
      requiredAnyRole: ['SUPER_ADMIN'],
    ),
    ConsoleDestination(
      id: 'A-41',
      label: 'School',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      location: '/school',
      // A settings screen, not an incident-response one — same reasoning as A-23 below.
      availableOnNarrowLayout: false,
      // `SCHOOL_ADMIN` only, deliberately narrower than `PERM-SCHOOL-EDIT`'s full holder list
      // (PERMISSION_MATRIX.md also grants it to `SUPER_ADMIN` and `ORG_ADMIN`) — those two
      // already reach the same school through Organizations (A-40) and would see a redundant
      // second nav entry for no benefit. A `SCHOOL_ADMIN` holds the permission but not
      // `PERM-ORG-VIEW`, so A-40 is not reachable for them; this is their only path in.
      requiredAnyRole: ['SCHOOL_ADMIN'],
    ),
    ConsoleDestination(
      id: 'A-10',
      label: 'Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      location: '/students',
      // A data-dense register, not an incident-response screen — ADMIN_WEB.md §Responsive
      // keeps the narrow layout to the dashboard/alerts/SOS/live-map subset. Reading a roll of
      // two thousand children on a phone during an incident is not what anyone needs.
      availableOnNarrowLayout: false,
      // PERM-STUDENT-VIEW's holders among console roles, verbatim from PERMISSION_MATRIX.md.
      // Wider than the write permissions on purpose: a PRINCIPAL and a TRANSPORT_MANAGER may
      // read the register, and StudentListScreen hides the affordances they cannot use rather
      // than hiding the screen itself.
      requiredAnyRole: [
        'SUPER_ADMIN',
        'ORG_ADMIN',
        'SCHOOL_ADMIN',
        'PRINCIPAL',
        'TRANSPORT_MANAGER',
      ],
    ),
    ConsoleDestination(
      id: 'A-23',
      label: 'Drivers',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      location: '/staff',
      // A data-entry screen (roster, contact details, employee codes), not an
      // incident-response one — ADMIN_WEB.md §Responsive keeps the narrow layout to the
      // dashboard/alerts/SOS/live-map subset, matching A-40's own reasoning in reverse.
      availableOnNarrowLayout: false,
      // PERM-STAFF-MANAGE's holders, verbatim from PERMISSION_MATRIX.md.
      requiredAnyRole: ['SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN', 'TRANSPORT_MANAGER'],
    ),
    ConsoleDestination(
      id: 'A-20',
      label: 'Vehicles',
      icon: Icons.directions_bus_outlined,
      selectedIcon: Icons.directions_bus,
      location: '/vehicles',
      availableOnNarrowLayout: false,
      // PERM-VEHICLE-MANAGE's holders, verbatim from PERMISSION_MATRIX.md.
      requiredAnyRole: ['SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN', 'TRANSPORT_MANAGER'],
    ),
    ConsoleDestination(
      id: 'A-30',
      label: 'Routes',
      icon: Icons.alt_route_outlined,
      selectedIcon: Icons.alt_route,
      location: '/routes',
      availableOnNarrowLayout: false,
      // PERM-ROUTE-MANAGE's holders, verbatim from PERMISSION_MATRIX.md.
      requiredAnyRole: ['SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN', 'TRANSPORT_MANAGER'],
    ),
    ConsoleDestination(
      id: 'A-43',
      label: 'Users',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
      location: '/users',
      // An administration screen, not an incident-response one — same reasoning as A-23.
      availableOnNarrowLayout: false,
      // PERM-USER-VIEW's holders among the roles that can reach this console at all —
      // PRINCIPAL and TRANSPORT_MANAGER hold no PERM-USER-* permission (PERMISSION_MATRIX.md)
      // and never see this destination.
      requiredAnyRole: ['SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN'],
    ),
    ConsoleDestination(
      id: 'A-44',
      label: 'Roles',
      icon: Icons.rule_folder_outlined,
      selectedIcon: Icons.rule_folder,
      location: '/roles',
      availableOnNarrowLayout: false,
      // A reference screen open to the same audience as Users (A-43) — deliberately not
      // gated to a PERM-ROLE-MANAGE-only audience, since today it only ever displays the
      // fixed system-role matrix rather than editing anything (see `RoleReferenceScreen`).
      requiredAnyRole: ['SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN'],
    ),
    ConsoleDestination(
      id: 'A-62',
      label: 'Platform health',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
      location: '/platform-health',
      // A platform-wide pulse check, not an incident-response tool for one organization's
      // bus — deliberately outside the narrow-layout subset (ADMIN_WEB.md §Responsive).
      availableOnNarrowLayout: false,
      // PERM-PLATFORM-HEALTH-VIEW's sole holder (PERMISSION_MATRIX.md, Platform Operations).
      requiredAnyRole: ['SUPER_ADMIN'],
    ),
  ];

  /// The subset shown below 768 px (ADMIN_WEB.md §Responsive).
  static List<ConsoleDestination> forNarrowLayout() => all
      .where((destination) => destination.availableOnNarrowLayout)
      .toList(growable: false);

  /// The subset visible to a user holding [roles] — affordance filtering only, see
  /// [ConsoleDestination.requiredAnyRole].
  static List<ConsoleDestination> visibleTo(List<String> roles) =>
      all.where((destination) => destination.visibleTo(roles)).toList(growable: false);
}
