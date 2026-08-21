import 'package:flutter/material.dart';

/// The in-progress indicator inside a submit control. Identical to the login feature's
/// `ButtonSpinner` — kept as a separate copy rather than a shared import, matching this
/// codebase's discipline that each feature under `features/` is self-contained
/// (PROJECT_STRUCTURE.md §Flutter Layout); a two-line widget is cheaper to duplicate than to
/// promote to `core/` on the strength of one other user.
class OnboardingButtonSpinner extends StatelessWidget {
  const OnboardingButtonSpinner({super.key, this.semanticsLabel});

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        semanticsLabel: semanticsLabel,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
