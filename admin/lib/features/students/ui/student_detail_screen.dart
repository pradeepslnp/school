import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../guardians/bloc/student_guardians_bloc.dart';
import '../../guardians/bloc/student_guardians_event.dart';
import '../../guardians/bloc/student_guardians_state.dart';
import '../../custody_restrictions/widgets/custody_restriction_panel.dart';
import '../../guardians/domain/guardian_models.dart';
import '../../guardians/widgets/add_guardian_form.dart';
import '../../guardians/widgets/edit_guardian_form.dart';
import '../../guardians/widgets/guardian_tile.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../route_assignments/bloc/student_assignments_bloc.dart';
import '../../route_assignments/bloc/student_assignments_event.dart';
import '../../route_assignments/bloc/student_assignments_state.dart';
import '../../route_assignments/domain/route_assignment_models.dart';
import '../../route_assignments/widgets/assign_route_form.dart';
import '../../routes/domain/route_models.dart';
import '../../routes/domain/stop_models.dart';
import '../../student_transport/bloc/student_transport_bloc.dart';
import '../../student_transport/bloc/student_transport_event.dart';
import '../../student_transport/bloc/student_transport_state.dart';
import '../../student_transport/domain/student_transport_models.dart';
import '../../student_transport/widgets/assigned_bus_line.dart';
import '../domain/student_models.dart';
import '../widgets/student_error_text.dart';

/// A-11 — the record for one student: who they are, the parents who may see and collect them,
/// and their pickup and drop. Reached by tapping a row on the register (A-10).
///
/// The mutation affordances are gated by role exactly as the register is (`PERM-GUARDIAN-LINK`
/// and `PERM-ROUTE-ASSIGN-STUDENT` are held by the same roles as `PERM-STUDENT-EDIT`), so a
/// `PRINCIPAL` or `TRANSPORT_MANAGER` who may view is not offered buttons the server would refuse.
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({
    super.key,
    required this.student,
    this.showCustodyPanel = false,
  });

  static const _editingRoles = {'SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN'};

  final Student student;

  /// Whether to show the custody-restrictions panel (A-14) — set by the route only when the
  /// operator holds `PERM-CUSTODY-RESTRICTION-MANAGE`, so the bloc for it exists in scope.
  final bool showCustodyPanel;

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

  /// Corrects a parent's details (GRD-001). A changed phone moves their sign-in (BR-IAM-014);
  /// the form says so before saving.
  Future<void> _openEditParent(BuildContext context, StudentGuardian guardian) async {
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
                    EditGuardianForm(
                      guardian: guardian,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String firstName,
                        required String lastName,
                        required String phone,
                        String? email,
                      }) {
                        bloc.add(GuardianUpdated(
                          studentId: student.id,
                          guardianId: guardian.guardianId,
                          firstName: firstName,
                          lastName: lastName,
                          phone: phone,
                          email: email,
                        ));
                      },
                    ),
                    if (state.error != null)
                      StudentErrorText(code: state.error!, messageKey: state.errorMessageKey),
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
        // A changed or removed pickup/drop changes the bus and crew too — re-read them, so the
        // panel never shows the previous route's bus under the new route.
        BlocListener<StudentAssignmentsBloc, StudentAssignmentsState>(
          listenWhen: (previous, current) =>
              previous.isSubmitting && !current.isSubmitting && current.error == null,
          listener: (context, state) => context
              .read<StudentTransportBloc>()
              .add(StudentTransportRequested(studentId: student.id)),
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
              onEditParent: (guardian) => _openEditParent(context, guardian),
            ),
            const SizedBox(height: AdminSpacing.xl),
            _PickupDropPanel(
              canEdit: canEdit,
              onSet: (direction) => _openAssign(context, direction),
            ),
            if (showCustodyPanel) ...[
              const SizedBox(height: AdminSpacing.xl),
              CustodyRestrictionPanel(studentId: student.id),
            ],
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
  const _ParentsPanel({
    required this.canEdit,
    required this.onAddParent,
    required this.onEditParent,
  });

  /// `PERM-GUARDIAN-LINK` and `PERM-GUARDIAN-MANAGE` are held by the same three roles, so one
  /// flag gates both adding a parent and correcting one.
  final bool canEdit;
  final VoidCallback onAddParent;
  final ValueChanged<StudentGuardian> onEditParent;

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
                  GuardianTile(
                    guardian: guardian,
                    onEdit: canEdit ? () => onEditParent(guardian) : null,
                  ),
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
        const SizedBox(height: AdminSpacing.xs),
        // The bus and crew below are the plan, not a location — said once, up front.
        Text(
          context.l10n.studentTransportCaption,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AdminSpacing.md),
        BlocBuilder<StudentAssignmentsBloc, StudentAssignmentsState>(
          builder: (context, state) {
            final transport = context.watch<StudentTransportBloc>().state;
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
                  transportLeg: _legFor(transport, 'PICKUP'),
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
                  transportLeg: _legFor(transport, 'DROP'),
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
                if (transport.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AdminSpacing.sm),
                    child: Text(
                      context.l10n.studentTransportLoadError,
                      style: theme.textTheme.bodySmall?.copyWith(color: context.status.warning),
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

/// The loaded leg for [direction], or null before the first load or when none is assigned.
TransportLeg? _legFor(StudentTransportState transport, String direction) {
  for (final leg in transport.transport?.legs ?? const <TransportLeg>[]) {
    if (leg.direction == direction) return leg;
  }
  return null;
}

class _DirectionRow extends StatelessWidget {
  const _DirectionRow({
    required this.label,
    required this.direction,
    required this.assignment,
    required this.transportLeg,
    required this.canEdit,
    required this.isBusy,
    required this.onSet,
    required this.onRemove,
  });

  final String label;
  final String direction;
  final RouteAssignment? assignment;

  /// The bus and crew for this direction, once loaded (STU-009). Shown only while an assignment
  /// is set, so a stale leg never appears under "Not set".
  final TransportLeg? transportLeg;
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
                if (set && transportLeg != null) AssignedBusLine(leg: transportLeg!),
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
