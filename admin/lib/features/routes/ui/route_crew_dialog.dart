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

class _RouteCrewView extends StatelessWidget {
  const _RouteCrewView({required this.route});

  final CreatedRoute route;

  Future<void> _openAssignForm(BuildContext context) async {
    final bloc = context.read<DutyAssignmentBloc>();

    // The driver/attendant dropdown below needs this route's own school's roster — fetched
    // once, here, rather than inside the dialog, so the dialog itself never needs its own
    // loading state.
    final dependencies = DependencyScope.of(context);
    final staffResult = await dependencies.staffRepository.listStaff(schoolId: route.schoolId);
    final staffOptions = switch (staffResult) {
      Success<List<CreatedStaff>>(:final value) => value,
      Failure() => const <CreatedStaff>[],
    };

    if (!context.mounted) return;

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

    return BlocListener<DutyAssignmentBloc, DutyAssignmentState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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

                      return _CrewList(assignments: state.assignments);
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
  const _CrewList({required this.assignments});

  final List<CreatedDutyAssignment> assignments;

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
          title: Text(_roleLabel(context, assignment.role)),
          subtitle: Text(_directionLabel(context, assignment.direction)),
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
