import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../../../l10n/app_localizations_extension.dart';

/// The signed-in operator, and the way out.
///
/// Shows who the console currently believes you are. That matters more here than in the
/// mobile apps: this is a desk tool on a shared workstation, and every action an operator
/// takes against a child's record is attributed to the signed-in account in the audit trail
/// (BR-AUD-001). Someone acting under a colleague's forgotten session is an audit trail that
/// names the wrong person.
class AccountMenu extends StatelessWidget {
  const AccountMenu({
    super.key,
    required this.user,
    required this.onSignOut,
    this.isSigningOut = false,
  });

  final AuthenticatedUser user;
  final VoidCallback onSignOut;
  final bool isSigningOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primaryContainer,
          // The initials duplicate the name beside them, so announcing them again is noise.
          child: ExcludeSemantics(
            child: Text(
              user.initials,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AdminSpacing.sm),
        // Constrained rather than fixed: a long name truncates instead of overflowing, and
        // the layout still holds at 200% text scale (ACCESSIBILITY.md §Text).
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            user.displayName,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: AdminSpacing.sm),
        TextButton.icon(
          key: const Key('admin_shell_sign_out_button'),
          onPressed: isSigningOut ? null : onSignOut,
          icon: const Icon(Icons.logout_outlined, size: 18),
          label: Text(isSigningOut ? context.l10n.accountMenuSigningOut : context.l10n.accountMenuSignOut),
          style: TextButton.styleFrom(
            minimumSize: const Size(kAdminTouchTarget, kAdminTouchTarget),
          ),
        ),
      ],
    );
  }
}
