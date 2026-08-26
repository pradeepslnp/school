import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../guardians/bloc/student_guardians_bloc.dart';
import '../../guardians/bloc/student_guardians_event.dart';
import '../../guardians/bloc/student_guardians_state.dart';
import '../../guardians/widgets/add_guardian_form.dart';
import '../../guardians/widgets/guardian_tile.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../domain/student_models.dart';

/// A-11 — the record for one student: who they are, and the parents who may see and collect
/// them. Reached by tapping a row on the register (A-10).
///
/// Pickup and drop live here too, and are the next panel to land — this pass ships the student
/// header and the parents panel, which is what makes a parent's sign-in usable: enter a parent
/// with their phone here, and they can open the app.
///
/// The mutation affordances are gated by role exactly as the register is (`PERM-GUARDIAN-LINK`
/// is held by the same three roles as `PERM-STUDENT-EDIT`), so a `PRINCIPAL` or
/// `TRANSPORT_MANAGER` who may view is not offered an add button the server would refuse.
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

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit(context);

    return BlocListener<StudentGuardiansBloc, StudentGuardiansState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        // The add dialog is open until the create succeeds — close it here rather than from
        // inside the form, which has no reason to know it is in a dialog.
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
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
          ],
        ),
      ),
    );
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
                    'Admission ${student.admissionNo}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.sm),
                  Text(_statusLine(), style: theme.textTheme.bodyMedium),
                  if (student.dateOfBirth != null) ...[
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      'Date of birth ${_formatDate(student.dateOfBirth!)}',
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

  String _statusLine() {
    if (student.isWithdrawn) return 'Withdrawn';
    if (!student.transportEligible) return 'On roll · not using transport';
    return 'On roll · using transport';
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
              child: Text('Parents', style: theme.textTheme.titleLarge),
            ),
            if (canEdit)
              FilledButton.icon(
                key: const Key('student_detail_add_parent_button'),
                onPressed: onAddParent,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add parent'),
              ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        BlocBuilder<StudentGuardiansBloc, StudentGuardiansState>(
          builder: (context, state) {
            if (state.isLoading && state.guardians.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AdminSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(semanticsLabel: 'Loading parents'),
                ),
              );
            }

            if (state.error != null && state.guardians.isEmpty) {
              return Text(
                'That could not be loaded right now. Try again.',
                style: theme.textTheme.bodyMedium?.copyWith(color: context.status.critical),
              );
            }

            if (state.guardians.isEmpty) {
              return Text(
                'No parents yet. Add one so they can see this child and be reached — and so '
                'the child can be assigned to a bus.',
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
                      'No parent here can collect the child yet — turn on "Can collect the '
                      'child" for at least one before assigning a bus.',
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
