import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../guardians/bloc/student_guardians_bloc.dart';
import '../../guardians/bloc/student_guardians_event.dart';
import '../../guardians/bloc/student_guardians_state.dart';
import '../../guardians/widgets/add_guardian_form.dart';
import '../../guardians/widgets/guardian_tile.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../route_assignments/bloc/student_assignments_bloc.dart';
import '../../route_assignments/bloc/student_assignments_event.dart';
import '../../route_assignments/bloc/student_assignments_state.dart';
import '../../route_assignments/domain/route_assignment_models.dart';
import '../../route_assignments/widgets/assign_route_form.dart';
import '../../routes/domain/route_models.dart';
import '../../routes/domain/stop_models.dart';
import '../domain/student_models.dart';

/// A-11 — the record for one student: who they are, the parents who may see and collect them,
/// and their pickup and drop. Reached by tapping a row on the register (A-10).
///
/// The mutation affordances are gated by role exactly as the register is (`PERM-GUARDIAN-LINK`
/// and `PERM-ROUTE-ASSIGN-STUDENT` are held by the same roles as `PERM-STUDENT-EDIT`), so a
/// `PRINCIPAL` or `TRANSPORT_MANAGER` who may view is not offered buttons the server would refuse.
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.student});

  static const _editingRoles = {'SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN'};

  final Student student;

  bool _canEdit(BuildContext context) {
    final user = DependencyScope.of(context).sessionManager.currentUser;
    final roles = user?.roles ?? const <String>[];
    return roles.any(_editingRoles.contains);
  }

  Future<void> _openAddParent(BuildContext context) async {
    final bloc = context.read<StudentGuardiansBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<StudentGuardiansBloc, StudentGuardiansState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AddGuardianForm(
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String firstName,
                        required String lastName,
                        required String phone,
                        String? email,
                        required String relationshipType,
                        required bool canView,
                        required bool canReceiveNotifications,
                        required bool canAuthoriseHandover,
                        required bool canDeclareAbsence,
                        required bool isPrimary,
                      }) {
                        bloc.add(GuardianAdded(
                          studentId: student.id,
                          firstName: firstName,
                          lastName: lastName,
                          phone: phone,
                          email: email,
                          relationshipType: relationshipType,
                          canView: canView,
                          canReceiveNotifications: canReceiveNotifications,
                          canAuthoriseHandover: canAuthoriseHandover,
                          canDeclareAbsence: canDeclareAbsence,
                          isPrimary: isPrimary,
                        ));
                      },
                    ),
                    if (state.error != null)
                      OnboardingErrorText(
                          code: state.error!, messageKey: state.errorMessageKey),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAssign(BuildContext context, String direction) async {
    final dependencies = DependencyScope.of(context);
    final bloc = context.read<StudentAssignmentsBloc>();

    // The route list is fetched once, here, so the dialog opens with its first dropdown ready.
    final routesResult =
        await dependencies.routeRepository.listRoutes(schoolId: student.schoolId);
    final routes = switch (routesResult) {
      Success<List<CreatedRoute>>(:final value) => value,
      Failure() => const <CreatedRoute>[],
    };

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<StudentAssignmentsBloc, StudentAssignmentsState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AssignRouteForm(
                      direction: direction,
                      routes: routes,
                      isSubmitting: state.isSubmitting,
                      loadStops: (routeId) async {
                        final result =
                            await dependencies.stopRepository.listStops(routeId: routeId);
                        return switch (result) {
                          Success<List<RouteStop>>(:final value) => value,
                          Failure() => throw Exception('stops load failed'),
                        };
                      },
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({required String routeId, required String stopId}) {
                        bloc.add(StudentAssignmentAdded(
                          studentId: student.id,
                          routeId: routeId,
                          stopId: stopId,
                          direction: direction,
                        ));
                      },
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: AdminSpacing.md),
                      Text(
                        _assignErrorText(context, state.error!),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.status.critical),
                      ),
                    ],
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
    final canEdit = _canEdit(context);

    return MultiBlocListener(
      listeners: [
        // Close the add-parent dialog when the create succeeds — from here, not from inside the
        // form, which has no reason to know it is in a dialog.
        BlocListener<StudentGuardiansBloc, StudentGuardiansState>(
          listenWhen: (previous, current) =>
              previous.isSubmitting && !current.isSubmitting && current.error == null,
          listener: (context, state) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        // Same for the assign dialog.
        BlocListener<StudentAssignmentsBloc, StudentAssignmentsState>(
          listenWhen: (previous, current) =>
              previous.isSubmitting && !current.isSubmitting && current.error == null,
          listener: (context, state) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(student.displayName)),
        body: ListView(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          children: [
            _StudentHeader(student: student),
            const SizedBox(height: AdminSpacing.xl),
            _ParentsPanel(
              canEdit: canEdit,
              onAddParent: () => _openAddParent(context),
            ),
            const SizedBox(height: AdminSpacing.xl),
            _PickupDropPanel(
              canEdit: canEdit,
              onSet: (direction) => _openAssign(context, direction),
            ),
          ],
        ),
      ),
    );
  }

  static String _assignErrorText(BuildContext context, ErrorCode code) {
    final l10n = context.l10n;
    return switch (code) {
      ErrorCode.studentHasNoActiveGuardian => l10n.studentAssignErrorNoActiveGuardian,
      ErrorCode.studentAlreadyAssignedForDirection => l10n.studentAssignErrorAlreadyAssigned,
      ErrorCode.dependencyUnavailable => l10n.studentAssignErrorApiUnreachable,
      _ => l10n.studentAssignErrorGeneric,
    };
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(student.hasPhoto ? Icons.face : Icons.person_outline),
            ),
            const SizedBox(width: AdminSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.displayName, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AdminSpacing.xs),
                  Text(
                    context.l10n.studentDetailAdmissionLine(student.admissionNo),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.sm),
                  Text(_statusLine(context), style: theme.textTheme.bodyMedium),
                  if (student.dateOfBirth != null) ...[
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      context.l10n.studentDetailDobLine(_formatDate(student.dateOfBirth!)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLine(BuildContext context) {
    if (student.isWithdrawn) return context.l10n.studentStatusWithdrawn;
    if (!student.transportEligible) return context.l10n.studentStatusOnRollNoTransport;
    return context.l10n.studentDetailStatusOnRollTransport;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _ParentsPanel extends StatelessWidget {
  const _ParentsPanel({required this.canEdit, required this.onAddParent});

  final bool canEdit;
  final VoidCallback onAddParent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(context.l10n.studentDetailParentsTitle, style: theme.textTheme.titleLarge),
            ),
            if (canEdit)
              FilledButton.icon(
                key: const Key('student_detail_add_parent_button'),
                onPressed: onAddParent,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(context.l10n.addGuardianFormTitle),
              ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        BlocBuilder<StudentGuardiansBloc, StudentGuardiansState>(
          builder: (context, state) {
            if (state.isLoading && state.guardians.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: context.l10n.studentDetailLoadingParentsLabel,
                  ),
                ),
              );
            }

            if (state.error != null && state.guardians.isEmpty) {
              return Text(
                context.l10n.errorGenericLoadRetry,
                style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
              );
            }

            if (state.guardians.isEmpty) {
              return Text(
                context.l10n.studentDetailNoParentsEmptyState,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!state.hasHandoverGuardian)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
                    child: Text(
                      context.l10n.studentDetailNoHandoverGuardianWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.status.warning,
                      ),
                    ),
                  ),
                for (final guardian in state.guardians)
                  GuardianTile(guardian: guardian),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PickupDropPanel extends StatelessWidget {
  const _PickupDropPanel({required this.canEdit, required this.onSet});

  final bool canEdit;
  final ValueChanged<String> onSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.studentDetailPickupDropTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.md),
        BlocBuilder<StudentAssignmentsBloc, StudentAssignmentsState>(
          builder: (context, state) {
            if (state.isLoading && state.assignments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: context.l10n.studentDetailLoadingAssignmentsLabel,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DirectionRow(
                  label: context.l10n.studentDetailDirectionPickup,
                  direction: 'PICKUP',
                  assignment: state.pickup,
                  canEdit: canEdit,
                  isBusy: state.isSubmitting,
                  onSet: () => onSet('PICKUP'),
                  onRemove: state.pickup == null
                      ? null
                      : () => context.read<StudentAssignmentsBloc>().add(
                            StudentAssignmentRemoved(
                              studentId: state.pickup!.studentId,
                              assignmentId: state.pickup!.id,
                            ),
                          ),
                ),
                const Divider(),
                _DirectionRow(
                  label: context.l10n.studentDetailDirectionDrop,
                  direction: 'DROP',
                  assignment: state.drop,
                  canEdit: canEdit,
                  isBusy: state.isSubmitting,
                  onSet: () => onSet('DROP'),
                  onRemove: state.drop == null
                      ? null
                      : () => context.read<StudentAssignmentsBloc>().add(
                            StudentAssignmentRemoved(
                              studentId: state.drop!.studentId,
                              assignmentId: state.drop!.id,
                            ),
                          ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AdminSpacing.sm),
                    child: Text(
                      StudentDetailScreen._assignErrorText(context, state.error!),
                      style: theme.textTheme.bodySmall?.copyWith(color: context.status.critical),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DirectionRow extends StatelessWidget {
  const _DirectionRow({
    required this.label,
    required this.direction,
    required this.assignment,
    required this.canEdit,
    required this.isBusy,
    required this.onSet,
    required this.onRemove,
  });

  final String label;
  final String direction;
  final RouteAssignment? assignment;
  final bool canEdit;
  final bool isBusy;
  final VoidCallback onSet;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = assignment != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
      child: Row(
        children: [
          Icon(
            direction == 'PICKUP' ? Icons.login : Icons.logout,
            color: set ? context.status.safe : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                Text(
                  set
                      ? context.l10n.studentDetailAssignmentSummary(
                          assignment!.routeName,
                          assignment!.routeCode,
                          assignment!.stopName,
                        )
                      : context.l10n.studentDetailAssignmentNotSet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: set ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit) ...[
            if (set && onRemove != null)
              IconButton(
                key: Key('assignment_remove_$direction'),
                icon: const Icon(Icons.delete_outline),
                tooltip: context.l10n.studentDetailRemoveAssignment(label),
                onPressed: isBusy ? null : onRemove,
              ),
            TextButton(
              key: Key('assignment_set_$direction'),
              onPressed: isBusy ? null : onSet,
              child: Text(set ? context.l10n.studentDetailChangeButton : context.l10n.studentDetailSetButton),
            ),
          ],
        ],
      ),
    );
  }
}
