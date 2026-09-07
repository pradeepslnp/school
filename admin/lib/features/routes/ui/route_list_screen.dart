import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../school_scope/widgets/school_picker_field.dart';
import '../../vehicles/domain/vehicle_models.dart';
import '../bloc/route_list_bloc.dart';
import '../bloc/route_list_event.dart';
import '../bloc/route_list_state.dart';
import '../domain/route_models.dart';
import '../widgets/create_route_form.dart';
import 'route_crew_dialog.dart';
import 'route_stops_dialog.dart';

/// A-30 — Route list: the school's standing routes (RTE-001). Reached only by roles holding
/// `PERM-ROUTE-MANAGE` (PERMISSION_MATRIX.md) — see `ConsoleDestinations`.
///
/// Holds the "which school" text the operator is looking at — everything else is
/// [RouteListState]. Matching `VehicleListScreen`: no decisions here, only rendering and
/// reporting what the operator did.
class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key, this.initialSchoolId});

  /// The signed-in operator's own school (`AuthenticatedUser.schoolScopeId`), when they hold
  /// a school-scoped role. Pre-fills the field and loads immediately, so a `TRANSPORT_MANAGER`
  /// or `SCHOOL_ADMIN` sees their own routes without pasting an id first — an `ORG_ADMIN` or
  /// `SUPER_ADMIN`, who oversees more than one school, still has to enter one.
  final String? initialSchoolId;

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  /// The school currently loaded — from [widget.initialSchoolId], from `WorkspaceContext`, or
  /// from `SchoolPickerField` (shown only when neither of those is set; see [build]).
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    // The role's own school wins if known; otherwise fall back to whatever school the
    // operator last looked at on another of these screens (WorkspaceContext) — either way,
    // the point is to not make them pick it again.
    final remembered = DependencyScope.readOnce(context).workspaceContext.value;
    final schoolId = widget.initialSchoolId ?? remembered;
    _selectedSchoolId = schoolId;
    if (schoolId != null && schoolId.isNotEmpty) {
      context.read<RouteListBloc>().add(RouteListRequested(schoolId: schoolId));
    }
  }

  void _load(BuildContext context, String schoolId) {
    if (schoolId.isEmpty) return;
    setState(() => _selectedSchoolId = schoolId);
    DependencyScope.of(context).workspaceContext.value = schoolId;
    context.read<RouteListBloc>().add(RouteListRequested(schoolId: schoolId));
  }

  Future<void> _openAddForm(BuildContext context) async {
    final bloc = context.read<RouteListBloc>();
    final schoolId = _selectedSchoolId!;

    // The vehicle dropdown below needs this school's fleet — fetched once, here, rather than
    // inside the dialog, so the dialog itself never needs its own loading state.
    final dependencies = DependencyScope.of(context);
    final vehicleResult = await dependencies.vehicleRepository.listVehicles(schoolId: schoolId);
    final vehicles = switch (vehicleResult) {
      Success<List<CreatedVehicle>>(:final value) => value,
      Failure() => const <CreatedVehicle>[],
    };

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<RouteListBloc, RouteListState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CreateRouteForm(
                      schoolId: schoolId,
                      vehicles: vehicles,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String schoolId,
                        required String code,
                        required String name,
                        String? defaultVehicleId,
                      }) {
                        bloc.add(RouteCreated(
                          schoolId: schoolId,
                          code: code,
                          name: name,
                          defaultVehicleId: defaultVehicleId,
                        ));
                      },
                    ),
                    if (state.error != null)
                      OnboardingErrorText(code: state.error!, messageKey: state.errorMessageKey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<RouteListBloc, RouteListState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(context.l10n.consoleDestinationRoutes, style: theme.textTheme.headlineSmall),
                ),
_AddRouteButton(
                  enabled: _selectedSchoolId != null,
                  onPressed: () => _openAddForm(context),
                ),
              ],
            ),
            if (widget.initialSchoolId == null) ...[
              const SizedBox(height: AdminSpacing.lg),
              SchoolPickerField(
                onSchoolSelected: (schoolId) => _load(context, schoolId),
              ),
            ],
            const SizedBox(height: AdminSpacing.lg),
            Expanded(
              child: BlocBuilder<RouteListBloc, RouteListState>(
                builder: (context, state) {
                  if (state.isLoading && state.routes.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: context.l10n.routeListLoadingLabel,
                      ),
                    );
                  }

                  if (state.error != null && state.routes.isEmpty) {
                    final color = context.status.critical;
                    return Center(
                      child: Text(
                        context.l10n.errorGenericLoadRetry,
                        style: theme.textTheme.bodyMedium?.copyWith(color: color),
                      ),
                    );
                  }

                  if (state.routes.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.routeListEmptyState,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return _RouteTable(
                    routes: state.routes,
                    onOpenRoute: (route) => showDialog<void>(
                      context: context,
                      builder: (_) => RouteCrewDialog(route: route),
                    ),
                    onOpenStops: (route) => showDialog<void>(
                      context: context,
                      builder: (_) => RouteStopsDialog(route: route),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteTable extends StatelessWidget {
  const _RouteTable({
    required this.routes,
    required this.onOpenRoute,
    required this.onOpenStops,
  });

  final List<CreatedRoute> routes;
  final ValueChanged<CreatedRoute> onOpenRoute;
  final ValueChanged<CreatedRoute> onOpenStops;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        key: const Key('route_list_table'),
        itemCount: routes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final route = routes[index];

          return ListTile(
            key: Key('route_list_row_${route.id}'),
            minVerticalPadding: AdminSpacing.md,
            title: Text(route.name),
            subtitle: Text(route.code),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('route_list_stops_${route.id}'),
                  icon: const Icon(Icons.alt_route_outlined),
                  tooltip: context.l10n.routeStopsTooltip(route.name),
                  onPressed: () => onOpenStops(route),
                ),
                Tooltip(
                  message: route.hasVehicle
                      ? context.l10n.routeHasVehicleTooltip
                      : context.l10n.routeNoVehicleTooltip,
                  child: Icon(
                    route.hasVehicle ? Icons.directions_bus : Icons.directions_bus_outlined,
                    color: route.hasVehicle
                        ? context.status.safe
                        : context.status.warning,
                  ),
                ),
              ],
            ),
            onTap: () => onOpenRoute(route),
          );
        },
      ),
    );
  }
}

/// The "Add route" action — a plain [FilledButton] when a school is selected, or the same
/// button disabled with a [Tooltip] explaining why when it is not. Enrolling/adding with no
/// school chosen would submit against an empty schoolId — see `StudentListScreen._EnrolButton`
/// for the original reasoning, applied identically here.
class _AddRouteButton extends StatelessWidget {
  const _AddRouteButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      key: const Key('route_list_add_button'),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.add),
      label: Text(context.l10n.routeListAddButton),
    );

    if (enabled) return button;
    return Tooltip(message: context.l10n.pickSchoolFirstTooltip, child: button);
  }
}
