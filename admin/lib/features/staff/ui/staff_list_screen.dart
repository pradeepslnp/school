import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/dependencies.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../../school_scope/widgets/school_picker_field.dart';
import '../bloc/staff_list_bloc.dart';
import '../bloc/staff_list_event.dart';
import '../bloc/staff_list_state.dart';
import '../domain/staff_models.dart';
import '../widgets/create_staff_form.dart';
import '../widgets/edit_staff_form.dart';

/// A-23 — Drivers: register transport staff and see who already has a working sign-in
/// (STF-001). Reached only by roles holding `PERM-STAFF-MANAGE` (PERMISSION_MATRIX.md) — see
/// `ConsoleDestinations`.
///
/// Holds the "which school" text the operator is looking at — everything else is
/// [StaffListState]. Matching `OrganizationListScreen`: no decisions here, only rendering and
/// reporting what the operator did.
class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key, this.initialSchoolId});

  /// The signed-in operator's own school (`AuthenticatedUser.schoolScopeId`), when they hold
  /// a school-scoped role. Pre-fills the field and loads immediately, so a `TRANSPORT_MANAGER`
  /// or `SCHOOL_ADMIN` sees their own roster without pasting an id first — an `ORG_ADMIN` or
  /// `SUPER_ADMIN`, who oversees more than one school, still has to enter one.
  final String? initialSchoolId;

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  /// The school currently loaded — from [widget.initialSchoolId], from `WorkspaceContext`, or
  /// from `SchoolPickerField` (shown only when neither of those is set; see [build]).
  String? _selectedSchoolId;
  final _search = TextEditingController();
  String _searchQuery = '';

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
      context.read<StaffListBloc>().add(StaffListRequested(schoolId: schoolId));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load(BuildContext context, String schoolId) {
    if (schoolId.isEmpty) return;
    setState(() => _selectedSchoolId = schoolId);
    DependencyScope.of(context).workspaceContext.value = schoolId;
    context.read<StaffListBloc>().add(StaffListRequested(schoolId: schoolId));
  }

  Future<void> _openAddForm(BuildContext context) async {
    final bloc = context.read<StaffListBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<StaffListBloc, StaffListState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CreateStaffForm(
                      schoolId: _selectedSchoolId!,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String schoolId,
                        required String staffType,
                        required String firstName,
                        required String lastName,
                        required String phone,
                        String? employeeCode,
                        String? vendorName,
                      }) {
                        bloc.add(StaffCreated(
                          schoolId: schoolId,
                          staffType: staffType,
                          firstName: firstName,
                          lastName: lastName,
                          phone: phone,
                          employeeCode: employeeCode,
                          vendorName: vendorName,
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

  Future<void> _openEditForm(BuildContext context, CreatedStaff staff) async {
    final bloc = context.read<StaffListBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final savedMessage = context.l10n.commonChangesSavedSnackbar;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<StaffListBloc, StaffListState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EditStaffForm(
                      staff: staff,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String firstName,
                        required String lastName,
                        required String phone,
                        String? employeeCode,
                        String? vendorName,
                      }) {
                        bloc.add(StaffUpdated(
                          staffId: staff.id,
                          firstName: firstName,
                          lastName: lastName,
                          phone: phone,
                          employeeCode: employeeCode,
                          vendorName: vendorName,
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

    // `true` only when the listener in [build] closed the dialog after the update succeeded — a
    // cancel or a dismissed dialog returns null, and a failed save keeps the dialog open.
    if (saved ?? false) {
      messenger.showSnackBar(SnackBar(content: Text(savedMessage)));
    }
  }

  /// Instant, client-side, over whatever roster is already loaded — no server round trip. See
  /// `StaffDataProvider`'s own note on `GET /transport-staff` taking only `schoolId`: a
  /// real search endpoint does not exist yet, so this is what "type a name or phone and see
  /// matches" can mean today.
  List<CreatedStaff> _filtered(List<CreatedStaff> staff) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return staff;
    return staff
        .where((person) =>
            person.displayName.toLowerCase().contains(query) ||
            person.phone.contains(query) ||
            (person.employeeCode?.toLowerCase().contains(query) ?? false))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<StaffListBloc, StaffListState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        // The add or edit dialog is still open until the write succeeds — close it here rather
        // than from inside the form, which has no reason to know it is inside a dialog. Closed
        // with `true` so [_openEditForm] can confirm the save.
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
                  child: Text(context.l10n.staffListTitle, style: theme.textTheme.headlineSmall),
                ),
_AddDriverButton(
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
            const SizedBox(height: AdminSpacing.md),
            TextField(
              key: const Key('staff_list_search_field'),
              controller: _search,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: context.l10n.commonSearchLabel,
                hintText: context.l10n.staffListSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('staff_list_search_clear_button'),
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
              child: BlocBuilder<StaffListBloc, StaffListState>(
                builder: (context, state) {
                  if (state.isLoading && state.staff.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: context.l10n.staffListLoadingLabel,
                      ),
                    );
                  }

                  if (state.error != null && state.staff.isEmpty) {
                    final color = context.status.critical;
                    return Center(
                      child: Text(
                        context.l10n.errorGenericLoadRetry,
                        style: theme.textTheme.bodyMedium?.copyWith(color: color),
                      ),
                    );
                  }

                  if (state.staff.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.staffListEmptyState,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final filtered = _filtered(state.staff);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.staffListSearchNoMatches(_searchQuery),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return _StaffTable(
                    staff: filtered,
                    onTapStaff: (person) => _openEditForm(context, person),
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

class _StaffTable extends StatelessWidget {
  const _StaffTable({required this.staff, required this.onTapStaff});

  final List<CreatedStaff> staff;
  final ValueChanged<CreatedStaff> onTapStaff;

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
        key: const Key('staff_list_table'),
        itemCount: staff.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final person = staff[index];
          final loginColor =
              person.hasLogin ? context.status.safe : context.status.warning;

          return ListTile(
            key: Key('staff_list_row_${person.id}'),
            minVerticalPadding: AdminSpacing.md,
            title: Text(person.displayName),
            subtitle: Text(context.l10n.staffListRowSubtitle(person.staffType, person.phone)),
            onTap: () => onTapStaff(person),
            trailing: Tooltip(
              message: person.hasLogin
                  ? context.l10n.staffListHasLoginTooltip
                  : context.l10n.staffListNoLoginTooltip,
              child: Icon(
                person.hasLogin ? Icons.check_circle_outline : Icons.error_outline,
                color: loginColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The "Add driver" action — a plain [FilledButton] when a school is selected, or the same
/// button disabled with a [Tooltip] explaining why when it is not. Enrolling/adding with no
/// school chosen would submit against an empty schoolId — see `StudentListScreen._EnrolButton`
/// for the original reasoning, applied identically here.
class _AddDriverButton extends StatelessWidget {
  const _AddDriverButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      key: const Key('staff_list_add_button'),
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.add),
      label: Text(context.l10n.staffListAddButton),
    );

    if (enabled) return button;
    return Tooltip(message: context.l10n.pickSchoolFirstTooltip, child: button);
  }
}
