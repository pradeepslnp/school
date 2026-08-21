import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// The frame around sign-in: centred card, product mark, bounded width.
///
/// Separate from the screen so the screen is only the form and its states. The width bound
/// is the point of this widget — a full-width form on a 27-inch monitor puts the label at
/// one edge and the field at the other, and the line length exceeds what is comfortably
/// readable.
class SignInScaffold extends StatelessWidget {
  const SignInScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          // Scrollable so the form stays reachable at 200% text scale and on a short
          // window, rather than overflowing (ACCESSIBILITY.md §Text).
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  // The mark is decorative; the heading below carries the meaning, and a
                  // screen reader announcing "shield icon" adds nothing.
                  excludeSemantics: true,
                  child: Icon(
                    Icons.shield_outlined,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
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
      ),
    );
  }
}
