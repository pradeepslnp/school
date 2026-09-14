import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// One titled group of fields in an onboarding form: what the group is for on the start side,
/// its fields beside it.
///
/// A settings-page layout rather than one long column of labels, so an operator scans a handful
/// of headings to find a field instead of reading every label top to bottom. Side by side when
/// the section itself is wide enough, stacked when it is not — measured on the section, not the
/// window, so the same section works in the onboarding card and in the details view.
class OnboardingFormSection extends StatelessWidget {
  const OnboardingFormSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  static const double _sideBySideMinWidth = 600;
  static const double _headingWidth = 200;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _sideBySideMinWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: _headingWidth, child: heading),
              const SizedBox(width: AdminSpacing.xl),
              Expanded(child: child),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: AdminSpacing.md),
            child,
          ],
        );
      },
    );
  }
}

/// The hairline between two [OnboardingFormSection]s, with the breathing room either side.
class OnboardingSectionDivider extends StatelessWidget {
  const OnboardingSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AdminSpacing.lg),
      child: Divider(height: 1),
    );
  }
}

/// A field that does not need the full width of its section — a short code, a radius, a time
/// zone. Held to a width that hints at the length of the value expected.
class OnboardingCompactField extends StatelessWidget {
  const OnboardingCompactField({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// The action row that closes an onboarding form: the way out on the start side, the way
/// forward on the end side.
///
/// The primary action sits where a left-to-right form finishes, and the secondary one is a
/// plain text button, so "skip" never competes visually with "add". Wraps onto a second line
/// rather than clipping when a translated label runs long (DESIGN_SYSTEM.md §Localisation).
class OnboardingFormFooter extends StatelessWidget {
  const OnboardingFormFooter({super.key, required this.primary, this.secondary});

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: AdminSpacing.lg, bottom: AdminSpacing.md),
          child: Divider(height: 1),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.sm,
          children: [
            secondary ?? const SizedBox.shrink(),
            primary,
          ],
        ),
      ],
    );
  }
}
