import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// The frame around each onboarding step: bounded-width card, centred in the content area.
///
/// Separate from the screen so the screen is only step selection — matching
/// `SignInScaffold`'s split, adapted for the console shell (no product mark or full-page
/// background here; the shell already supplies both).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget child;

  /// Shows a back control beside the title when set. Null on a step that has nowhere to
  /// return to, so nothing is offered that would do nothing.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: AdminSpacing.sm),
                  ],
                  Expanded(child: Text(title, style: theme.textTheme.headlineSmall)),
                ],
              ),
              const SizedBox(height: AdminSpacing.lg),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminSpacing.sm),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AdminSpacing.lg),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
