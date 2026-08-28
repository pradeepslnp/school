import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../organizations/domain/onboarding_models.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../domain/user_models.dart';

/// Creates an administrative login (`ORG_ADMIN`, `SCHOOL_ADMIN`, `PRINCIPAL`, or
/// `TRANSPORT_MANAGER`) — IAM-005, IAM-008, screen A-43.
///
/// `roleCodes` is already filtered to what the signed-in operator may grant
/// (`assignableRoleCodes`, BR-IAM-006) — this form does not re-derive that list, so it can
/// never accidentally offer a role the server would refuse.
///
/// The school picker is shown only when both are true: the selected role is school-scoped
/// (`isSchoolScopedRole`) and [lockedSchoolId] is null. A `SCHOOL_ADMIN` operator only ever
/// grants school-scoped roles and only ever within their own school — passing their own
/// school id as [lockedSchoolId] means they are never shown a dropdown listing every school
/// in the organization, most of which are not theirs to grant into.
class CreateUserForm extends StatefulWidget {
  const CreateUserForm({
    super.key,
    required this.roleCodes,
    required this.schools,
    required this.onSubmit,
    required this.onCancel,
    this.lockedSchoolId,
    this.isSubmitting = false,
  });

  final List<String> roleCodes;
  final List<CreatedSchool> schools;
  final String? lockedSchoolId;

  final void Function({
    String? schoolId,
    required String email,
    String? phone,
    required String firstName,
    required String lastName,
    required String roleCode,
    String? initialPassword,
    required String deliveryMode,
  }) onSubmit;

  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<CreateUserForm> createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  String? _roleCode;
  String? _schoolId;

  /// `INVITE` (default) emails a set-password link; `PASSWORD` sets one here and now (ADR-0012).
  String _deliveryMode = 'INVITE';

  bool get _isInvite => _deliveryMode == 'INVITE';

  @override
  void initState() {
    super.initState();
    _roleCode = widget.roleCodes.isEmpty ? null : widget.roleCodes.first;
    _schoolId = widget.lockedSchoolId;
    _autoSelectOnlySchool();
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _needsSchool =>
      widget.lockedSchoolId == null && _roleCode != null && isSchoolScopedRole(_roleCode!);

  /// Most organizations on this platform have exactly one school — matching
  /// `SchoolPickerField`'s own reasoning for auto-selecting rather than making the operator
  /// open a dropdown with one entry in it.
  void _autoSelectOnlySchool() {
    if (_needsSchool && widget.schools.length == 1) {
      _schoolId = widget.schools.first.id;
    }
  }

  void _generatePassword() {
    // Not cryptographically precious — this is a one-time credential the receiving admin is
    // expected to change (no forced-rotation flow exists yet, flagged in
    // CreateAdministrativeUserUseCase). Random.secure() costs nothing extra here and rules
    // out any predictability question being asked later.
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%';
    final random = Random.secure();
    final generated =
        List.generate(14, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() {
      _password.text = generated;
      _obscurePassword = false;
    });
  }

  void _submit() {
    if (widget.isSubmitting) return;
    final roleCode = _roleCode;
    if (roleCode == null) return;
    widget.onSubmit(
      schoolId: isSchoolScopedRole(roleCode) ? (widget.lockedSchoolId ?? _schoolId) : null,
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      firstName: _firstName.text,
      lastName: _lastName.text,
      roleCode: roleCode,
      initialPassword: _isInvite ? null : _password.text,
      deliveryMode: _deliveryMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Add administrator', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          _isInvite
              ? 'We email them a link to set their own password and activate the account.'
              : 'You set a password now and share it with them yourself.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        SegmentedButton<String>(
          key: const Key('user_form_delivery_mode'),
          segments: const [
            ButtonSegment(
              value: 'INVITE',
              label: Text('Send invite'),
              icon: Icon(Icons.mail_outline),
            ),
            ButtonSegment(
              value: 'PASSWORD',
              label: Text('Set password'),
              icon: Icon(Icons.password_outlined),
            ),
          ],
          selected: {_deliveryMode},
          onSelectionChanged: widget.isSubmitting
              ? null
              : (selection) => setState(() => _deliveryMode = selection.first),
        ),
        const SizedBox(height: AdminSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('user_form_role_field'),
          initialValue: _roleCode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Role',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          items: [
            for (final role in widget.roleCodes)
              DropdownMenuItem(value: role, child: Text(roleDisplayName(role))),
          ],
          onChanged: widget.isSubmitting || widget.roleCodes.isEmpty
              ? null
              : (value) => setState(() {
                    _roleCode = value;
                    _autoSelectOnlySchool();
                  }),
        ),
        if (_needsSchool) ...[
          const SizedBox(height: AdminSpacing.md),
          DropdownButtonFormField<String>(
            key: const Key('user_form_school_field'),
            initialValue: _schoolId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'School',
              hintText: 'Which school this role applies to',
              border: OutlineInputBorder(),
              constraints: BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            items: [
              for (final school in widget.schools)
                DropdownMenuItem(value: school.id, child: Text(school.name)),
            ],
            onChanged: widget.isSubmitting
                ? null
                : (value) => setState(() => _schoolId = value),
          ),
        ],
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('user_form_first_name_field'),
          controller: _firstName,
          autofocus: true,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'First name',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('user_form_last_name_field'),
          controller: _lastName,
          enabled: !widget.isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Last name',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('user_form_email_field'),
          controller: _email,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (sign-in)',
            hintText: 'What this person signs in with',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('user_form_phone_field'),
          controller: _phone,
          enabled: !widget.isSubmitting,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone (optional)',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        if (!_isInvite) ...[
          const SizedBox(height: AdminSpacing.md),
          TextField(
            key: const Key('user_form_password_field'),
            controller: _password,
            enabled: !widget.isSubmitting,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Initial password',
              hintText: 'At least 12 characters',
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('user_form_password_visibility_button'),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: widget.isSubmitting
                        ? null
                        : () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  IconButton(
                    key: const Key('user_form_password_generate_button'),
                    tooltip: 'Generate a password',
                    icon: const Icon(Icons.autorenew),
                    onPressed: widget.isSubmitting ? null : _generatePassword,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('user_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('user_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: widget.isSubmitting
                    ? const OnboardingButtonSpinner(semanticsLabel: 'Adding')
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Confirms an invitation was sent (ADR-0012 invite mode). No credential to show — the account
/// is pending until the invitee sets their own password via the emailed link.
class InvitationSentView extends StatelessWidget {
  const InvitationSentView({super.key, required this.email, required this.onDone});

  final String email;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: context.status.safe),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(child: Text('Invitation sent', style: theme.textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'We’ve emailed $email a link to set their password. It is valid for 72 hours; '
          'you can re-send it from their row if it expires.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('user_form_invitation_done_button'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Shows the just-created account's credentials once, with a one-tap copy — the operator's only
/// chance to hand them to the new admin (password delivery mode, ADR-0012), since the server never
/// returns a password after this moment.
class CreatedUserCredentialsView extends StatelessWidget {
  const CreatedUserCredentialsView({
    super.key,
    required this.email,
    required this.password,
    required this.onDone,
  });

  final String email;
  final String password;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: context.status.safe),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text('Account created', style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          'Share these sign-in details with them now — this password will not be shown '
          'again.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        _CopyableField(key: const Key('user_form_created_email'), label: 'Email', value: email),
        const SizedBox(height: AdminSpacing.md),
        _CopyableField(
          key: const Key('user_form_created_password'),
          label: 'Password',
          value: password,
        ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('user_form_created_done_button'),
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// A styled, selectable, copyable value — built on [InputDecorator] rather than a read-only
/// [TextField], so there is no [TextEditingController] for a stateless widget to own and
/// never dispose.
class _CopyableField extends StatelessWidget {
  const _CopyableField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
        suffixIcon: IconButton(
          tooltip: 'Copy',
          icon: const Icon(Icons.copy_outlined),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied')),
              );
            }
          },
        ),
      ),
      child: SelectableText(value),
    );
  }
}
