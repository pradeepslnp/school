import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';

/// Where the operator is in a short linear flow — adding an organization, then its first school
/// (A-40).
///
/// Every step shows a number or a check **and** a label, so progress is never read from color
/// alone (ACCESSIBILITY.md). The fill is the brand navy, not a status color: finishing a form step
/// is not a safety state, and the status palette stays reserved for the journey
/// (DESIGN_SYSTEM.md §Status colors).
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({
    super.key,
    required this.labels,
    required this.currentIndex,
  });

  final List<String> labels;

  /// Steps before this one are complete, this one is in progress, the rest are still to come.
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (index > 0) ...[
            const SizedBox(width: AdminSpacing.md),
            _Connector(complete: index <= currentIndex),
            const SizedBox(width: AdminSpacing.md),
          ],
          Flexible(
            child: _Step(
              number: index + 1,
              total: labels.length,
              label: labels[index],
              state: index < currentIndex
                  ? _StepState.done
                  : index == currentIndex
                      ? _StepState.current
                      : _StepState.upcoming,
            ),
          ),
        ],
      ],
    );
  }
}

enum _StepState { done, current, upcoming }

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.total,
    required this.label,
    required this.state,
  });

  final int number;
  final int total;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final livery = context.livery;
    final l10n = context.l10n;
    final reached = state != _StepState.upcoming;

    final statusWord = switch (state) {
      _StepState.done => l10n.onboardingStepStatusDone,
      _StepState.current => l10n.onboardingStepStatusCurrent,
      _StepState.upcoming => l10n.onboardingStepStatusUpcoming,
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.onboardingStepSemanticLabel(number, total, label, statusWord),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? scheme.primary : livery.panel,
              border: reached ? null : Border.all(color: livery.borderStrong, width: 1.5),
            ),
            child: state == _StepState.done
                ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                : Text(
                    '$number',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: reached ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: AdminSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: state == _StepState.current ? FontWeight.w700 : FontWeight.w500,
                color: reached ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The line between two steps — navy once the step before it is done.
class _Connector extends StatelessWidget {
  const _Connector({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 2,
      decoration: BoxDecoration(
        color: complete ? Theme.of(context).colorScheme.primary : context.livery.borderStrong,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
