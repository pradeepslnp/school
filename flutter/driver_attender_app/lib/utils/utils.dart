/// Shared helpers for this app.
///
/// Import this one file rather than reaching into `utils/…` directly:
///
/// ```dart
/// import '../../../utils/utils.dart';
///
/// Padding(
///   padding: context.pagePadding,
///   child: context.isWideScreen ? const _TwoColumn() : const _SingleColumn(),
/// )
/// ```
///
/// ## What does not belong here
///
/// A `utils` folder attracts anything without an obvious home, and becomes the place nobody
/// can delete from because nobody knows what uses it. Business rules go in a feature's
/// repository or `guardian_core`; design tokens go in `app/theme.dart`. This folder is for
/// helpers that are about *presentation mechanics* and depend on nothing else in the app.
library;

export 'responsive/responsive_context.dart';
export 'responsive/screen_class.dart';
export 'responsive/touch_target.dart';
