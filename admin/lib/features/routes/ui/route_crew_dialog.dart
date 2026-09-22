import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../staff/domain/staff_models.dart';
import '../bloc/duty_assignment_bloc.dart';
import '../bloc/duty_assignment_event.dart';
import '../bloc/duty_assignment_state.dart';
import '../domain/duty_assignment_models.dart';
import '../domain/route_models.dart';
import '../widgets/assign_duty_form.dart';
import '../widgets/replace_duty_form.dart';

/// The standing crew for one route (STF-004), reached by tapping a row on the Routes screen
/// (A-30). A dialog rather than a second console location — matching `OrganizationListRoute`'s
/// own reasoning for creating/viewing an organization in place: this is a detail of one route,
/// not a destination of its own.
class RouteCrewDialog extends StatelessWidget {
  const RouteCrewDialog({super.key, required this.route});

  final CreatedRoute route;

  @override
  Widget build(BuildContext context) {
    final dependencies = DependencyScope.of(context);

    return BlocProvider<DutyAssignmentBloc>(
      create: (_) => DutyAssignmentBloc(repository: dependencies.dutyAssignmentRepository)
        ..add(DutyAssignmentListRequested(routeId: route.id)),
      child: _RouteCrewView(route: route),
    );
  }
}

class _RouteCrewView extends StatefulWidget {
  const _RouteCrewView({required this.route});

  /// `PERM-DUTY-ASSIGN`'s holders (PERMISSION_MATRIX.md). Narrower than the roles that open
  /// Routes: a `SCHOOL_ADMIN` sees the crew (`PERM-ROUTE-VIEW`) but is not offered *Assign crew*,
  /// which the server would refuse with `403`.
  static const _dutyAssigningRoles = {'SUPER_ADMIN', 'ORG_ADMIN', 'TRANSPORT_MANAGER'};

  final CreatedRoute route;

  @override
  State<_RouteCrewView> createState() => _RouteCrewViewState();
}

class _RouteCrewViewState extends State<_RouteCrewView> {
  /// True while an assign or replace form is open over this dialog. The listener below closes
  /// that form when its write lands — without this it would close the crew dialog itself after a
  /// removal, which has no form open.
  bool _formOpen = false;

  CreatedRoute get route => widget.route;

  /// This route's own school's roster, fetched when a form needs it rather than on open.
  Future<List<CreatedStaff>> _roster(BuildContext context) async {
    final dependencies = DependencyScope.of(context);
    final staffResult = await dependencies.staffRepository.listStaff(schoolId: route.schoolId);
    return switch (staffResult) {
      Success<List<CreatedStaff>>(:final value) => value,
      Failure() => const <CreatedStaff>[],
    };
  }

  /// Puts a different person on an existing duty (STF-004) — the standing roster, with a reason.
  Future<void> _openReplaceForm(BuildContext context, CreatedDutyAssignment assignment) async {
    final bloc = context.read<DutyAssignmentBloc>();
    final staffOptions = await _roster(context);
    if (!context.mounted) return;

    setState(() => _formOpen = true);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<DutyAssignmentBloc, DutyAssignmentState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReplaceDutyForm(
                      current: assignment,
                      staffOptions: staffOptions,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({required String staffId, required String reason}) {
                        bloc.add(DutyReplaced(
                          routeId: route.id,
                          assignmentId: assignment.id,
                          staffId: staffId,
                          reason: reason,
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
    if (mounted) setState(() => _formOpen = false);
  }

  /// Takes a crew member off the route, leaving the slot empty until someone is assigned.
  Future<void> _confirmRemove(BuildContext context, CreatedDutyAssignment assignment) async {
    final bloc = context.read<DutyAssignmentBloc>();
    final role = assignment.role == 'DRIVER'
        ? context.l10n.staffTypeDriver
        : context.l10n.staffTypeAttendant;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.routeCrewRemoveTitle),
        content: Text(
          context.l10n.routeCrewRemoveBody(assignment.displayName, role, route.name),
        ),
        actions: [
          TextButton(
            key: const Key('route_crew_remove_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancelButton),
          ),
          FilledButton(
            key: const Key('route_crew_remove_confirm_button'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.routeCrewRemoveButton),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(DutyRemoved(routeId: route.id, assignmentId: assignment.id));
    }
  }

  Future<void> _openAssignForm(BuildContext context) async {
    final bloc = context.read<DutyAssignmentBloc>();

    // The driver/attendant dropdown below needs this route's own school's roster — fetched
    // here rather than inside the dialog, so the dialog itself never needs its own loading state.
    final staffOptions = await _roster(context);

    if (!context.mounted) return;

    setState(() => _formOpen = true);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<DutyAssignmentBloc, DutyAssignmentState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AssignDutyForm(
                      staffOptions: staffOptions,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({required staffId, required role, direction}) {
                        bloc.add(DutyAssigned(
                          routeId: route.id,
                          staffId: staffId,
                          role: role,
                          direction: direction,
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
    final roles = DependencyScope.of(context).sessionManager.currentUser?.roles ?? const [];
    final canAssign = roles.any(_RouteCrewView._dutyAssigningRoles.contains);

    return BlocListener<DutyAssignmentBloc, DutyAssignmentState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        // Only the form's own route, never this dialog (see [_formOpen]).
        if (_formOpen && Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(route.name, style: theme.textTheme.titleLarge),
                    ),
                    if (canAssign)
                      FilledButton.icon(
                        key: const Key('route_crew_assign_button'),
                        onPressed: () => _openAssignForm(context),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(context.l10n.routeCrewAssignButton),
                      ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.md),
                Expanded(
                  child: BlocBuilder<DutyAssignmentBloc, DutyAssignmentState>(
                    builder: (context, state) {
                      if (state.isLoading && state.assignments.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: context.l10n.routeCrewLoadingLabel,
                          ),
                        );
                      }

                      if (state.assignments.isEmpty) {
                        return Center(
                          child: Text(
                            context.l10n.routeCrewEmptyState,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return _CrewList(
                        assignments: state.assignments,
                        onReplace:
                            canAssign ? (duty) => _openReplaceForm(context, duty) : null,
                        onRemove: canAssign ? (duty) => _confirmRemove(context, duty) : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AdminSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('route_crew_close_button'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.commonCloseButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrewList extends StatelessWidget {
  const _CrewList({required this.assignments, this.onReplace, this.onRemove});

  final List<CreatedDutyAssignment> assignments;

  /// Null for a caller without `PERM-DUTY-ASSIGN` — they read the crew, they do not change it.
  final ValueChanged<CreatedDutyAssignment>? onReplace;
  final ValueChanged<CreatedDutyAssignment>? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('route_crew_list'),
      itemCount: assignments.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final assignment = assignments[index];
        return ListTile(
          key: Key('route_crew_row_${assignment.id}'),
          leading: Icon(
            assignment.role == 'DRIVER' ? Icons.airline_seat_recline_normal : Icons.badge,
          ),
          // The person first: a roster that reads "Driver · Both directions" answers nothing
          // for someone replacing an absent driver.
          title: Text(
            assignment.displayName.isEmpty
                ? context.l10n.routeCrewUnfilledSlot
                : assignment.displayName,
          ),
          subtitle: Text(
            '${_roleLabel(context, assignment.role)} · '
            '${_directionLabel(context, assignment.direction)}',
          ),
          trailing: onReplace == null && onRemove == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onReplace != null)
                      IconButton(
                        key: Key('route_crew_replace_${assignment.id}'),
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: context.l10n.routeCrewReplaceTooltip,
                        onPressed: () => onReplace!(assignment),
                      ),
                    if (onRemove != null)
                      IconButton(
                        key: Key('route_crew_remove_${assignment.id}'),
                        icon: const Icon(Icons.person_remove_outlined),
                        tooltip: context.l10n.routeCrewRemoveTooltip,
                        onPressed: () => onRemove!(assignment),
                      ),
                  ],
                ),
        );
      },
    );
  }

  String _roleLabel(BuildContext context, String role) {
    final l10n = context.l10n;
    return switch (role) {
      'DRIVER' => l10n.staffTypeDriver,
      'ATTENDANT' => l10n.staffTypeAttendant,
      _ => role,
    };
  }

  String _directionLabel(BuildContext context, String? direction) {
    final l10n = context.l10n;
    return switch (direction) {
      'PICKUP' => l10n.studentDetailDirectionPickup,
      'DROP' => l10n.studentDetailDirectionDrop,
      _ => l10n.routeCrewBothDirectionsLabel,
    };
  }
}
