import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../school_scope/widgets/school_picker_field.dart';
import '../bloc/student_list_bloc.dart';
import '../bloc/student_list_event.dart';
import '../bloc/student_list_state.dart';
import '../domain/student_models.dart';
import '../import/ui/student_import_route.dart';
import '../widgets/student_error_text.dart';
import '../widgets/student_form.dart';
import 'student_detail_route.dart';

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

  /// Opens bulk import (A-12) as a pushed page, then refreshes the register if it enrolled
  /// anyone — the rows the operator just added should appear without a manual reload.
  Future<void> _openImport(BuildContext context) async {
    final bloc = context.read<StudentListBloc>();
    final schoolId = _selectedSchoolId;
    if (schoolId == null || schoolId.isEmpty) return;

    final imported = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => StudentImportRoute(schoolId: schoolId),
      ),
    );

    if ((imported ?? false) == true) {
      bloc.add(StudentListRequested(schoolId: schoolId));
    }
  }

  /// Opens the record for one student (A-11) as a pushed page. A detail view of a
  /// specific student, so it is navigated to rather than being a nav-rail destination.
  void _openDetail(BuildContext context, Student student) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentDetailRoute(student: student),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Student? existing}) async {
    final bloc = context.read<StudentListBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final savedMessage = context.l10n.commonChangesSavedSnackbar;
    final schoolId = _selectedSchoolId ?? '';

    final saved = await showDialog<bool>(
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

    // `true` only when the listener in [build] closed the dialog after the write succeeded — a
    // cancel or a dismissed dialog returns null, and a failed save keeps the dialog open.
    if (existing != null && (saved ?? false)) {
      messenger.showSnackBar(SnackBar(content: Text(savedMessage)));
    }
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
        title: Text(context.l10n.studentWithdrawConfirmTitle),
        content: Text(
          context.l10n.studentWithdrawConfirmBody(student.displayName, student.admissionNo),
        ),
        actions: [
          TextButton(
            key: const Key('student_withdraw_cancel_button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancelButton),
          ),
          FilledButton(
            key: const Key('student_withdraw_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.studentWithdrawConfirmButton),
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
        // inside StudentForm, which has no reason to know it is inside a dialog. Closed with
        // `true` so [_openForm] can confirm an edit was saved.
        if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
      },
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(context.l10n.studentListTitle, style: theme.textTheme.headlineSmall),
                ),
                if (canEdit) ...[
                  _ImportButton(
                    enabled: _selectedSchoolId != null,
                    onPressed: () => _openImport(context),
                  ),
                  const SizedBox(width: AdminSpacing.sm),
                  _EnrolButton(
                    // Disabled until a school is chosen below — enrolling with no school
                    // selected would submit an empty schoolId (an operator managing more than
                    // one organization sees the picker below before any school is known), and
                    // a disabled button with a reason beats a dialog that fails after the fact.
                    enabled: _selectedSchoolId != null,
                    onPressed: () => _openForm(context),
                  ),
                ],
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
                labelText: context.l10n.commonSearchLabel,
                hintText: context.l10n.studentListSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('student_list_search_clear_button'),
                        icon: const Icon(Icons.close),
                        tooltip: context.l10n.commonClearSearchTooltip,
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
      return Center(
        child: CircularProgressIndicator(semanticsLabel: context.l10n.studentListLoadingLabel),
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
          context.l10n.studentListEmptyState,
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
              ? context.l10n.studentListNoMatchWithMore
              : context.l10n.studentListNoMatch,
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
          // The register sits on a panel rather than loose on the canvas: a table of two
          // thousand rows needs an edge, or the rows read as floating text.
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.livery.panel,
              border: Border.all(color: context.livery.border),
              borderRadius: BorderRadius.circular(10),
            ),
            // ListView.builder, not a Column in a scroll view: the register is thousands of
            // rows and only the visible ones should be built
            // (CODING_STANDARDS_FLUTTER.md).
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.zero,
              itemCount: students.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= students.length) {
                  return Padding(
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: context.l10n.studentListLoadingMoreLabel,
                      ),
                    ),
                  );
                }
                return _StudentRow(
                  student: students[index],
                  canEdit: canEdit,
                  onOpen: () => _openDetail(context, students[index]),
                  onEdit: () => _openForm(context, existing: students[index]),
                  onWithdraw: () => _confirmWithdraw(context, students[index]),
                );
              },
            ),
          ),
        ),
        if (!state.hasMore && _searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AdminSpacing.sm),
            child: Text(
              context.l10n.studentListCount(state.students.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// The "Enrol student" action — a plain [FilledButton] when a school is selected, or the
/// same button disabled with a [Tooltip] explaining why when it is not.
class _EnrolButton extends StatelessWidget {
  const _EnrolButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      key: const Key('student_list_add_button'),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.person_add_alt_1),
      label: Text(context.l10n.studentListEnrolButton),
    );

    if (enabled) return button;
    return Tooltip(message: context.l10n.pickSchoolFirstTooltip, child: button);
  }
}

/// The "Import" action — opens bulk import (A-12). Disabled with a tooltip until a school is
/// chosen, matching [_EnrolButton]: the import needs a school to enrol every row into.
class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      key: const Key('student_list_import_button'),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.upload_file),
      label: Text(context.l10n.studentListImportButton),
    );

    if (enabled) return button;
    return Tooltip(message: context.l10n.pickSchoolFirstTooltip, child: button);
  }
}

/// One row of the register.
class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.canEdit,
    required this.onEdit,
    required this.onWithdraw,
    required this.onOpen,
  });

  final Student student;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onWithdraw;
  final VoidCallback onOpen;

  /// The row's accent, as a (fill, ink) pair.
  ///
  /// **Deliberately not the safety palette.** `GuardianStatusColors` means *the child is
  /// accounted for* / *something is wrong on a journey*; enrolment is a registry state, and
  /// painting "on roll" green would spend the one signal that has to stay unambiguous on a
  /// row that says nothing about where a child is. Active rows take the brand's navy
  /// container, everything else is neutral.
  (Color, Color) _accent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (student.isWithdrawn || !student.transportEligible) {
      return (context.livery.panelSubtle, scheme.onSurfaceVariant);
    }
    return (scheme.primaryContainer, scheme.onPrimaryContainer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final livery = context.livery;
    final (fill, ink) = _accent(context);
    final muted = student.isWithdrawn;

    return InkWell(
      key: Key('student_list_row_${student.id}'),
      onTap: onOpen,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
          vertical: AdminSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: livery.border)),
        ),
        child: Row(
          children: [
            // Initials rather than a generic person glyph: at a glance down a column of
            // two thousand rows, a repeated identical icon carries no information.
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
              child: ExcludeSemantics(
                child: student.hasPhoto
                    ? Icon(Icons.face, size: 19, color: ink)
                    : Text(
                        _initials(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: muted ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  Text(
                    student.admissionNo,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: livery.placeholder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            // The status is a word, not only a tint — colour and shape are never the only
            // signal (DESIGN_SYSTEM.md §Principles).
            _StatusChip(label: _statusLabel(context), fill: fill, ink: ink),
            if (canEdit) ...[
              const SizedBox(width: AdminSpacing.sm),
              IconButton(
                key: Key('student_list_edit_${student.id}'),
                icon: const Icon(Icons.edit_outlined, size: 19),
                tooltip: context.l10n.studentListEditTooltip(student.displayName),
                onPressed: onEdit,
              ),
              if (!student.isWithdrawn)
                IconButton(
                  key: Key('student_list_withdraw_${student.id}'),
                  icon: const Icon(Icons.person_remove_outlined, size: 19),
                  tooltip: context.l10n.studentListWithdrawTooltip(student.displayName),
                  onPressed: onWithdraw,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// First letters of the displayed name, at most two.
  String _initials() {
    final parts = student.displayName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _statusLabel(BuildContext context) {
    if (student.isWithdrawn) return context.l10n.studentStatusWithdrawn;
    if (!student.transportEligible) return context.l10n.studentStatusOnRollNoTransport;
    return context.l10n.studentStatusOnRollTransport;
  }
}

/// A registry state, spelled out, on its own tint.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.fill,
    required this.ink,
  });

  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
