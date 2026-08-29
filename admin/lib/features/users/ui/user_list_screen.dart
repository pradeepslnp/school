import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_error_text.dart';
import '../bloc/user_list_bloc.dart';
import '../bloc/user_list_event.dart';
import '../bloc/user_list_state.dart';
import '../domain/user_models.dart';
import '../widgets/create_user_form.dart';
import '../widgets/edit_user_form.dart';

/// A-43 — Users: create and manage administrative sign-ins (`ORG_ADMIN`, `SCHOOL_ADMIN`,
/// `PRINCIPAL`, `TRANSPORT_MANAGER`) for one organization. Reached only by roles holding
/// `PERM-USER-VIEW` — see `ConsoleDestinations`.
///
/// Matching `StaffListScreen`: no decisions here, only rendering and reporting what the
/// operator did. The one addition this screen carries that `StaffListScreen` does not is
/// [actorRoles] — the create dialog needs to know who is looking at it, not just which
/// organization, to offer only the roles BR-IAM-006 lets this operator grant.
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key, required this.actorRoles, this.lockedSchoolId});

  final List<String> actorRoles;

  /// A `SCHOOL_ADMIN`'s own school — see `UserListRoute`'s documentation.
  final String? lockedSchoolId;

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _search = TextEditingController();
  String _searchQuery = '';

  List<String> get _assignableRoles => assignableRoleCodes(widget.actorRoles);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openAddForm(BuildContext context) async {
    final bloc = context.read<UserListBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: _CreateUserDialogBody(
                roleCodes: _assignableRoles,
                lockedSchoolId: widget.lockedSchoolId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditForm(BuildContext context, AdminUser user) async {
    final bloc = context.read<UserListBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: BlocProvider.value(
              value: bloc,
              child: BlocBuilder<UserListBloc, UserListState>(
                builder: (context, state) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EditUserForm(
                      user: user,
                      isSubmitting: state.isSubmitting,
                      onCancel: () => Navigator.of(dialogContext).pop(),
                      onSubmit: ({
                        required String firstName,
                        required String lastName,
                        required String preferredLocale,
                      }) {
                        bloc.add(UserProfileUpdateRequested(
                          userId: user.id,
                          firstName: firstName,
                          lastName: lastName,
                          preferredLocale: preferredLocale,
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

  Future<void> _confirmToggleStatus(BuildContext context, AdminUser user) async {
    final activate = !user.isActive;
    final bloc = context.read<UserListBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          activate ? 'Reactivate ${user.displayName}?' : 'Deactivate ${user.displayName}?',
        ),
        content: Text(
          activate
              ? 'They will be able to sign in again.'
              : 'They will no longer be able to sign in. This can be reversed at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('user_list_toggle_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(activate ? 'Reactivate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(UserStatusToggleRequested(userId: user.id, activate: activate));
    }
  }

  /// Instant, client-side, over whatever roster is already loaded — matching
  /// `StaffListScreen._filtered`'s own note on why: no server-side search endpoint exists.
  List<AdminUser> _filtered(List<AdminUser> users) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where((user) =>
            user.displayName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            roleDisplayName(user.primaryRoleCode).toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<UserListBloc, UserListState>(
      listenWhen: (previous, current) =>
          current.actionNotice != null && previous.actionNotice != current.actionNotice,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.actionNotice!))),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Users', style: theme.textTheme.headlineSmall)),
              BlocBuilder<UserListBloc, UserListState>(
                buildWhen: (previous, current) =>
                    previous.resolvedOrganizationId != current.resolvedOrganizationId,
                builder: (context, state) {
                  final canAdd =
                      _assignableRoles.isNotEmpty && state.resolvedOrganizationId != null;
                  return FilledButton.icon(
                    key: const Key('user_list_add_button'),
                    onPressed: canAdd ? () => _openAddForm(context) : null,
                    icon: const Icon(Icons.person_add_alt_outlined),
                    label: const Text('Add administrator'),
                  );
                },
              ),
            ],
          ),
          BlocBuilder<UserListBloc, UserListState>(
            builder: (context, state) {
              if (!state.needsOrganizationPicker) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AdminSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrganizationPicker(state: state),
                    if (state.error != null)
                      OnboardingErrorText(code: state.error!, messageKey: state.errorMessageKey),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AdminSpacing.lg),
          TextField(
            key: const Key('user_list_search_field'),
            controller: _search,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Filter by name, email, or role',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('user_list_search_clear_button'),
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
            child: BlocBuilder<UserListBloc, UserListState>(
              builder: (context, state) {
                if (state.isLoading && state.users.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(semanticsLabel: 'Loading users'),
                  );
                }

                if (state.needsOrganizationPicker && state.resolvedOrganizationId == null) {
                  return Center(
                    child: Text(
                      'Pick an organization above to see its administrators.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                if (state.error != null && state.users.isEmpty) {
                  final color = context.status.critical;
                  return Center(
                    child: Text(
                      'That could not be loaded right now. Try again.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  );
                }

                if (state.users.isEmpty) {
                  return Center(
                    child: Text(
                      'No administrators yet. Add the first one above.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                final filtered = _filtered(state.users);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No one matches "$_searchQuery".',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return _UserTable(
                  users: filtered,
                  onTapUser: (user) => _openEditForm(context, user),
                  onToggleStatus: (user) => _confirmToggleStatus(context, user),
                  onResendInvite: (user) => context
                      .read<UserListBloc>()
                      .add(UserInvitationResendRequested(user.id)),
                  onSendReset: (user) =>
                      context.read<UserListBloc>().add(UserResetLinkRequested(user.id)),
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

/// Shown only for a `SUPER_ADMIN` (`UserListState.needsOrganizationPicker`) — every other
/// role reaches this screen with its organization already known, see `UserListRoute`.
class _OrganizationPicker extends StatelessWidget {
  const _OrganizationPicker({required this.state});

  final UserListState state;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const Key('user_list_organization_field'),
      initialValue: state.resolvedOrganizationId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Organization',
        border: OutlineInputBorder(),
        constraints: BoxConstraints(minHeight: kAdminTouchTarget),
      ),
      hint: Text(state.isLoadingOrganizations ? 'Loading…' : 'Select an organization'),
      items: [
        for (final organization in state.organizations)
          DropdownMenuItem(value: organization.id, child: Text(organization.name)),
      ],
      onChanged: state.isLoadingOrganizations
          ? null
          : (organizationId) {
              if (organizationId == null) return;
              context.read<UserListBloc>().add(UserListOrganizationSelected(organizationId));
            },
    );
  }
}

/// The add-administrator dialog's body — a form, then (on success) the one-time credentials
/// view. Owns the just-submitted email/password locally: neither is ever returned by the
/// server after this point (see `CreatedUserCredentialsView`), so this is the only place
/// they can come from.
class _CreateUserDialogBody extends StatefulWidget {
  const _CreateUserDialogBody({required this.roleCodes, required this.lockedSchoolId});

  final List<String> roleCodes;
  final String? lockedSchoolId;

  @override
  State<_CreateUserDialogBody> createState() => _CreateUserDialogBodyState();
}

class _CreateUserDialogBodyState extends State<_CreateUserDialogBody> {
  String? _pendingEmail;
  String? _pendingPassword;
  String _pendingMode = 'INVITE';
  String? _createdEmail;
  String? _createdPassword;
  String? _createdMode;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserListBloc, UserListState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting && current.error == null,
      listener: (context, state) {
        setState(() {
          _createdEmail = _pendingEmail;
          _createdPassword = _pendingPassword;
          _createdMode = _pendingMode;
        });
      },
      builder: (context, state) {
        final createdEmail = _createdEmail;
        if (createdEmail != null) {
          // Invite mode never has a password to show — the account is pending until the invitee
          // sets one (ADR-0012).
          if (_createdMode == 'INVITE') {
            return InvitationSentView(
              email: createdEmail,
              onDone: () => Navigator.of(context).pop(),
            );
          }
          final createdPassword = _createdPassword;
          if (createdPassword != null) {
            return CreatedUserCredentialsView(
              email: createdEmail,
              password: createdPassword,
              onDone: () => Navigator.of(context).pop(),
            );
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CreateUserForm(
              roleCodes: widget.roleCodes,
              schools: state.schools,
              lockedSchoolId: widget.lockedSchoolId,
              isSubmitting: state.isSubmitting,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: ({
                String? schoolId,
                required String email,
                String? phone,
                required String firstName,
                required String lastName,
                required String roleCode,
                String? initialPassword,
                required String deliveryMode,
              }) {
                _pendingEmail = email;
                _pendingPassword = initialPassword;
                _pendingMode = deliveryMode;
                context.read<UserListBloc>().add(UserCreateRequested(
                      schoolId: schoolId,
                      email: email,
                      phone: phone,
                      firstName: firstName,
                      lastName: lastName,
                      roleCode: roleCode,
                      initialPassword: initialPassword,
                      deliveryMode: deliveryMode,
                    ));
              },
            ),
            if (state.error != null)
              OnboardingErrorText(code: state.error!, messageKey: state.errorMessageKey),
          ],
        );
      },
    );
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({
    required this.users,
    required this.onTapUser,
    required this.onToggleStatus,
    required this.onResendInvite,
    required this.onSendReset,
  });

  final List<AdminUser> users;
  final ValueChanged<AdminUser> onTapUser;
  final ValueChanged<AdminUser> onToggleStatus;
  final ValueChanged<AdminUser> onResendInvite;
  final ValueChanged<AdminUser> onSendReset;

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
        key: const Key('user_list_table'),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          final statusColor = user.isActive ? context.status.safe : context.status.warning;
          final statusLabel = user.isActive
              ? 'Active'
              : user.isPending
                  ? 'Pending'
                  : 'Inactive';

          return ListTile(
            key: Key('user_list_row_${user.id}'),
            minVerticalPadding: AdminSpacing.md,
            title: Text(user.displayName),
            subtitle: Text('${user.email} · ${roleDisplayName(user.primaryRoleCode)}'),
            onTap: () => onTapUser(user),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AdminSpacing.sm),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
                  ),
                ),
                if (!user.isPending)
                  IconButton(
                    key: Key('user_list_toggle_${user.id}'),
                    tooltip: user.isActive ? 'Deactivate' : 'Reactivate',
                    icon: Icon(
                      user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                    ),
                    onPressed: () => onToggleStatus(user),
                  ),
                // Invitation / reset actions (ADR-0012). A menu rather than more inline icons —
                // pending accounts get resend, active ones get a reset link; an inactive account
                // has neither, so no menu is shown.
                if (user.isPending || user.isActive)
                  PopupMenuButton<String>(
                  key: Key('user_list_actions_${user.id}'),
                  tooltip: 'More actions',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case 'resend':
                        onResendInvite(user);
                      case 'reset':
                        onSendReset(user);
                    }
                  },
                  itemBuilder: (context) => [
                    if (user.isPending)
                      const PopupMenuItem(
                        value: 'resend',
                        child: ListTile(
                          leading: Icon(Icons.mail_outline),
                          title: Text('Resend invitation'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (user.isActive)
                      const PopupMenuItem(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(Icons.lock_reset_outlined),
                          title: Text('Send reset code'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
