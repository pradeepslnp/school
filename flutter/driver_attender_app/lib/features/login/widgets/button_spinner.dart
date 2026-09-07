import 'package:flutter/material.dart';

import '../../../l10n/l10n_extensions.dart';

/// A spinner sized to sit inside a button without changing its height.
///
/// Keeping the button the same size while it works matters more here than elsewhere: a
/// control that shrinks under a thumb on a moving vehicle is a control that gets mis-tapped
/// (DRIVER_ATTENDANT_APP.md §Non-Negotiable Constraints).
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.workingLabel,
      child: const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
