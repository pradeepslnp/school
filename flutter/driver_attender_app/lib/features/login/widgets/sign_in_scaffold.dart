import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// The frame both sign-in steps sit in.
///
/// Shared so the two steps cannot drift apart in padding, width, or scroll behaviour — on a
/// handset held one-handed at a depot gate, a form that shifts position between steps reads
/// as the app having jumped.
class SignInScaffold extends StatelessWidget {
  const SignInScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DriverSpacing.lg,
              vertical: DriverSpacing.lg,
            ),
            // Scrollable because the keyboard covers most of a phone screen, and because
            // text scaled to 200% must still reach the submit button
            // (ACCESSIBILITY.md, CODING_STANDARDS_FLUTTER.md §Accessibility).
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
