import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
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
                      label: const Text('Assign crew'),
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpacing.md),
                Expanded(
                  child: BlocBuilder<DutyAssignmentBloc, DutyAssignmentState>(
                    builder: (context, state) {
                      if (state.isLoading && state.assignments.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(semanticsLabel: 'Loading crew'),
                        );
                      }

                      if (state.assignments.isEmpty) {
                        return Center(
                          child: Text(
                            'No crew assigned yet.',
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
                    child: const Text('Close'),
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
          title: Text(assignment.role),
          subtitle: Text(assignment.direction ?? 'Both directions'),
        );
      },
    );
  }
}
