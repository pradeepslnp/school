import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../domain/onboarding_models.dart';

/// Step 3: confirmation, once the organization (and optionally its first school) exists.
class OnboardingCompleteSummary extends StatelessWidget {
  const OnboardingCompleteSummary({
    super.key,
    required this.organization,
    required this.school,
    required this.onStartAnother,
  });

  final CreatedOrganization organization;

  /// Null if the operator skipped step 2.
  final CreatedSchool? school;

  final VoidCallback onStartAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeColor = context.status.safe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: safeColor),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text('Organization onboarded', style: theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        _SummaryRow(label: 'Organization', value: '${organization.name} (${organization.code})'),
        if (school != null) ...[
          _SummaryRow(label: 'First school', value: '${school!.name} (${school!.code})'),
          _CopyableIdRow(
            key: const Key('onboarding_school_id_row'),
            label: 'School ID',
            value: school!.id,
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: AdminSpacing.sm),
            child: Text(
              'No school was added yet. Add one from the Schools screen before this '
              'organization is used day to day (BR-TEN-002).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AdminSpacing.lg),
        FilledButton(
          key: const Key('org_onboarding_start_another_button'),
          onPressed: onStartAnother,
          child: const Text('Onboard another organization'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Like [_SummaryRow], but for the school's UUID — the value that has to be handed to whoever
/// registers staff, vehicles, or routes for it, none of which accept the human-readable code
/// (BR-TEN-007). Copyable because nobody should have to select a UUID by hand.
class _CopyableIdRow extends StatelessWidget {
  const _CopyableIdRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}
