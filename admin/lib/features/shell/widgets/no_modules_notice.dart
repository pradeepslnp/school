import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// What the console shows when it has no modules to show.
///
/// This build implements the console's foundation — session handling, the HTTP boundary,
/// routing, and sign-in — and no operational screen. Rendering an empty dashboard frame, or
/// a rail of links that lead nowhere, would imply a console that works and is merely empty
/// today. It says what is actually true instead (ENGINEERING_PRINCIPLES.md §15).
///
/// Deleted when A-01 lands. Nothing else depends on it.
class NoModulesNotice extends StatelessWidget {
  const NoModulesNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AdminSpacing.md),
              Text(
                'No console modules in this build',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AdminSpacing.sm),
              Text(
                'You are signed in. The operations dashboard, alert inbox, and '
                'administration screens are not part of this build yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
