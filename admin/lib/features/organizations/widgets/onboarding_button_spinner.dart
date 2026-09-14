import 'package:flutter/material.dart';

/// The in-progress indicator inside a submit control. Identical to the login feature's
/// `ButtonSpinner` — kept as a separate copy rather than a shared import, matching this
/// codebase's discipline that each feature under `features/` is self-contained
/// (PROJECT_STRUCTURE.md §Flutter Layout); a two-line widget is cheaper to duplicate than to
/// promote to `core/` on the strength of one other user.
///
/// Takes the enclosing button's own icon color, so it stays visible on the disabled fill the
/// button shows while its action is in flight — a fixed `onPrimary` white disappeared there.
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
        color: IconTheme.of(context).color ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
