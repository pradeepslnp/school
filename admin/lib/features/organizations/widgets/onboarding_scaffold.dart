import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'onboarding_step_indicator.dart';

/// The page the organization flow sits on (A-40): a slim bar leading back to where the operator
/// came from, a heading that names what they are doing, an optional step indicator, and one card
/// holding the work.
///
/// A whole page with its own [Scaffold], because it is one — `OrganizationListRoute` pushes it
/// over the entire console shell. It used to assume the shell's surface was still underneath and
/// drew none of its own, so the flow rendered on the bare browser canvas instead of the console's
/// work surface.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.backLabel,
    required this.title,
    required this.child,
    this.subtitle,
    this.stepLabels,
    this.currentStep = 0,
    this.onBack,
  });

  /// Names where [onBack] leads, e.g. "Organizations" — a labelled way back rather than a bare
  /// arrow, because this page covers the navigation that would otherwise say where it sits.
  final String backLabel;

  final String title;
  final String? subtitle;

  /// Shown as an [OnboardingStepIndicator] when set; null once there are no steps to show.
  final List<String>? stepLabels;
  final int currentStep;

  /// Null on a page with nowhere to return to, so nothing is offered that would do nothing.
  final VoidCallback? onBack;

  final Widget child;

  static const double _maxContentWidth = 760;

  /// Below this the page tightens its gutters, so a phone-width window keeps its fields wide.
  static const double _roomyWidth = 600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final livery = context.livery;
    final roomy = MediaQuery.sizeOf(context).width >= _roomyWidth;
    final back = onBack;
    final subtitle = this.subtitle;
    final stepLabels = this.stepLabels;

    return Scaffold(
      backgroundColor: livery.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 56,
        titleSpacing: AdminSpacing.sm,
        backgroundColor: livery.panel,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: livery.border)),
        title: back == null
            ? null
            : TextButton.icon(
                key: const Key('onboarding_back_button'),
                onPressed: back,
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(backLabel),
              ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: roomy ? AdminSpacing.xl : AdminSpacing.md,
          vertical: roomy ? AdminSpacing.xl : AdminSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AdminSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (stepLabels != null) ...[
                  const SizedBox(height: AdminSpacing.lg),
                  OnboardingStepIndicator(labels: stepLabels, currentIndex: currentStep),
                ],
                const SizedBox(height: AdminSpacing.lg),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(roomy ? AdminSpacing.xl : AdminSpacing.lg),
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
