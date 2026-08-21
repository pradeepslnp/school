import 'package:flutter/widgets.dart';

/// How much room the app has, as a category rather than a pixel count.
///
/// Layout decisions branch on this, never on a raw width. `if (width > 412)` encodes one
/// specific handset; `if (isCompact)` states the intent, and keeps every screen agreeing on
/// where the boundary sits.
enum ScreenClass {
  /// Phones in portrait, and split-screen. One column.
  compact,

  /// Large phones in landscape, small tablets. Two columns are possible.
  medium,

  /// Tablets and desktop. Master–detail fits.
  expanded;

  bool get isCompact => this == ScreenClass.compact;
  bool get isMedium => this == ScreenClass.medium;
  bool get isExpanded => this == ScreenClass.expanded;

  /// True when there is room for more than a single column.
  bool get isWide => this != ScreenClass.compact;
}

/// Width boundaries between [ScreenClass] values.
///
/// Chosen to match the Material window size classes so the app agrees with the platform's
/// own conventions rather than inventing private ones.
abstract final class Breakpoints {
  /// Below this is [ScreenClass.compact].
  static const double medium = 600;

  /// At or above this is [ScreenClass.expanded].
  static const double expanded = 1024;

  /// Longest comfortable line of text.
  ///
  /// Beyond roughly this width, the eye loses its place travelling back to the start of the
  /// next line. Content is centred inside this rather than stretched across a tablet.
  static const double readableContentWidth = 640;

  static ScreenClass classify(double width) {
    if (width >= expanded) return ScreenClass.expanded;
    if (width >= medium) return ScreenClass.medium;
    return ScreenClass.compact;
  }

  /// Classifies from a [MediaQuery] size.
  static ScreenClass of(BuildContext context) =>
      classify(MediaQuery.sizeOf(context).width);
}
