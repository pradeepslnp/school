import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../school_scope/widgets/school_picker_field.dart';
import '../bloc/student_list_bloc.dart';
import '../bloc/student_list_event.dart';
import '../bloc/student_list_state.dart';
import '../domain/student_models.dart';
import '../widgets/student_error_text.dart';
import '../widgets/student_form.dart';

/// A-10 — Student register: the school's roll, and the entry point to a student's record
/// (STU-001, STU-004). Reached by roles holding `PERM-STUDENT-VIEW`; the mutation affordances
/// are hidden from roles that only hold the view permission — see [_canEdit].
///
/// Holds the "which school" text and the search query the operator is looking at — everything
/// else is [StudentListState]. Matching `StaffListScreen`: no decisions here, only rendering and
/// reporting what the operator did.
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key, this.initialSchoolId});

  /// The signed-in operator's own school, when they hold a school-scoped role. Pre-fills the
  /// field and loads immediately, so a `SCHOOL_ADMIN` sees their own register without pasting
  /// an id first.
  final String? initialSchoolId;

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  /// Roles that may change the roll. `PERM-STUDENT-EDIT` and `PERM-STUDENT-CREATE` are held by
  /// these three only (PERMISSION_MATRIX.md), whereas `PERM-STUDENT-VIEW` also reaches
  /// `PRINCIPAL` and `TRANSPORT_MANAGER` — who should see the register and not be offered
  /// buttons the server will refuse.
  static const _editingRoles = {'SUPER_ADMIN', 'ORG_ADMIN', 'SCHOOL_ADMIN'};

  /// The school currently loaded — from [widget.initialSchoolId], from `WorkspaceContext`, or
  /// from `SchoolPickerField` (shown only when neither of those is set; see [build]).
  String? _selectedSchoolId;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final remembered = DependencyScope.readOnce(context).workspaceContext.value;
    final schoolId = widget.initialSchoolId ?? remembered;
    _selectedSchoolId = schoolId;
    if (schoolId != null && schoolId.isNotEmpty) {
      context.read<StudentListBloc>().add(StudentListRequested(schoolId: schoolId));
    }
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Fetches the next page as the operator nears the end of the loaded rows.
  ///
  /// Deliberately ahead of the very bottom: a register is read by scrolling, and waiting for
  /// the last pixel would show a spinner every time. The bloc guards against the repeat calls
  /// a scroll listener inevitably makes.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining > 400) return;

    final schoolId = _selectedSchoolId;
    if (schoolId == null || schoolId.isEmpty) return;
    context.read<StudentListBloc>().add(StudentListNextPageRequested(schoolId: schoolId));
  }

  bool _canEdit(BuildContext context) {
    final user = DependencyScope.of(context).sessionManager.currentUser;
    final roles = user?.roles ?? const <String>[];
    return roles.any(_editingRoles.contains);
  }

  void _load(BuildContext context, String schoolId) {
    if (schoolId.isEmpty) return;
    setState(() => _selectedSchoolId = schoolId);
    DependencyScope.of(context).workspaceContext.value = schoolId;
    context.read<StudentListBloc>().add(StudentListRequested(schoolId: schoolId));
  }

  Future<void> _openForm(BuildContext context, {Student? existing}) async {
    final bloc = context.read<StudentListBloc>();
    final schoolId = _selectedSchoolId ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<StudentListBloc, StudentListState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StudentForm(
                      existing: existing,
                      schoolId: schoolId,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String admissionNo,
                        required String firstName,
                        required String lastName,
                        String? dateOfBirth,
                        required bool transportEligible,
                      }) {
                        if (existing == null) {
                          bloc.add(StudentCreated(
                            schoolId: schoolId,
                            admissionNo: admissionNo,
                            firstName: firstName,
                            lastName: lastName,
                            dateOfBirth: dateOfBirth,
                            transportEligible: transportEligible,
                          ));
                        } else {
                          bloc.add(StudentUpdated(
                            studentId: existing.id,
                            firstName: firstName,
                            lastName: lastName,
                            dateOfBirth: dateOfBirth,
                            transportEligible: transportEligible,
                          ));
                        }
                      },
                    ),
                    if (state.error != null)
                      StudentErrorText(
                        code: state.error!,
                        messageKey: state.errorMessageKey,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Withdrawal is confirmed; ordinary edits are not.
  ///
  /// ACCESSIBILITY.md is explicit that confirmation is for destructive or safety-critical
  /// actions and nothing else — a dialog on every save trains people to dismiss dialogs. This
  /// one qualifies: it takes a child off the roll, and other people's screens depend on that.
  Future<void> _confirmWithdraw(BuildContext context, Student student) async {
    final bloc = context.read<StudentListBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw student?'),
        content: Text(
          '${student.displayName} (${student.admissionNo}) will be taken off the roll and '
          'removed from transport.\n\n'
          'Their record is kept — safety records reference it — and can still be read.',
        ),
        actions: [
          TextButton(
            key: const Key('student_withdraw_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('student_withdraw_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(StudentWithdrawn(studentId: student.id));
    }
  }

  /// Instant, client-side, over whatever rows are already loaded — no server round trip.
  ///
  /// `GET /students` takes no search parameter yet, so this filters the loaded pages only. On a
  /// register that pages, that is a real limitation: a name further down the roll than the
  /// operator has scrolled will not match. Surfaced in the empty-state copy rather than hidden.
  List<Student> _filtered(List<Student> students) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students
        .where((student) =>
            student.displayName.toLowerCase().contains(query) ||
            student.admissionNo.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEdit = _canEdit(context);

    return BlocListener<StudentListBloc, StudentListState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        // The form dialog stays open until the write succeeds — closed here rather than from
        // inside StudentForm, which has no reason to know it is inside a dialog.
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
                  child: Text('Students', style: theme.textTheme.headlineSmall),
                ),
                if (canEdit)
                  FilledButton.icon(
                    key: const Key('student_list_add_button'),
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Enrol student'),
                  ),
              ],
            ),
            if (widget.initialSchoolId == null) ...[
              const SizedBox(height: AdminSpacing.lg),
              SchoolPickerField(
                onSchoolSelected: (schoolId) => _load(context, schoolId),
              ),
            ],
            const SizedBox(height: AdminSpacing.md),
            TextField(
              key: const Key('student_list_search_field'),
              controller: _search,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Filter loaded students by name or admission number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('student_list_search_clear_button'),
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                        onPressed: () => setState(() {
                          _search.clear();
                          _searchQuery = '';
                        }),
                      ),
                border: const OutlineInputBorder(),
                constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            Expanded(
              child: BlocBuilder<StudentListBloc, StudentListState>(
                builder: (context, state) => _body(context, state, theme, canEdit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    StudentListState state,
    ThemeData theme,
    bool canEdit,
  ) {
    if (state.isLoading && state.students.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading register'),
      );
    }

    if (state.error != null && state.students.isEmpty) {
      return Center(
        child: StudentErrorText(code: state.error!, messageKey: state.errorMessageKey),
      );
    }

    if (state.students.isEmpty) {
      return Center(
        child: Text(
          'No register loaded. Pick a school above, or enrol the first student.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final students = _filtered(state.students);

    if (students.isEmpty) {
      return Center(
        child: Text(
          state.hasMore
              ? 'No loaded student matches that. Scroll to load more of the register, then '
                  'search again.'
              : 'No student matches that.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null)
          StudentErrorText(code: state.error!, messageKey: state.errorMessageKey),
        Expanded(
          // ListView.builder, not a Column in a scroll view: the register is thousands of rows
          // and only the visible ones should be built (CODING_STANDARDS_FLUTTER.md).
          child: ListView.builder(
            controller: _scroll,
            itemCount: students.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= students.length) {
                return const Padding(
                  padding: EdgeInsets.all(AdminSpacing.lg),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading more students',
                    ),
                  ),
                );
              }
              return _StudentRow(
                student: students[index],
                canEdit: canEdit,
                onEdit: () => _openForm(context, existing: students[index]),
                onWithdraw: () => _confirmWithdraw(context, students[index]),
              );
            },
          ),
        ),
        if (!state.hasMore && _searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AdminSpacing.sm),
            child: Text(
              '${state.students.length} students',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// One row of the register.
class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.canEdit,
    required this.onEdit,
    required this.onWithdraw,
  });

  final Student student;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      key: Key('student_list_row_${student.id}'),
      leading: CircleAvatar(
        child: Icon(student.hasPhoto ? Icons.face : Icons.person_outline),
      ),
      title: Text(student.displayName),
      subtitle: Text('${student.admissionNo} · ${_statusLabel()}'),
      trailing: canEdit
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('student_list_edit_${student.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit ${student.displayName}',
                  onPressed: onEdit,
                ),
                if (!student.isWithdrawn)
                  IconButton(
                    key: Key('student_list_withdraw_${student.id}'),
                    icon: const Icon(Icons.person_remove_outlined),
                    tooltip: 'Withdraw ${student.displayName}',
                    onPressed: onWithdraw,
                  ),
              ],
            )
          : null,
      // The status is spelled out in the subtitle as well as implied by the icon — colour and
      // shape are never the only signal (DESIGN_SYSTEM.md).
      textColor: student.isWithdrawn ? theme.colorScheme.onSurfaceVariant : null,
    );
  }

  String _statusLabel() {
    if (student.isWithdrawn) return 'Withdrawn';
    if (!student.transportEligible) return 'On roll · not using transport';
    return 'On roll · transport';
  }
}
