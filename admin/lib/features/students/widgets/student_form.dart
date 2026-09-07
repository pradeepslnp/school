import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/student_models.dart';

/// Enrol or correct a student (STU-001) — one form for both, because the fields are the same
/// two apart and two nearly-identical forms drift.
///
/// When [existing] is null this enrols; otherwise it edits, and the admission number becomes
/// read-only. That is not a UI preference: the number identifies the child to every safety
/// record that cites them, so changing it would orphan their reference (see
/// `StudentDataProvider.updateStudent`). Showing it disabled rather than hiding it tells the
/// operator which student they are editing.
class StudentForm extends StatefulWidget {
  const StudentForm({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onCancel,
    this.existing,
    this.schoolId,
  });

  final bool isSubmitting;
  final Student? existing;
  final String? schoolId;
  final VoidCallback onCancel;

  final void Function({
    required String admissionNo,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    required bool transportEligible,
  }) onSubmit;

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _admissionNo;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _dateOfBirth;
  late bool _transportEligible;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _admissionNo = TextEditingController(text: existing?.admissionNo ?? '');
    _firstName = TextEditingController(text: existing?.firstName ?? '');
    _lastName = TextEditingController(text: existing?.lastName ?? '');
    _dateOfBirth = TextEditingController(
      text: existing?.dateOfBirth == null
          ? ''
          : _formatDate(existing!.dateOfBirth!),
    );
    _transportEligible = existing?.transportEligible ?? true;
  }

  @override
  void dispose() {
    _admissionNo.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final dateOfBirth = _dateOfBirth.text.trim();
    widget.onSubmit(
      admissionNo: _admissionNo.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      dateOfBirth: dateOfBirth.isEmpty ? null : dateOfBirth,
      transportEligible: _transportEligible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? context.l10n.studentFormEditTitle : context.l10n.studentListEnrolButton,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AdminSpacing.lg),
          TextFormField(
            key: const Key('student_form_admission_no_field'),
            controller: _admissionNo,
            enabled: !_isEditing,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.studentFormAdmissionNoLabel,
              helperText: _isEditing
                  ? context.l10n.studentFormAdmissionNoHelperEditing
                  : context.l10n.studentFormAdmissionNoHelperNew,
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.studentFormAdmissionNoRequired
                : null,
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            key: const Key('student_form_first_name_field'),
            controller: _firstName,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.firstNameLabel,
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.studentFormFirstNameRequired
                : null,
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            key: const Key('student_form_last_name_field'),
            controller: _lastName,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.l10n.lastNameLabel,
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.studentFormLastNameRequired
                : null,
          ),
          const SizedBox(height: AdminSpacing.md),
          TextFormField(
            key: const Key('student_form_date_of_birth_field'),
            controller: _dateOfBirth,
            decoration: InputDecoration(
              labelText: context.l10n.studentFormDateOfBirthLabel,
              // Not decoration: self-release eligibility is decided from it (BR-HAND-005), so
              // the operator should know it is load-bearing before leaving it blank.
              helperText: context.l10n.studentFormDateOfBirthHelper,
              border: const OutlineInputBorder(),
              constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;
              final parsed = DateTime.tryParse(text);
              if (parsed == null) return context.l10n.studentFormDateOfBirthFormatError;
              if (!parsed.isBefore(DateTime.now())) {
                return context.l10n.studentFormDateOfBirthPastError;
              }
              return null;
            },
          ),
          const SizedBox(height: AdminSpacing.md),
          SwitchListTile(
            key: const Key('student_form_transport_eligible_switch'),
            value: _transportEligible,
            onChanged: (value) => setState(() => _transportEligible = value),
            title: Text(context.l10n.studentFormTransportEligibleTitle),
            subtitle: Text(context.l10n.studentFormTransportEligibleSubtitle),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AdminSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('student_form_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
              const SizedBox(width: AdminSpacing.sm),
              FilledButton(
                key: const Key('student_form_submit_button'),
                onPressed: widget.isSubmitting ? null : _submit,
                child: Text(
                  _isEditing
                      ? context.l10n.commonSaveChangesButton
                      : context.l10n.studentListEnrolButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
