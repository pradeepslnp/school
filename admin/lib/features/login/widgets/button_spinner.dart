import 'package:flutter/material.dart';

/// The in-progress indicator inside a submit control.
///
/// Sized to the label it replaces so the button does not resize mid-submission — a control
/// that changes size under the pointer is the classic way to make someone click the thing
/// that moved into place.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.semanticsLabel});

  /// Announced while the request is in flight. A spinner with no label is silent to a
  /// screen reader, which turns "signing in" into "nothing happened"
  /// (ACCESSIBILITY.md §Non-text content).
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
